import Foundation

enum SheetsService {
    private static let driveBase  = "https://www.googleapis.com/drive/v3"
    private static let sheetsBase = "https://sheets.googleapis.com/v4/spreadsheets"
    private static let folderIdKey     = "sheets_folder_id"
    private static let spreadsheetIdKey = "sheets_spreadsheet_id"

    // MARK: - Public

    static func export(_ list: ShoppingList, auth: GoogleAuth) async throws {
        let token = try await auth.getToken()
        let folderId = try await ensureFolder(token: token)
        let sheetId  = try await ensureSpreadsheet(folderId: folderId, token: token)
        let tab      = list.monthYear
        try await ensureTab(spreadsheetId: sheetId, name: tab, token: token)
        try await appendRow(spreadsheetId: sheetId, tab: tab, list: list, token: token)
    }

    // MARK: - Drive: folder

    private static func ensureFolder(token: String) async throws -> String {
        if let id = UserDefaults.standard.string(forKey: folderIdKey) { return id }

        var comps = URLComponents(string: "\(driveBase)/files")!
        comps.queryItems = [
            .init(name: "q", value: "name='Compreis' and mimeType='application/vnd.google-apps.folder' and trashed=false"),
            .init(name: "fields", value: "files(id)")
        ]
        let resp = try await get(comps.url!, token: token) as? [String: Any]
        if let files = resp?["files"] as? [[String: Any]],
           let id = files.first?["id"] as? String {
            UserDefaults.standard.set(id, forKey: folderIdKey)
            return id
        }

        let body: [String: Any] = [
            "name": "Compreis",
            "mimeType": "application/vnd.google-apps.folder"
        ]
        let created = try await post("\(driveBase)/files", body: body, token: token) as? [String: Any]
        guard let id = created?["id"] as? String else { throw SheetsError.api("Failed to create folder") }
        UserDefaults.standard.set(id, forKey: folderIdKey)
        return id
    }

    // MARK: - Sheets: spreadsheet

    private static func ensureSpreadsheet(folderId: String, token: String) async throws -> String {
        if let id = UserDefaults.standard.string(forKey: spreadsheetIdKey) { return id }

        var comps = URLComponents(string: "\(driveBase)/files")!
        comps.queryItems = [
            .init(name: "q", value: "name='Compreis - Histórico' and '\(folderId)' in parents and trashed=false"),
            .init(name: "fields", value: "files(id)")
        ]
        let resp = try await get(comps.url!, token: token) as? [String: Any]
        if let files = resp?["files"] as? [[String: Any]],
           let id = files.first?["id"] as? String {
            UserDefaults.standard.set(id, forKey: spreadsheetIdKey)
            return id
        }

        let body: [String: Any] = [
            "properties": ["title": "Compreis - Histórico"],
            "sheets": [[
                "properties": ["title": "General"],
                "data": [[
                    "rowData": [[
                        "values": headerRow().map { ["userEnteredValue": ["stringValue": $0]] }
                    ]]
                ]]
            ]]
        ]
        let created = try await post(sheetsBase, body: body, token: token) as? [String: Any]
        guard let id = created?["spreadsheetId"] as? String else {
            throw SheetsError.api("Failed to create spreadsheet")
        }

        var moveComps = URLComponents(string: "\(driveBase)/files/\(id)")!
        moveComps.queryItems = [
            .init(name: "addParents", value: folderId),
            .init(name: "fields", value: "id")
        ]
        var req = URLRequest(url: moveComps.url!)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)

        UserDefaults.standard.set(id, forKey: spreadsheetIdKey)
        return id
    }

    // MARK: - Sheets: month tab

    private static func ensureTab(spreadsheetId: String, name: String, token: String) async throws {
        let info = try await get(URL(string: "\(sheetsBase)/\(spreadsheetId)?fields=sheets.properties.title")!, token: token) as? [String: Any]
        let tabs = (info?["sheets"] as? [[String: Any]])?.compactMap {
            ($0["properties"] as? [String: Any])?["title"] as? String
        } ?? []

        if tabs.contains(name) { return }

        let body: [String: Any] = ["requests": [["addSheet": ["properties": ["title": name]]]]]
        _ = try await post("\(sheetsBase)/\(spreadsheetId):batchUpdate", body: body, token: token)

        let headerBody: [String: Any] = [
            "values": [headerRow()],
            "majorDimension": "ROWS"
        ]
        let range = "\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)!A1"
        _ = try await put("\(sheetsBase)/\(spreadsheetId)/values/\(range)?valueInputOption=RAW", body: headerBody, token: token)
    }

    // MARK: - Append row

    private static func appendRow(spreadsheetId: String, tab: String, list: ShoppingList, token: String) async throws {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy HH:mm"
        let date = df.string(from: list.finalizedAt ?? .now)
        let products = list.items.map { "\($0.name) (\($0.total.brl))" }.joined(separator: ", ")

        let row: [Any] = [
            date,
            list.name,
            list.items.count,
            list.computedTotal,
            list.total,
            list.marketName ?? "",
            products
        ]

        let body: [String: Any] = ["values": [row], "majorDimension": "ROWS"]
        let range = "\(tab.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tab)!A:G"
        let url = "\(sheetsBase)/\(spreadsheetId)/values/\(range):append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS"
        _ = try await post(url, body: body, token: token)
    }

    // MARK: - HTTP helpers

    private static func get(_ url: URL, token: String) async throws -> Any? {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    private static func post(_ urlStr: String, body: [String: Any], token: String) async throws -> Any? {
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    private static func put(_ urlStr: String, body: [String: Any], token: String) async throws -> Any? {
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    private static func headerRow() -> [String] {
        ["Date", "List", "Items", "Computed Total", "Total Paid", "Market", "Products"]
    }

    enum SheetsError: Error, LocalizedError {
        case api(String)
        var errorDescription: String? {
            if case .api(let m) = self { return m }
            return nil
        }
    }
}
