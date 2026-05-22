import Foundation
import SwiftData

@Model
final class ListaDeCompras {
    var nome: String
    var dataMercado: Date?
    var criadaEm: Date
    var finalizadaEm: Date?
    var finalizada: Bool
    var localNome: String?
    var localLatitude: Double?
    var localLongitude: Double?
    var totalPago: Double?
    @Relationship(deleteRule: .cascade, inverse: \Item.lista) var itens: [Item] = []

    init(nome: String, dataMercado: Date? = nil, criadaEm: Date = .now,
         localNome: String? = nil, localLatitude: Double? = nil, localLongitude: Double? = nil) {
        self.nome = nome
        self.dataMercado = dataMercado
        self.criadaEm = criadaEm
        self.finalizadaEm = nil
        self.finalizada = false
        self.localNome = localNome
        self.localLatitude = localLatitude
        self.localLongitude = localLongitude
    }

    var totalCalculado: Double { itens.reduce(0) { $0 + $1.total } }
    var total: Double { totalPago ?? totalCalculado }

    var mesAno: String {
        let ref = finalizadaEm ?? criadaEm
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale.current
        return f.string(from: ref).capitalized
    }
}
