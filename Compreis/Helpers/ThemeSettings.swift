import SwiftUI
import UIKit

// MARK: - Preset

enum ThemePreset: String, CaseIterable {
    case standard = "Padrão"
    case blue     = "Azul"
    case purple   = "Roxo"
    case green    = "Verde"
    case orange   = "Laranja"
    case red      = "Vermelho"
    case custom   = "Personalizado"

    var color: Color {
        switch self {
        case .standard: return Color(red: 0.13, green: 0.55, blue: 0.25)
        case .blue:     return Color(red: 0.00, green: 0.48, blue: 1.00)
        case .purple:   return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .green:    return Color(red: 0.07, green: 0.68, blue: 0.55)
        case .orange:   return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .red:      return Color(red: 1.00, green: 0.23, blue: 0.19)
        case .custom:   return .clear
        }
    }

    var icon: String {
        switch self {
        case .standard: return "leaf.fill"
        case .blue:     return "drop.fill"
        case .purple:   return "sparkles"
        case .green:    return "waveform.path.ecg"
        case .orange:   return "sun.max.fill"
        case .red:      return "heart.fill"
        case .custom:   return "paintpalette.fill"
        }
    }
}

// MARK: - Background style

enum BackgroundStyle: String, CaseIterable {
    case neutral = "Neutro"
    case soft    = "Suave"
    case solid   = "Sólido"

    var description: String {
        switch self {
        case .neutral: return "Default iOS system background."
        case .soft:    return "Subtle accent colour on list items."
        case .solid:   return "Stronger accent colour on item backgrounds."
        }
    }
}

// MARK: - ThemeSettings

@Observable final class ThemeSettings {
    nonisolated(unsafe) static let shared = ThemeSettings()

    var preset: ThemePreset = .standard {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: "tema_preset") }
    }

    var customColor: Color = Color(red: 0.13, green: 0.55, blue: 0.25) {
        didSet { persistCustomColor() }
    }

    var backgroundStyle: BackgroundStyle = .neutral {
        didSet { UserDefaults.standard.set(backgroundStyle.rawValue, forKey: "tema_fundo") }
    }

    init() {
        let ud = UserDefaults.standard
        if let raw = ud.string(forKey: "tema_preset"),
           let p = ThemePreset(rawValue: raw) { preset = p }
        if let raw = ud.string(forKey: "tema_fundo"),
           let f = BackgroundStyle(rawValue: raw) { backgroundStyle = f }
        let r = ud.double(forKey: "tema_cr")
        let g = ud.double(forKey: "tema_cg")
        let b = ud.double(forKey: "tema_cb")
        if r + g + b > 0 { customColor = Color(red: r, green: g, blue: b) }
    }

    var accent: Color { preset == .custom ? customColor : preset.color }
    var accentSubtle: Color { accent.opacity(0.15) }
    var accentBorder: Color { accent.opacity(0.25) }

    var rowBackground: Color {
        switch backgroundStyle {
        case .neutral: return Color(.secondarySystemGroupedBackground)
        case .soft:    return accent.opacity(0.07)
        case .solid:   return accent.opacity(0.15)
        }
    }

    private func persistCustomColor() {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(customColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        let ud = UserDefaults.standard
        ud.set(Double(r), forKey: "tema_cr")
        ud.set(Double(g), forKey: "tema_cg")
        ud.set(Double(b), forKey: "tema_cb")
    }
}
