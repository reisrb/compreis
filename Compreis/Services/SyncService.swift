import Foundation
import SwiftData

// Sincroniza TUDO com o Google Sheets em tempo real.
// Estrutura da planilha:
//   - Aba "Listas"   → uma linha por lista (ativa ou finalizada)
//   - Aba "Itens"    → uma linha por item de cada lista
//   - Aba "Produtos" → histórico de produtos cadastrados (ProdutoHistorico)
//
// Estratégia: reescreve a aba inteira a cada sync (simples, sem conflitos).
// Debounce de 3 s para não spammar a API a cada keystroke.

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

    // Chama depois de qualquer mutação no ModelContext
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
            let folderId = try await garantirPasta(token: token)
            let sheetId  = try await garantirPlanilha(folderId: folderId, token: token)

            let listas   = (try? context.fetch(FetchDescriptor<ListaDeCompras>(sort: [SortDescriptor(\.criadaEm)]))) ?? []
            let historico = (try? context.fetch(FetchDescriptor<ProdutoHistorico>(sort: [SortDescriptor(\.nome)]))) ?? []

            try await reescreverAba(spreadsheetId: sheetId, nome: "Listas",
                                    cabecalho: ["Nome", "Status", "Criada em", "Finalizada em", "Itens", "Total Calculado", "Total Pago", "Local"],
                                    linhas: listas.map { linhaLista($0) },
                                    token: token)

            let itensTodos = listas.flatMap { lista in lista.itens.map { (lista, $0) } }
            try await reescreverAba(spreadsheetId: sheetId, nome: "Itens",
                                    cabecalho: ["Lista", "Produto", "Preço", "Unidade", "Quantidade", "Total"],
                                    linhas: itensTodos.map { linhaItem(lista: $0.0, item: $0.1) },
                                    token: token)

            try await reescreverAba(spreadsheetId: sheetId, nome: "Produtos",
                                    cabecalho: ["Produto", "Último Preço", "Unidade"],
                                    linhas: historico.map { [
                                        $0.nome,
                                        $0.preco,
                                        $0.unidade.rawValue
                                    ]},
                                    token: token)

            lastSynced = .now
        } catch {
            lastError = error.localizedDescription
        }
        syncing = false
    }

    // MARK: - Row builders

    private func linhaLista(_ l: ListaDeCompras) -> [Any] {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy HH:mm"
        return [
            l.nome,
            l.finalizada ? "Finalizada" : "Em aberto",
            df.string(from: l.criadaEm),
            l.finalizadaEm.map { df.string(from: $0) } ?? "",
            l.itens.count,
            l.totalCalculado,
            l.totalPago ?? l.totalCalculado,
            l.localNome ?? ""
        ]
    }

    private func linhaItem(lista: ListaDeCompras, item: Item) -> [Any] {
        [lista.nome, item.nome, item.preco, item.unidade.rawValue, item.quantidade, item.total]
    }

    // MARK: - Drive / Sheets helpers

    private func garantirPasta(token: String) async throws -> String {
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
        guard let id = created?["id"] as? String else { throw SyncError.api("pasta") }
        UserDefaults.standard.set(id, forKey: folderIdKey); return id
    }

    private func garantirPlanilha(folderId: String, token: String) async throws -> String {
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
            "sheets": [["properties": ["title": "Listas"]],
                       ["properties": ["title": "Itens"]],
                       ["properties": ["title": "Produtos"]]]
        ]
        let created = try await apiPost("https://sheets.googleapis.com/v4/spreadsheets",
                                        body: body, token: token) as? [String: Any]
        guard let id = created?["spreadsheetId"] as? String else { throw SyncError.api("planilha") }
        // Move para pasta
        var mv = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(id)?addParents=\(folderId)&fields=id")!)
        mv.httpMethod = "PATCH"
        mv.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: mv)
        UserDefaults.standard.set(id, forKey: spreadsheetIdKey); return id
    }

    private func reescreverAba(spreadsheetId: String, nome: String, cabecalho: [String], linhas: [[Any]], token: String) async throws {
        // Garante que a aba existe
        let info = try await apiGet(URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)?fields=sheets.properties.title")!, token: token) as? [String: Any]
        let abas = (info?["sheets"] as? [[String: Any]])?.compactMap { ($0["properties"] as? [String: Any])?["title"] as? String } ?? []
        if !abas.contains(nome) {
            _ = try await apiPost("https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate",
                                  body: ["requests": [["addSheet": ["properties": ["title": nome]]]]], token: token)
        }
        // Limpa e reescreve
        let encodedNome = nome.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? nome
        let range = "\(encodedNome)!A1:Z10000"
        var clearReq = URLRequest(url: URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range):clear")!)
        clearReq.httpMethod = "POST"
        clearReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: clearReq)

        let values: [[Any]] = [cabecalho] + linhas
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
        var errorDescription: String? { if case .api(let m) = self { "Erro API: \(m)" } else { nil } }
    }
}
