import Foundation
import SwiftData

@Model
final class ProdutoHistorico {
    var nome: String
    var preco: Double
    var unidadeRaw: String

    var unidade: Unidade {
        get { Unidade(rawValue: unidadeRaw) ?? .unidade }
        set { unidadeRaw = newValue.rawValue }
    }

    init(nome: String, preco: Double, unidade: Unidade) {
        self.nome = nome
        self.preco = preco
        self.unidadeRaw = unidade.rawValue
    }
}
