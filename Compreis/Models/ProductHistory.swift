import Foundation
import SwiftData

@Model
final class ProductHistory {
    var name: String
    var price: Double
    var unitRaw: String
    var categoryRaw: String = ItemCategory.other.rawValue

    var unit: ItemUnit {
        get { ItemUnit(rawValue: unitRaw) ?? .each }
        set { unitRaw = newValue.rawValue }
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(name: String, price: Double, unit: ItemUnit, category: ItemCategory = .other) {
        self.name = name
        self.price = price
        self.unitRaw = unit.rawValue
        self.categoryRaw = category.rawValue
    }
}
