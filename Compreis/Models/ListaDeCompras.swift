import Foundation
import SwiftData

@Model
final class ListaDeCompras {
    var nome: String
    var dataMercado: Date?
    var criadaEm: Date
    var finalizadaEm: Date?
    var finalizada: Bool
    @Relationship(deleteRule: .cascade, inverse: \Item.lista) var itens: [Item] = []

    init(nome: String, dataMercado: Date? = nil, criadaEm: Date = .now) {
        self.nome = nome
        self.dataMercado = dataMercado
        self.criadaEm = criadaEm
        self.finalizadaEm = nil
        self.finalizada = false
    }

    var total: Double { itens.reduce(0) { $0 + $1.total } }

    var mesAno: String {
        let ref = finalizadaEm ?? criadaEm
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "pt_BR")
        return f.string(from: ref).capitalized
    }
}
