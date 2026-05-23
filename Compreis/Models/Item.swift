import Foundation
import SwiftUI
import SwiftData

@Model
final class Item {
    var nome: String
    var preco: Double
    var unidadeRaw: String
    var quantidade: Double
    var categoriaRaw: String = Categoria.outros.rawValue
    var pegou: Bool = false
    var lista: ListaDeCompras?

    var unidade: Unidade {
        get { Unidade(rawValue: unidadeRaw) ?? .unidade }
        set { unidadeRaw = newValue.rawValue }
    }

    var categoria: Categoria {
        get { Categoria(rawValue: categoriaRaw) ?? .outros }
        set { categoriaRaw = newValue.rawValue }
    }

    init(nome: String, preco: Double, unidade: Unidade, quantidade: Double, categoria: Categoria = .outros) {
        self.nome = nome
        self.preco = preco
        self.unidadeRaw = unidade.rawValue
        self.quantidade = quantidade
        self.categoriaRaw = categoria.rawValue
    }

    var total: Double { preco * quantidade }
}

enum Unidade: String, CaseIterable {
    case unidade = "un"
    case kg = "kg"
}

enum Categoria: String, CaseIterable, Codable, Hashable {
    case hortifruti  = "Hortifruti"
    case carnes      = "Carnes"
    case peixaria    = "Peixaria"
    case laticinios  = "Laticínios"
    case padaria     = "Padaria"
    case bebidas     = "Bebidas"
    case congelados  = "Congelados"
    case mercearia   = "Mercearia"
    case higiene     = "Higiene"
    case limpeza     = "Limpeza"
    case outros      = "Outros"

    var icone: String {
        switch self {
        case .hortifruti: return "leaf.fill"
        case .carnes:     return "fork.knife"
        case .peixaria:   return "fish.fill"
        case .laticinios: return "drop.fill"
        case .padaria:    return "flame.fill"
        case .bebidas:    return "cup.and.heat.waves"
        case .congelados: return "snowflake"
        case .mercearia:  return "shippingbox.fill"
        case .higiene:    return "sparkles"
        case .limpeza:    return "bubbles.and.sparkles.fill"
        case .outros:     return "square.grid.2x2"
        }
    }

    var cor: Color {
        switch self {
        case .hortifruti: return Color(red: 0.20, green: 0.70, blue: 0.30)
        case .carnes:     return Color(red: 0.85, green: 0.25, blue: 0.25)
        case .peixaria:   return Color(red: 0.20, green: 0.55, blue: 0.85)
        case .laticinios: return Color(red: 0.50, green: 0.70, blue: 0.95)
        case .padaria:    return Color(red: 0.95, green: 0.60, blue: 0.15)
        case .bebidas:    return Color(red: 0.25, green: 0.75, blue: 0.80)
        case .congelados: return Color(red: 0.55, green: 0.80, blue: 1.00)
        case .mercearia:  return Color(red: 0.65, green: 0.45, blue: 0.25)
        case .higiene:    return Color(red: 0.70, green: 0.35, blue: 0.90)
        case .limpeza:    return Color(red: 0.30, green: 0.60, blue: 0.95)
        case .outros:     return Color.secondary
        }
    }
}
