import Foundation
import SwiftData

@Model
final class Mercado {
    var nome: String
    var latitude: Double?
    var longitude: Double?
    var criadoEm: Date

    init(nome: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.nome = nome
        self.latitude = latitude
        self.longitude = longitude
        self.criadoEm = .now
    }
}
