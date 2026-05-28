import Foundation
import SwiftData

enum ExportService {
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    static func exportJSON(context: ModelContext) throws -> URL {
        let lists = (try? context.fetch(FetchDescriptor<ShoppingList>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))) ?? []

        let payload: [[String: Any]] = lists.map { list in
            [
                "nome": list.name,
                "criada_em": df.string(from: list.createdAt),
                "finalizada": list.finalized,
                "finalizada_em": list.finalizedAt.map { df.string(from: $0) } ?? NSNull(),
                "data_mercado": list.marketDate.map { df.string(from: $0) } ?? NSNull(),
                "is_template": list.isTemplate,
                "local": list.marketName ?? NSNull(),
                "local_latitude": list.latitude ?? NSNull(),
                "local_longitude": list.longitude ?? NSNull(),
                "total_pago": list.totalPaid ?? NSNull(),
                "itens": list.items.map { item in
                    [
                        "nome": item.name,
                        "preco": item.price,
                        "unidade": item.unit.rawValue,
                        "quantidade": item.quantity,
                        "categoria": item.category.rawValue,
                        "pegou": item.picked
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

    static func importJSON(url: URL, context: ModelContext) throws -> (lists: Int, items: Int) {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.invalidFormat
        }

        var totalLists = 0
        var totalItems = 0

        for dict in json {
            guard let name = dict["nome"] as? String else { continue }

            let list = ShoppingList(
                name: name,
                marketDate: (dict["data_mercado"] as? String).flatMap { df.date(from: $0) },
                marketName: dict["local"] as? String,
                latitude: dict["local_latitude"] as? Double,
                longitude: dict["local_longitude"] as? Double
            )
            if let createdAt = (dict["criada_em"] as? String).flatMap({ df.date(from: $0) }) {
                list.createdAt = createdAt
            }
            list.finalized = dict["finalizada"] as? Bool ?? false
            list.finalizedAt = (dict["finalizada_em"] as? String).flatMap { df.date(from: $0) }
            list.isTemplate = dict["is_template"] as? Bool ?? false
            list.totalPaid = dict["total_pago"] as? Double

            for itemDict in (dict["itens"] as? [[String: Any]] ?? []) {
                guard let itemName = itemDict["nome"] as? String else { continue }
                let item = Item(
                    name: itemName,
                    price: itemDict["preco"] as? Double ?? 0,
                    unit: ItemUnit(rawValue: itemDict["unidade"] as? String ?? "") ?? .each,
                    quantity: itemDict["quantidade"] as? Double ?? 1,
                    category: ItemCategory(rawValue: itemDict["categoria"] as? String ?? "") ?? .other
                )
                item.picked = itemDict["pegou"] as? Bool ?? false
                list.items.append(item)
                totalItems += 1
            }

            context.insert(list)
            totalLists += 1
        }

        return (totalLists, totalItems)
    }
}

enum ImportError: LocalizedError {
    case invalidFormat
    var errorDescription: String? { "Invalid JSON file or unexpected format." }
}
