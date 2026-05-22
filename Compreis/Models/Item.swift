import Foundation
import SwiftData

@Model
final class Item {
    var nome: String
    var preco: Double
    var unidadeRaw: String
    var quantidade: Double

    var unidade: Unidade {
        get { Unidade(rawValue: unidadeRaw) ?? .unidade }
        set { unidadeRaw = newValue.rawValue }
    }

    init(nome: String, preco: Double, unidade: Unidade, quantidade: Double) {
        self.nome = nome
        self.preco = preco
        self.unidadeRaw = unidade.rawValue
        self.quantidade = quantidade
    }

    var total: Double { preco * quantidade }
}

enum Unidade: String, CaseIterable {
    case unidade = "un"
    case kg = "kg"
}
