import SwiftUI
import UIKit

// MARK: - Preset

enum TemaPreset: String, CaseIterable {
    case padrao   = "Padrão"
    case azul     = "Azul"
    case roxo     = "Roxo"
    case verde    = "Verde"
    case laranja  = "Laranja"
    case vermelho = "Vermelho"
    case custom   = "Personalizado"

    var color: Color {
        switch self {
        case .padrao:   return Color(red: 0.13, green: 0.55, blue: 0.25)
        case .azul:     return Color(red: 0.00, green: 0.48, blue: 1.00)
        case .roxo:     return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .verde:    return Color(red: 0.07, green: 0.68, blue: 0.55)
        case .laranja:  return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .vermelho: return Color(red: 1.00, green: 0.23, blue: 0.19)
        case .custom:   return .clear
        }
    }

    var icone: String {
        switch self {
        case .padrao:   return "leaf.fill"
        case .azul:     return "drop.fill"
        case .roxo:     return "sparkles"
        case .verde:    return "waveform.path.ecg"
        case .laranja:  return "sun.max.fill"
        case .vermelho: return "heart.fill"
        case .custom:   return "paintpalette.fill"
        }
    }
}

// MARK: - Estilo de fundo

enum EstiloFundo: String, CaseIterable {
    case neutro  = "Neutro"
    case suave   = "Suave"
    case solido  = "Sólido"

    var descricao: String {
        switch self {
        case .neutro:  return "Fundo padrão do sistema iOS."
        case .suave:   return "Leve toque da cor nos itens das listas."
        case .solido:  return "Cor mais presente no fundo dos itens."
        }
    }
}

// MARK: - ThemeSettings

@Observable final class ThemeSettings {
    nonisolated(unsafe) static let shared = ThemeSettings()

    var preset: TemaPreset = .padrao {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: "tema_preset") }
    }

    var customColor: Color = Color(red: 0.13, green: 0.55, blue: 0.25) {
        didSet { persistCustomColor() }
    }

    var estiloFundo: EstiloFundo = .neutro {
        didSet { UserDefaults.standard.set(estiloFundo.rawValue, forKey: "tema_fundo") }
    }

    init() {
        let ud = UserDefaults.standard
        if let raw = ud.string(forKey: "tema_preset"),
           let p = TemaPreset(rawValue: raw) { preset = p }
        if let raw = ud.string(forKey: "tema_fundo"),
           let f = EstiloFundo(rawValue: raw) { estiloFundo = f }
        let r = ud.double(forKey: "tema_cr")
        let g = ud.double(forKey: "tema_cg")
        let b = ud.double(forKey: "tema_cb")
        if r + g + b > 0 { customColor = Color(red: r, green: g, blue: b) }
    }

    var accent: Color { preset == .custom ? customColor : preset.color }
    var accentSubtle: Color { accent.opacity(0.15) }
    var accentBorder: Color { accent.opacity(0.25) }

    var rowBackground: Color {
        switch estiloFundo {
        case .neutro: return Color(.secondarySystemGroupedBackground)
        case .suave:  return accent.opacity(0.07)
        case .solido: return accent.opacity(0.15)
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
