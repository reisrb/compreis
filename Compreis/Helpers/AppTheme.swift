import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.78, blue: 0.45, alpha: 1)
            : UIColor(red: 0.13, green: 0.55, blue: 0.25, alpha: 1)
    })

    static let accentSubtle = accent.opacity(0.15)
    static let accentBorder = accent.opacity(0.25)

    static let spend = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.45, blue: 0.45, alpha: 1)
            : UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)
    })
}

extension View {
    // Glow duplo — efeito neon rock
    func rockGlow(_ color: Color = AppTheme.accent, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.30), radius: radius)
            .shadow(color: color.opacity(0.12), radius: radius * 2)
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
