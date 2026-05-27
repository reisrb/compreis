import Foundation
import SwiftData

/// Preço de um produto em um mercado específico, salvo ao confirmar no carrinho.
@Model
final class PrecoMercado {
    var produtoNome: String
    var mercadoNome: String
    var preco: Double
    var unidadeRaw: String
    var atualizadoEm: Date

    init(produtoNome: String, mercadoNome: String, preco: Double, unidade: Unidade) {
        self.produtoNome = produtoNome
        self.mercadoNome = mercadoNome
        self.preco = preco
        self.unidadeRaw = unidade.rawValue
        self.atualizadoEm = .now
    }

    var unidade: Unidade { Unidade(rawValue: unidadeRaw) ?? .unidade }
}
