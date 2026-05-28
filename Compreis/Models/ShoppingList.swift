import Foundation
import SwiftData

@Model
final class ShoppingList {
    var name: String
    var marketDate: Date?
    var createdAt: Date
    var finalizedAt: Date?
    var finalized: Bool
    var marketName: String?
    var latitude: Double?
    var longitude: Double?
    var totalPaid: Double?
    var isTemplate: Bool = false
    var isPredefined: Bool = false
    var inProgress: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Item.list) var items: [Item] = []

    init(name: String, marketDate: Date? = nil, createdAt: Date = .now,
         marketName: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name
        self.marketDate = marketDate
        self.createdAt = createdAt
        self.finalizedAt = nil
        self.finalized = false
        self.marketName = marketName
        self.latitude = latitude
        self.longitude = longitude
    }

    var computedTotal: Double { items.reduce(0) { $0 + $1.total } }
    var total: Double { totalPaid ?? computedTotal }

    var monthYear: String {
        let ref = finalizedAt ?? createdAt
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale.current
        return f.string(from: ref).capitalized
    }
}
