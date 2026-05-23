import Foundation

enum SheetsService {
    private static let driveBase  = "https://www.googleapis.com/drive/v3"
    private static let sheetsBase = "https://sheets.googleapis.com/v4/spreadsheets"
    private static let folderIdKey     = "sheets_folder_id"
    private static let spreadsheetIdKey = "sheets_spreadsheet_id"

    // MARK: - Public

    static func exportar(_ lista: ListaDeCompras, auth: GoogleAuth) async throws {
        let token = try await auth.getToken()
        let folderId = try await garantirPasta(token: token)
        let sheetId  = try await garantirPlanilha(folderId: folderId, token: token)
        let mesAba   = lista.mesAno
        try await garantirAba(spreadsheetId: sheetId, nome: mesAba, token: token)
        try await appendLinha(spreadsheetId: sheetId, aba: mesAba, lista: lista, token: token)
    }

    // MARK: - Drive: pasta

    private static func garantirPasta(token: String) async throws -> String {
        if let id = UserDefaults.standard.string(forKey: folderIdKey) { return id }

        // Busca pasta existente
        var comps = URLComponents(string: "\(driveBase)/files")!
        comps.queryItems = [
            .init(name: "q", value: "name='Compreis' and mimeType='application/vnd.google-apps.folder' and trashed=false"),
            .init(name: "fields", value: "files(id)")
        ]
        let lista = try await get(comps.url!, token: token) as? [String: Any]
        if let files = lista?["files"] as? [[String: Any]],
           let id = files.first?["id"] as? String {
            UserDefaults.standard.set(id, forKey: folderIdKey)
            return id
        }

        // Cria pasta
        let body: [String: Any] = [
            "name": "Compreis",
            "mimeType": "application/vnd.google-apps.folder"
        ]
        let resp = try await post("\(driveBase)/files", body: body, token: token) as? [String: Any]
        guard let id = resp?["id"] as? String else { throw SheetsError.api("Falha ao criar pasta") }
        UserDefaults.standard.set(id, forKey: folderIdKey)
        return id
    }

    // MARK: - Sheets: planilha

    private static func garantirPlanilha(folderId: String, token: String) async throws -> String {
        if let id = UserDefaults.standard.string(forKey: spreadsheetIdKey) { return id }

        // Busca planilha existente
        var comps = URLComponents(string: "\(driveBase)/files")!
        comps.queryItems = [
            .init(name: "q", value: "name='Compreis - Histórico' and '\(folderId)' in parents and trashed=false"),
            .init(name: "fields", value: "files(id)")
        ]
        let lista = try await get(comps.url!, token: token) as? [String: Any]
        if let files = lista?["files"] as? [[String: Any]],
           let id = files.first?["id"] as? String {
            UserDefaults.standard.set(id, forKey: spreadsheetIdKey)
            return id
        }

        // Cria planilha
        let body: [String: Any] = [
            "properties": ["title": "Compreis - Histórico"],
            "sheets": [[
                "properties": ["title": "Geral"],
                "data": [[
                    "rowData": [[
                        "values": cabecalho().map { ["userEnteredValue": ["stringValue": $0]] }
                    ]]
                ]]
            ]]
        ]
        let resp = try await post(sheetsBase, body: body, token: token) as? [String: Any]
        guard let id = resp?["spreadsheetId"] as? String else {
            throw SheetsError.api("Falha ao criar planilha")
        }

        // Move para a pasta Compreis
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

    // MARK: - Sheets: aba do mês

    private static func garantirAba(spreadsheetId: String, nome: String, token: String) async throws {
        let info = try await get(URL(string: "\(sheetsBase)/\(spreadsheetId)?fields=sheets.properties.title")!, token: token) as? [String: Any]
        let abas = (info?["sheets"] as? [[String: Any]])?.compactMap {
            ($0["properties"] as? [String: Any])?["title"] as? String
        } ?? []

        if abas.contains(nome) { return }

        var requests: [[String: Any]] = [
            ["addSheet": ["properties": ["title": nome]]]
        ]
        // Cabeçalho na nova aba
        requests.append(contentsOf: [])

        let body: [String: Any] = ["requests": requests]
        _ = try await post("\(sheetsBase)/\(spreadsheetId):batchUpdate", body: body, token: token)

        // Insere cabeçalho
        let cabBody: [String: Any] = [
            "values": [cabecalho()],
            "majorDimension": "ROWS"
        ]
        let range = "\(nome.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? nome)!A1"
        _ = try await put("\(sheetsBase)/\(spreadsheetId)/values/\(range)?valueInputOption=RAW", body: cabBody, token: token)
    }

    // MARK: - Append linha

    private static func appendLinha(spreadsheetId: String, aba: String, lista: ListaDeCompras, token: String) async throws {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy HH:mm"
        let data = df.string(from: lista.finalizadaEm ?? .now)
        let produtos = lista.itens.map { "\($0.nome) (\($0.total.brl))" }.joined(separator: ", ")

        let row: [Any] = [
            data,
            lista.nome,
            lista.itens.count,
            lista.totalCalculado,
            lista.total,
            lista.localNome ?? "",
            produtos
        ]

        let body: [String: Any] = ["values": [row], "majorDimension": "ROWS"]
        let range = "\(aba.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? aba)!A:G"
        let url = "\(sheetsBase)/\(spreadsheetId)/values/\(range):append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS"
        _ = try await post(url, body: body, token: token)
    }

    // MARK: - Helpers HTTP

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

    private static func cabecalho() -> [String] {
        ["Data", "Lista", "Itens", "Total Calculado", "Total Pago", "Local", "Produtos"]
    }

    enum SheetsError: Error, LocalizedError {
        case api(String)
        var errorDescription: String? {
            if case .api(let m) = self { return m }
            return nil
        }
    }
}
