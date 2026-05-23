import Foundation
import SwiftData

enum ExportService {
    static func exportarJSON(context: ModelContext) throws -> URL {
        let listas = (try? context.fetch(FetchDescriptor<ListaDeCompras>(
            sortBy: [SortDescriptor(\.criadaEm, order: .reverse)]
        ))) ?? []

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let payload: [[String: Any]] = listas.map { lista in
            [
                "nome": lista.nome,
                "criada_em": df.string(from: lista.criadaEm),
                "finalizada": lista.finalizada,
                "finalizada_em": lista.finalizadaEm.map { df.string(from: $0) } ?? NSNull(),
                "data_mercado": lista.dataMercado.map { df.string(from: $0) } ?? NSNull(),
                "local": lista.localNome ?? NSNull(),
                "total_calculado": lista.totalCalculado,
                "total_pago": lista.totalPago ?? NSNull(),
                "itens": lista.itens.map { item in
                    [
                        "nome": item.nome,
                        "preco": item.preco,
                        "unidade": item.unidade.rawValue,
                        "quantidade": item.quantidade,
                        "total": item.total
                    ] as [String: Any]
                }
            ]
        }

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("compreis_\(Date().formatted(.iso8601)).json")
        try data.write(to: url)
        return url
    }
}
