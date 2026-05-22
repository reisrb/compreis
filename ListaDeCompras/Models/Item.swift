import Foundation
import SwiftData

@Model
final class Item {
    var nome: String
    var preco: Double
    var unidade: Unidade
    var quantidade: Double

    init(nome: String, preco: Double, unidade: Unidade, quantidade: Double) {
        self.nome = nome
        self.preco = preco
        self.unidade = unidade
        self.quantidade = quantidade
    }

    var total: Double { preco * quantidade }
}

enum Unidade: String, Codable, CaseIterable {
    case unidade = "un"
    case kg = "kg"
}
