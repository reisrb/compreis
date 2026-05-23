import Foundation
import SwiftData

@Model
final class ProdutoHistorico {
    var nome: String
    var preco: Double
    var unidadeRaw: String
    var categoriaRaw: String = Categoria.outros.rawValue

    var unidade: Unidade {
        get { Unidade(rawValue: unidadeRaw) ?? .unidade }
        set { unidadeRaw = newValue.rawValue }
    }

    var categoria: Categoria {
        get { Categoria(rawValue: categoriaRaw) ?? .outros }
        set { categoriaRaw = newValue.rawValue }
    }

    init(nome: String, preco: Double, unidade: Unidade, categoria: Categoria = .outros) {
        self.nome = nome
        self.preco = preco
        self.unidadeRaw = unidade.rawValue
        self.categoriaRaw = categoria.rawValue
    }
}
