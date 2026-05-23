import Foundation
import CoreLocation

actor CONABService {
    static let shared = CONABService()
    private init() {}

    // prodKey (normalizado) -> uf -> preço atacado
    private var cache: [String: [String: Double]] = [:]
    private var lastFetch: Date?
    private let ttl: TimeInterval = 6 * 3600

    // MARK: - API pública

    func preco(nomeProduto: String, uf: String) async -> Double? {
        await carregarSeNecessario()
        let key = normalizar(nomeProduto)

        // Match direto
        if let precos = cache[key] {
            return precos[uf] ?? precos.values.first
        }
        // Match via alias
        for (alias, conabKey) in Self.aliases {
            if key.contains(alias) {
                if let precos = cache[conabKey] { return precos[uf] ?? precos.values.first }
                // partial: algum key do cache contém conabKey
                for (cacheKey, precos) in cache where cacheKey.contains(conabKey) {
                    return precos[uf] ?? precos.values.first
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
        return estadoUF[admin]
    }

    // MARK: - Fetch

    private func carregarSeNecessario() async {
        guard lastFetch == nil || Date().timeIntervalSince(lastFetch!) > ttl else { return }
        await buscarDados()
    }

    private func buscarDados() async {
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

        // Mapeia colIndex → UF
        var colUF: [Int: String] = [:]
        for col in metadata {
            guard let idx  = col["colIndex"] as? Int, idx > 0,
                  let nome = col["colName"]  as? String else { continue }
            let clean = nome.uppercased()
                .replacingOccurrences(of: #"\s*\(\d{2}/\d{2}/\d{4}\)"#, with: "",
                                      options: .regularExpression)
            for (frag, uf) in Self.ceasaUF where clean.contains(frag) {
                colUF[idx] = uf
                break
            }
        }

        var novo: [String: [String: Double]] = [:]
        for row in resultset {
            guard let rawNome = row.first as? String else { continue }
            // "TOMATE (KG)" → "tomate"
            let key = rawNome
                .replacingOccurrences(of: #"\s*\([^)]+\)"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            let keyNorm = normalizar(key)

            var precos: [String: Double] = [:]
            for (idx, uf) in colUF {
                guard idx < row.count, let num = row[idx] as? NSNumber else { continue }
                let v = num.doubleValue
                if v > 0 { precos[uf] = v }
            }
            if !precos.isEmpty { novo[keyNorm] = precos }
        }

        cache = novo
        lastFetch = Date()
    }

    private nonisolated func normalizar(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    // MARK: - Tabelas

    // nome app (normalizado) → fragmento chave CONAB normalizado
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

    nonisolated static let ceasaUF: [(String, String)] = [
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

    nonisolated static let estadoUF: [String: String] = [
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
