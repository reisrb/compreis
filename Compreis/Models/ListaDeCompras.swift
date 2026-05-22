import Foundation
import SwiftData

@Model
final class ListaDeCompras {
    var criadaEm: Date
    var finalizadaEm: Date?
    var finalizada: Bool
    @Relationship(deleteRule: .cascade, inverse: \Item.lista) var itens: [Item] = []

    init(criadaEm: Date = .now) {
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
