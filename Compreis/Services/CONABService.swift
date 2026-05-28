import Foundation
import CoreLocation

actor CONABService {
    static let shared = CONABService()
    private init() {}

    // normalizedKey -> state -> wholesale price
    private var cache: [String: [String: Double]] = [:]
    private var lastFetch: Date?
    private let ttl: TimeInterval = 6 * 3600

    // MARK: - Public API

    func price(productName: String, state: String) async -> Double? {
        await loadIfNeeded()
        let key = normalize(productName)

        if let prices = cache[key] {
            return prices[state] ?? prices.values.first
        }
        for (alias, conabKey) in Self.aliases {
            if key.contains(alias) {
                if let prices = cache[conabKey] { return prices[state] ?? prices.values.first }
                for (cacheKey, prices) in cache where cacheKey.contains(conabKey) {
                    return prices[state] ?? prices.values.first
                }
            }
        }
        return nil
    }

    nonisolated static func uf(lat: Double, lon: Double) async -> String? {
        let geocoder = CLGeocoder()
        guard let pms = try? await geocoder.reverseGeocodeLocation(
            CLLocation(latitude: lat, longitude: lon)
        ), let admin = pms.first?.administrativeArea else { return nil }
        return stateCode[admin]
    }

    // MARK: - Fetch

    private func loadIfNeeded() async {
        guard lastFetch == nil || Date().timeIntervalSince(lastFetch!) > ttl else { return }
        await fetchData()
    }

    private func fetchData() async {
        var comps = URLComponents(string: "https://pentahoportaldeinformacoes.conab.gov.br/pentaho/plugin/cda/api/doQuery")!
        comps.queryItems = [
            .init(name: "path",         value: "/home/PROHORT/precoDia.cda"),
            .init(name: "dataAccessId", value: "MDXProdutoPreco"),
            .init(name: "userid",       value: "pentaho"),
            .init(name: "password",     value: "password"),
        ]
        guard let url = comps.url,
              let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let metadata  = json["metadata"]  as? [[String: Any]],
              let resultset = json["resultset"] as? [[Any]]
        else { return }

        var stateByCol: [Int: String] = [:]
        for col in metadata {
            guard let idx  = col["colIndex"] as? Int, idx > 0,
                  let name = col["colName"]  as? String else { continue }
            let clean = name.uppercased()
                .replacingOccurrences(of: #"\s*\(\d{2}/\d{2}/\d{4}\)"#, with: "",
                                      options: .regularExpression)
            for (frag, state) in Self.ceasaStates where clean.contains(frag) {
                stateByCol[idx] = state
                break
            }
        }

        var updated: [String: [String: Double]] = [:]
        for row in resultset {
            guard let rawName = row.first as? String else { continue }
            let key = rawName
                .replacingOccurrences(of: #"\s*\([^)]+\)"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            let normalizedKey = normalize(key)

            var prices: [String: Double] = [:]
            for (idx, state) in stateByCol {
                guard idx < row.count, let num = row[idx] as? NSNumber else { continue }
                let v = num.doubleValue
                if v > 0 { prices[state] = v }
            }
            if !prices.isEmpty { updated[normalizedKey] = prices }
        }

        cache = updated
        lastFetch = Date()
    }

    private nonisolated func normalize(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    // MARK: - Tables

    nonisolated static let aliases: [String: String] = [
        "tomate":     "tomate",
        "batata":     "batata",
        "cebola":     "cebola",
        "cenoura":    "cenoura",
        "alface":     "alface",
        "banana":     "banana nanica",
        "maca":       "maca fuji",
        "laranja":    "laranja pera",
        "limao":      "limao taiti",
        "alho":       "alho nacional",
        "frango":     "frango inteiro",
        "abacate":    "abacate",
        "mamao":      "mamao papaia",
        "manga":      "manga palmer",
        "pepino":     "pepino",
        "abobrinha":  "abobrinha",
        "pimentao":   "pimentao vermelho",
        "brocolis":   "brocolis",
        "couve":      "couve",
        "melancia":   "melancia",
        "melao":      "melao amarelo",
    ]

    nonisolated static let ceasaStates: [(String, String)] = [
        ("CEAGESP SAO PAULO", "SP"), ("CAMPINAS", "SP"), ("RIBEIRAO PRETO", "SP"), ("SOROCABA", "SP"),
        ("CURITIBA", "PR"),
        ("BELO HORIZONTE", "MG"), ("UBERLANDIA", "MG"),
        ("RIO DE JANEIRO", "RJ"),
        ("PORTO ALEGRE", "RS"),
        ("FLORIANOPOLIS", "SC"), ("JOINVILLE", "SC"),
        ("GOIANIA", "GO"),
        ("BRASILIA", "DF"),
        ("SALVADOR", "BA"),
        ("RECIFE", "PE"), ("CARUARU", "PE"),
        ("FORTALEZA", "CE"),
        ("MANAUS", "AM"),
        ("BELEM", "PA"), ("MARABA", "PA"),
        ("MACEIO", "AL"),
        ("NATAL", "RN"),
        ("CAMPO GRANDE", "MS"),
        ("VITORIA", "ES"),
        ("ARACAJU", "SE"),
        ("TERESINA", "PI"),
        ("CAMPINA GRANDE", "PB"),
    ]

    nonisolated static let stateCode: [String: String] = [
        "Acre": "AC", "Alagoas": "AL", "Amapá": "AP", "Amazonas": "AM",
        "Bahia": "BA", "Ceará": "CE", "Distrito Federal": "DF",
        "Espírito Santo": "ES", "Goiás": "GO", "Maranhão": "MA",
        "Mato Grosso": "MT", "Mato Grosso do Sul": "MS", "Minas Gerais": "MG",
        "Pará": "PA", "Paraíba": "PB", "Paraná": "PR", "Pernambuco": "PE",
        "Piauí": "PI", "Rio de Janeiro": "RJ", "Rio Grande do Norte": "RN",
        "Rio Grande do Sul": "RS", "Rondônia": "RO", "Roraima": "RR",
        "Santa Catarina": "SC", "São Paulo": "SP", "Sergipe": "SE",
        "Tocantins": "TO",
    ]
}
