import SwiftUI
import UIKit

enum AppTheme {
    static var accent: Color       { ThemeSettings.shared.accent }
    static var accentSubtle: Color { ThemeSettings.shared.accentSubtle }
    static var accentBorder: Color { ThemeSettings.shared.accentBorder }
    static var rowBackground: Color { ThemeSettings.shared.rowBackground }

    static let spend = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.45, blue: 0.45, alpha: 1)
            : UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1)
    })
}

extension View {
    func rockGlow(_ color: Color? = nil, radius: CGFloat = 8) -> some View {
        let c = color ?? AppTheme.accent
        return self
            .shadow(color: c.opacity(0.30), radius: radius)
            .shadow(color: c.opacity(0.12), radius: radius * 2)
    }

    func rockBorder(cornerRadius: CGFloat = 12) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AppTheme.accentBorder, lineWidth: 0.75)
        )
    }
}

struct RockSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppTheme.accent)
                .frame(width: 3, height: 11)
                .cornerRadius(1.5)
            Text(LocalizedStringKey(title)).textCase(.uppercase)
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
