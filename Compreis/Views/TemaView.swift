import SwiftUI

struct TemaView: View {
    @Environment(ThemeSettings.self) private var theme

    private let colunas = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        @Bindable var theme = theme
        Form {
            // Preview
            Section {
                previewCard
            } header: { Text("Prévia") }

            // Presets
            Section {
                LazyVGrid(columns: colunas, spacing: 16) {
                    ForEach(TemaPreset.allCases.filter { $0 != .custom }, id: \.self) { p in
                        presetSwatch(p, theme: theme)
                    }
                }
                .padding(.vertical, 8)

                Button {
                    withAnimation(.spring(duration: 0.2)) { theme.preset = .custom }
                } label: {
                    HStack {
                        Image(systemName: TemaPreset.custom.icone)
                            .foregroundStyle(theme.preset == .custom ? theme.accent : .secondary)
                        Text("Personalizado").foregroundStyle(.primary)
                        Spacer()
                        if theme.preset == .custom {
                            Image(systemName: "checkmark").foregroundStyle(theme.accent)
                        }
                    }
                }
            } header: { Text("Cor de destaque") }

            if theme.preset == .custom {
                Section {
                    ColorPicker("Escolher cor", selection: $theme.customColor, supportsOpacity: false)
                } header: { Text("Cor personalizada") }
            }

            // Fundo
            Section {
                Picker("Estilo de fundo", selection: $theme.estiloFundo) {
                    ForEach(EstiloFundo.allCases, id: \.self) { e in
                        Text(e.rawValue).tag(e)
                    }
                }
                .pickerStyle(.segmented)

                Text(theme.estiloFundo.descricao)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: { Text("Fundo das listas") }
        }
        .navigationTitle("Aparência")
        .navigationBarTitleDisplayMode(.large)
        .tint(theme.accent)
    }

    // MARK: - Preview

    private var previewCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentSubtle)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(AppTheme.accentBorder, lineWidth: 0.75))
                    Image(systemName: "cart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lista de exemplo").font(.body.weight(.bold))
                    Text("5 itens · dom 08/06").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("R$ 87,50")
                    .font(.callout.weight(.heavy).monospacedDigit())
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.vertical, 4)
            .listRowBackground(AppTheme.rowBackground)

            Divider().padding(.vertical, 8)

            HStack {
                Button("Finalizar") {}
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent, in: Capsule())
                    .rockGlow(radius: 6)
                Spacer()
                Text("R$ 87,50")
                    .font(.title2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(AppTheme.spend)
            }
        }
    }

    // MARK: - Swatch

    @ViewBuilder
    private func presetSwatch(_ preset: TemaPreset, theme: ThemeSettings) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) { theme.preset = preset }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(preset.color)
                        .frame(width: 48, height: 48)
                        .shadow(color: preset.color.opacity(0.35), radius: 6)
                    if theme.preset == preset {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: preset.icone)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Text(preset.rawValue)
                    .font(.caption2)
                    .foregroundStyle(theme.preset == preset ? theme.accent : .secondary)
                    .fontWeight(theme.preset == preset ? .bold : .regular)
            }
        }
        .buttonStyle(.plain)
    }
}
