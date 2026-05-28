import SwiftUI
import SwiftData
import UIKit

/// User-created category, complements the built-in Category enum.
/// Item.categoryRaw stores the custom category name directly;
/// when Category(rawValue:) returns nil, it is a custom category.
@Model
final class CustomCategory {
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date

    init(name: String, icon: String = "tag", colorHex: String = "#808080") {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = .now
    }

    var color: Color { Color(hex: colorHex) ?? .gray }
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
