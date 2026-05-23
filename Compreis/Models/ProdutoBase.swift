import Foundation
import SwiftData

struct ProdutoSemente {
    let nome: String
    let categoria: Categoria
    let unidade: Unidade
}

enum ListaModelo: String, CaseIterable, Hashable {
    case vazia     = "Vazia"
    case essencial = "Essencial"
    case mensal    = "Do mês"

    var icone: String {
        switch self {
        case .vazia:     return "doc"
        case .essencial: return "cart"
        case .mensal:    return "calendar"
        }
    }

    var detalhe: String {
        switch self {
        case .vazia: return "Em branco"
        default:     return "\(produtos.count) itens"
        }
    }

    var produtos: [ProdutoSemente] {
        switch self {
        case .vazia:     return []
        case .essencial: return ProdutoBase.essencial
        case .mensal:    return ProdutoBase.mensal
        }
    }
}

enum ProdutoBase {

    // MARK: - Essencial (lista do usuário)

    static let essencial: [ProdutoSemente] = [
        // Higiene
        .init(nome: "Papel higiênico",      categoria: .higiene,    unidade: .unidade),
        .init(nome: "Cotonete",              categoria: .higiene,    unidade: .unidade),
        .init(nome: "Algodão",               categoria: .higiene,    unidade: .unidade),
        .init(nome: "Shampoo",               categoria: .higiene,    unidade: .unidade),
        .init(nome: "Condicionador",         categoria: .higiene,    unidade: .unidade),
        .init(nome: "Pasta de dente",        categoria: .higiene,    unidade: .unidade),
        .init(nome: "Sabonete líquido",      categoria: .higiene,    unidade: .unidade),
        // Limpeza
        .init(nome: "Desengordurante",       categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Detergente",            categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Desinfetante Sanol",    categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Água sanitária",        categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Bucha de cozinha",      categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Bucha de banho",        categoria: .limpeza,    unidade: .unidade),
        // Laticínios
        .init(nome: "Leite",                 categoria: .laticinios, unidade: .unidade),
        .init(nome: "Creme de leite",        categoria: .laticinios, unidade: .unidade),
        // Carnes
        .init(nome: "Carne moída",           categoria: .carnes,     unidade: .kg),
        .init(nome: "Frango",                categoria: .carnes,     unidade: .kg),
        .init(nome: "Bife de fígado",        categoria: .carnes,     unidade: .kg),
        // Mercearia
        .init(nome: "Feijão",                categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Arroz",                 categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Óleo de soja",          categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Vinagre",               categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Macarrão",              categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Molho de tomate",       categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Extrato de tomate",     categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Ketchup",               categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Mostarda",              categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Café",                  categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Chocolate em pó",       categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Sal",                   categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Chimichurri",           categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Alho em pó",            categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Páprica defumada",      categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Bicarbonato de sódio",  categoria: .mercearia,  unidade: .unidade),
    ]

    // MARK: - Do mês (essencial + itens extras)

    static let mensal: [ProdutoSemente] = essencial + [
        // Hortifruti
        .init(nome: "Alface",               categoria: .hortifruti, unidade: .unidade),
        .init(nome: "Tomate",               categoria: .hortifruti, unidade: .kg),
        .init(nome: "Cebola",               categoria: .hortifruti, unidade: .kg),
        .init(nome: "Cenoura",              categoria: .hortifruti, unidade: .kg),
        .init(nome: "Batata",               categoria: .hortifruti, unidade: .kg),
        .init(nome: "Banana",               categoria: .hortifruti, unidade: .kg),
        .init(nome: "Maçã",                 categoria: .hortifruti, unidade: .kg),
        .init(nome: "Laranja",              categoria: .hortifruti, unidade: .kg),
        .init(nome: "Limão",                categoria: .hortifruti, unidade: .unidade),
        .init(nome: "Alho",                 categoria: .hortifruti, unidade: .unidade),
        // Laticínios extra
        .init(nome: "Queijo mussarela",     categoria: .laticinios, unidade: .kg),
        .init(nome: "Iogurte",              categoria: .laticinios, unidade: .unidade),
        .init(nome: "Manteiga",             categoria: .laticinios, unidade: .unidade),
        .init(nome: "Requeijão",            categoria: .laticinios, unidade: .unidade),
        .init(nome: "Ovo",                  categoria: .laticinios, unidade: .unidade),
        // Carnes extra
        .init(nome: "Costela",              categoria: .carnes,     unidade: .kg),
        .init(nome: "Linguiça",             categoria: .carnes,     unidade: .kg),
        // Mercearia extra
        .init(nome: "Açúcar",               categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Farinha de trigo",     categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Azeite",               categoria: .mercearia,  unidade: .unidade),
        .init(nome: "Maionese",             categoria: .mercearia,  unidade: .unidade),
        // Padaria
        .init(nome: "Pão de forma",         categoria: .padaria,    unidade: .unidade),
        // Bebidas
        .init(nome: "Água mineral",         categoria: .bebidas,    unidade: .unidade),
        // Higiene extra
        .init(nome: "Fio dental",           categoria: .higiene,    unidade: .unidade),
        .init(nome: "Desodorante",          categoria: .higiene,    unidade: .unidade),
        // Limpeza extra
        .init(nome: "Saco de lixo",         categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Esponja de aço",       categoria: .limpeza,    unidade: .unidade),
        .init(nome: "Sabão em pó",          categoria: .limpeza,    unidade: .unidade),
    ]

    // MARK: - Semente (roda uma vez no primeiro launch)

    static func sementar(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: "semente_v1") else { return }
        let todos = (try? context.fetch(FetchDescriptor<ProdutoHistorico>())) ?? []
        let existentes = Set(todos.map { $0.nome.lowercased() })
        for p in mensal where !existentes.contains(p.nome.lowercased()) {
            context.insert(ProdutoHistorico(nome: p.nome, preco: 0,
                                            unidade: p.unidade, categoria: p.categoria))
        }
        UserDefaults.standard.set(true, forKey: "semente_v1")
    }

    // MARK: - Cria itens na lista com preços do histórico

    static func criarItens(para lista: ListaDeCompras, modelo: ListaModelo, context: ModelContext) {
        guard !modelo.produtos.isEmpty else { return }
        let historico = (try? context.fetch(FetchDescriptor<ProdutoHistorico>())) ?? []
        let mapa = Dictionary(uniqueKeysWithValues:
            Dictionary(grouping: historico, by: { $0.nome.lowercased() })
                .compactMap { k, v -> (String, ProdutoHistorico)? in v.first.map { (k, $0) } }
        )
        for p in modelo.produtos {
            let hist = mapa[p.nome.lowercased()]
            lista.itens.append(Item(
                nome: p.nome,
                preco: hist?.preco ?? 0.0,
                unidade: hist?.unidade ?? p.unidade,
                quantidade: 1.0,
                categoria: p.categoria
            ))
        }
    }
}
