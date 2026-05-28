import Foundation
import SwiftUI
import SwiftData

@Model
final class Item {
    var name: String
    var price: Double
    var unitRaw: String
    var quantity: Double
    var categoryRaw: String = ItemCategory.other.rawValue
    var picked: Bool = false
    var list: ShoppingList?

    var unit: ItemUnit {
        get { ItemUnit(rawValue: unitRaw) ?? .each }
        set { unitRaw = newValue.rawValue }
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(name: String, price: Double, unit: ItemUnit, quantity: Double, category: ItemCategory = .other) {
        self.name = name
        self.price = price
        self.unitRaw = unit.rawValue
        self.quantity = quantity
        self.categoryRaw = category.rawValue
    }

    var total: Double { price * quantity }
}

enum ItemUnit: String, CaseIterable {
    case each = "un"
    case kg = "kg"
}

enum ItemCategory: String, CaseIterable, Codable, Hashable {
    case produce    = "Hortifruti"
    case meat       = "Carnes"
    case fish       = "Peixaria"
    case dairy      = "Laticínios"
    case bakery     = "Padaria"
    case beverages  = "Bebidas"
    case frozen     = "Congelados"
    case grocery    = "Mercearia"
    case hygiene    = "Higiene"
    case cleaning   = "Limpeza"
    case other      = "Outros"

    var icon: String {
        switch self {
        case .produce:   return "leaf.fill"
        case .meat:      return "fork.knife"
        case .fish:      return "fish.fill"
        case .dairy:     return "drop.fill"
        case .bakery:    return "flame.fill"
        case .beverages: return "cup.and.heat.waves"
        case .frozen:    return "snowflake"
        case .grocery:   return "shippingbox.fill"
        case .hygiene:   return "sparkles"
        case .cleaning:  return "bubbles.and.sparkles.fill"
        case .other:     return "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .produce:   return Color(red: 0.20, green: 0.70, blue: 0.30)
        case .meat:      return Color(red: 0.85, green: 0.25, blue: 0.25)
        case .fish:      return Color(red: 0.20, green: 0.55, blue: 0.85)
        case .dairy:     return Color(red: 0.50, green: 0.70, blue: 0.95)
        case .bakery:    return Color(red: 0.95, green: 0.60, blue: 0.15)
        case .beverages: return Color(red: 0.25, green: 0.75, blue: 0.80)
        case .frozen:    return Color(red: 0.55, green: 0.80, blue: 1.00)
        case .grocery:   return Color(red: 0.65, green: 0.45, blue: 0.25)
        case .hygiene:   return Color(red: 0.70, green: 0.35, blue: 0.90)
        case .cleaning:  return Color(red: 0.30, green: 0.60, blue: 0.95)
        case .other:     return Color.secondary
        }
    }
}
