import SwiftUI
import SwiftData
import UIKit

/// Categoria criada pelo usuário, complementa o enum Categoria built-in.
/// Item.categoriaRaw armazena o nome da categoria customizada diretamente;
/// quando Categoria(rawValue:) retorna nil, é uma categoria customizada.
@Model
final class CategoriaCustom {
    var nome: String
    var icone: String
    var corHex: String
    var criadaEm: Date

    init(nome: String, icone: String = "tag", corHex: String = "#808080") {
        self.nome = nome
        self.icone = icone
        self.corHex = corHex
        self.criadaEm = .now
    }

    var cor: Color { Color(hex: corHex) ?? .gray }
}

// MARK: - Color hex helpers

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6 else { return nil }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
