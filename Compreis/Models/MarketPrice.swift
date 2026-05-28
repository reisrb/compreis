import Foundation
import SwiftData

/// Price of a product at a specific market, saved when confirming in the cart.
@Model
final class MarketPrice {
    var productName: String
    var marketName: String
    var price: Double
    var unitRaw: String
    var updatedAt: Date

    init(productName: String, marketName: String, price: Double, unit: ItemUnit) {
        self.productName = productName
        self.marketName = marketName
        self.price = price
        self.unitRaw = unit.rawValue
        self.updatedAt = .now
    }

    var unit: ItemUnit { ItemUnit(rawValue: unitRaw) ?? .each }
}
