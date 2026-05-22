import SwiftUI
import UIKit

enum AppTheme {
    // Electric green — mais saturado/neon que o system green
    static let accent = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 1.00, blue: 0.38, alpha: 1)
            : UIColor(red: 0.10, green: 0.72, blue: 0.28, alpha: 1)
    })

    static let accentSubtle = accent.opacity(0.15)
    static let accentBorder = accent.opacity(0.25)
}

extension View {
    // Glow duplo — efeito neon rock
    func rockGlow(_ color: Color = AppTheme.accent, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.55), radius: radius)
            .shadow(color: color.opacity(0.25), radius: radius * 2.5)
    }

    // Borda sutil verde nos cards
    func rockBorder(cornerRadius: CGFloat = 12) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AppTheme.accentBorder, lineWidth: 0.75)
        )
    }
}

// Header de seção estilo rock: barra + texto uppercase espaçado
struct RockSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppTheme.accent)
                .frame(width: 3, height: 11)
                .cornerRadius(1.5)
            Text(title.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
