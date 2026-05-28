import Foundation
import SwiftData

// Syncs everything with Google Sheets in real time.
// Sheet structure:
//   - "Lists" tab   → one row per list (active or finalized)
//   - "Items" tab   → one row per item in each list
//   - "Products" tab → product history (ProductHistory)
//
// Strategy: rewrites the entire tab on each sync (simple, no conflicts).
// 3-second debounce to avoid spamming the API on every keystroke.

@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var syncing = false
    @Published var lastSynced: Date?
    @Published var lastError: String?

    private var pendingTask: Task<Void, Never>?
    private let spreadsheetIdKey = "sheets_spreadsheet_id"
    private let folderIdKey      = "sheets_folder_id"

    private init() {}

    func scheduleSync(context: ModelContext) {
        guard GoogleAuth.shared.isConnected else { return }
        pendingTask?.cancel()
        pendingTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await performSync(context: context)
        }
    }

    func performSync(context: ModelContext) async {
        guard GoogleAuth.shared.isConnected else { return }
        syncing = true
        lastError = nil
        do {
            let token = try await GoogleAuth.shared.getToken()
            let folderId = try await ensureFolder(token: token)
            let sheetId  = try await ensureSpreadsheet(folderId: folderId, token: token)

            let lists   = (try? context.fetch(FetchDescriptor<ShoppingList>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
            let history = (try? context.fetch(FetchDescriptor<ProductHistory>(sortBy: [SortDescriptor(\.name)]))) ?? []

            try await rewriteSheet(spreadsheetId: sheetId, name: "Lists",
                                   header: ["Name", "Status", "Created At", "Finalized At", "Items", "Computed Total", "Total Paid", "Market"],
                                   rows: lists.map { rowForList($0) },
                                   token: token)

            let allItems = lists.flatMap { list in list.items.map { (list, $0) } }
            try await rewriteSheet(spreadsheetId: sheetId, name: "Items",
                                   header: ["List", "Product", "Price", "Unit", "Quantity", "Total"],
                                   rows: allItems.map { rowForItem(list: $0.0, item: $0.1) },
                                   token: token)

            try await rewriteSheet(spreadsheetId: sheetId, name: "Products",
                                   header: ["Product", "Last Price", "Unit"],
                                   rows: history.map { [
                                       $0.name,
                                       $0.price,
                                       $0.unit.rawValue
                                   ]},
                                   token: token)

            lastSynced = .now
        } catch {
            lastError = error.localizedDescription
        }
        syncing = false
    }

    // MARK: - Row builders

    private func rowForList(_ l: ShoppingList) -> [Any] {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy HH:mm"
        return [
            l.name,
            l.finalized ? "Finalized" : "Open",
            df.string(from: l.createdAt),
            l.finalizedAt.map { df.string(from: $0) } ?? "",
            l.items.count,
            l.computedTotal,
            l.totalPaid ?? l.computedTotal,
            l.marketName ?? ""
        ]
    }

    private func rowForItem(list: ShoppingList, item: Item) -> [Any] {
        [list.name, item.name, item.price, item.unit.rawValue, item.quantity, item.total]
    }

    // MARK: - Drive / Sheets helpers

    private func ensureFolder(token: String) async throws -> String {
        if let id = UserDefaults.standard.string(forKey: folderIdKey) { return id }
        var comps = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        comps.queryItems = [
            .init(name: "q", value: "name='Compreis' and mimeType='application/vnd.google-apps.folder' and trashed=false"),
            .init(name: "fields", value: "files(id)")
        ]
        let resp = try await apiGet(comps.url!, token: token) as? [String: Any]
        if let id = (resp?["files"] as? [[String: Any]])?.first?["id"] as? String {
            UserDefaults.standard.set(id, forKey: folderIdKey); return id
        }
        let created = try await apiPost("https://www.googleapis.com/drive/v3/files",
                                        body: ["name": "Compreis", "mimeType": "application/vnd.google-apps.folder"],
                                        token: token) as? [String: Any]
        guard let id = created?["id"] as? String else { throw SyncError.api("folder") }
        UserDefaults.standard.set(id, forKey: folderIdKey); return id
    }

    private func ensureSpreadsheet(folderId: String, token: String) async throws -> String {
        if let id = UserDefaults.standard.string(forKey: spreadsheetIdKey) { return id }
        var comps = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        comps.queryItems = [
            .init(name: "q", value: "name='Compreis - Dados' and '\(folderId)' in parents and trashed=false"),
            .init(name: "fields", value: "files(id)")
        ]
        let resp = try await apiGet(comps.url!, token: token) as? [String: Any]
        if let id = (resp?["files"] as? [[String: Any]])?.first?["id"] as? String {
            UserDefaults.standard.set(id, forKey: spreadsheetIdKey); return id
        }
        let body: [String: Any] = [
            "properties": ["title": "Compreis - Dados"],
            "sheets": [["properties": ["title": "Lists"]],
                       ["properties": ["title": "Items"]],
                       ["properties": ["title": "Products"]]]
        ]
        let created = try await apiPost("https://sheets.googleapis.com/v4/spreadsheets",
                                        body: body, token: token) as? [String: Any]
        guard let id = created?["spreadsheetId"] as? String else { throw SyncError.api("spreadsheet") }
        var mv = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(id)?addParents=\(folderId)&fields=id")!)
        mv.httpMethod = "PATCH"
        mv.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: mv)
        UserDefaults.standard.set(id, forKey: spreadsheetIdKey); return id
    }

    private func rewriteSheet(spreadsheetId: String, name: String, header: [String], rows: [[Any]], token: String) async throws {
        let info = try await apiGet(URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)?fields=sheets.properties.title")!, token: token) as? [String: Any]
        let tabs = (info?["sheets"] as? [[String: Any]])?.compactMap { ($0["properties"] as? [String: Any])?["title"] as? String } ?? []
        if !tabs.contains(name) {
            _ = try await apiPost("https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate",
                                  body: ["requests": [["addSheet": ["properties": ["title": name]]]]], token: token)
        }
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let range = "\(encodedName)!A1:Z10000"
        var clearReq = URLRequest(url: URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range):clear")!)
        clearReq.httpMethod = "POST"
        clearReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: clearReq)

        let values: [[Any]] = [header] + rows
        let writeBody: [String: Any] = ["values": values, "majorDimension": "ROWS"]
        _ = try await apiPut("https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)?valueInputOption=USER_ENTERED",
                              body: writeBody, token: token)
    }

    // MARK: - HTTP

    private func apiGet(_ url: URL, token: String) async throws -> Any? {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    private func apiPost(_ urlStr: String, body: [String: Any], token: String) async throws -> Any? {
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    private func apiPut(_ urlStr: String, body: [String: Any], token: String) async throws -> Any? {
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    enum SyncError: Error, LocalizedError {
        case api(String)
        var errorDescription: String? { if case .api(let m) = self { "API Error: \(m)" } else { nil } }
    }
}
