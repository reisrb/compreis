import Foundation
import SwiftData

@Model
final class Market {
    var name: String
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    init(name: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = .now
    }
}
