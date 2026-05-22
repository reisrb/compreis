import Foundation

struct MLProduto: Identifiable {
    let id: String
    let titulo: String
    let preco: Double
    let thumbnail: URL?
}

enum MLService {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        return URLSession(configuration: config)
    }()

    static func buscar(_ query: String) async -> [MLProduto] {
        guard !query.isEmpty,
              var comps = URLComponents(string: "https://api.mercadolibre.com/sites/MLB/search") else {
            return []
        }
        comps.queryItems = [
            .init(name: "q", value: query),
            .init(name: "category", value: "MLB1246"), // Alimentos e Bebidas
            .init(name: "limit", value: "6"),
            .init(name: "condition", value: "new")
        ]
        guard let url = comps.url,
              let (data, _) = try? await session.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }
        return results.compactMap { item in
            guard let id = item["id"] as? String,
                  let titulo = item["title"] as? String,
                  let preco = item["price"] as? Double else { return nil }
            let thumb = (item["thumbnail"] as? String).flatMap { URL(string: $0) }
            return MLProduto(id: id, titulo: titulo, preco: preco, thumbnail: thumb)
        }
    }
}
