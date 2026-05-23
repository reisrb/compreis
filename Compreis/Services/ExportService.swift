import Foundation
import SwiftData

enum ExportService {
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    static func exportarJSON(context: ModelContext) throws -> URL {
        let listas = (try? context.fetch(FetchDescriptor<ListaDeCompras>(
            sortBy: [SortDescriptor(\.criadaEm, order: .reverse)]
        ))) ?? []

        let payload: [[String: Any]] = listas.map { lista in
            [
                "nome": lista.nome,
                "criada_em": df.string(from: lista.criadaEm),
                "finalizada": lista.finalizada,
                "finalizada_em": lista.finalizadaEm.map { df.string(from: $0) } ?? NSNull(),
                "data_mercado": lista.dataMercado.map { df.string(from: $0) } ?? NSNull(),
                "is_template": lista.isTemplate,
                "local": lista.localNome ?? NSNull(),
                "local_latitude": lista.localLatitude ?? NSNull(),
                "local_longitude": lista.localLongitude ?? NSNull(),
                "total_pago": lista.totalPago ?? NSNull(),
                "itens": lista.itens.map { item in
                    [
                        "nome": item.nome,
                        "preco": item.preco,
                        "unidade": item.unidade.rawValue,
                        "quantidade": item.quantidade,
                        "categoria": item.categoria.rawValue,
                        "pegou": item.pegou
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

    static func importarJSON(url: URL, context: ModelContext) throws -> (listas: Int, itens: Int) {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.formatoInvalido
        }

        var totalListas = 0
        var totalItens = 0

        for dict in json {
            guard let nome = dict["nome"] as? String else { continue }

            let lista = ListaDeCompras(
                nome: nome,
                dataMercado: (dict["data_mercado"] as? String).flatMap { df.date(from: $0) },
                localNome: dict["local"] as? String,
                localLatitude: dict["local_latitude"] as? Double,
                localLongitude: dict["local_longitude"] as? Double
            )
            if let criadaEm = (dict["criada_em"] as? String).flatMap({ df.date(from: $0) }) {
                lista.criadaEm = criadaEm
            }
            lista.finalizada = dict["finalizada"] as? Bool ?? false
            lista.finalizadaEm = (dict["finalizada_em"] as? String).flatMap { df.date(from: $0) }
            lista.isTemplate = dict["is_template"] as? Bool ?? false
            lista.totalPago = dict["total_pago"] as? Double

            for itemDict in (dict["itens"] as? [[String: Any]] ?? []) {
                guard let itemNome = itemDict["nome"] as? String else { continue }
                let item = Item(
                    nome: itemNome,
                    preco: itemDict["preco"] as? Double ?? 0,
                    unidade: Unidade(rawValue: itemDict["unidade"] as? String ?? "") ?? .unidade,
                    quantidade: itemDict["quantidade"] as? Double ?? 1,
                    categoria: Categoria(rawValue: itemDict["categoria"] as? String ?? "") ?? .outros
                )
                item.pegou = itemDict["pegou"] as? Bool ?? false
                lista.itens.append(item)
                totalItens += 1
            }

            context.insert(lista)
            totalListas += 1
        }

        return (totalListas, totalItens)
    }
}

enum ImportError: LocalizedError {
    case formatoInvalido
    var errorDescription: String? { "Arquivo JSON inválido ou fora do formato esperado." }
}
