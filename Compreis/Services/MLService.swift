import Foundation

struct MLProduct: Identifiable {
    let id: String
    let title: String
    let price: Double  // 0 when no history — user fills in
    let thumbnail: URL?
}

enum MLService {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.httpAdditionalHeaders = ["User-Agent": "CompreisApp/1.0 (iOS)"]
        return URLSession(configuration: config)
    }()

    static func search(_ query: String) async -> [MLProduct] {
        guard !query.isEmpty,
              var comps = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
        else { return [] }

        comps.queryItems = [
            .init(name: "search_terms",   value: query),
            .init(name: "search_simple",  value: "1"),
            .init(name: "action",         value: "process"),
            .init(name: "json",           value: "1"),
            .init(name: "page_size",      value: "6"),
            .init(name: "countries_tags", value: "en:brazil"),
            .init(name: "fields",         value: "code,product_name,product_name_pt,image_front_small_url"),
        ]

        guard let url = comps.url,
              let (data, resp) = try? await session.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let products = json["products"] as? [[String: Any]]
        else { return [] }

        return products.compactMap { p in
            guard let code = p["code"] as? String else { return nil }
            let name = (p["product_name_pt"] as? String
                        ?? p["product_name"] as? String ?? "")
                .trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            let thumb = (p["image_front_small_url"] as? String).flatMap { URL(string: $0) }
            return MLProduct(id: code, title: name, price: 0.0, thumbnail: thumb)
        }
    }
}
