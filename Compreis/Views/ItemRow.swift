import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSubtle)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(AppTheme.accentBorder, lineWidth: 0.75))
                Image(systemName: "cart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.nome)
                    .font(.body.weight(.bold))
                HStack(spacing: 4) {
                    Text(item.preco.brl)
                        .foregroundStyle(.secondary)
                    Text("/ \(item.unidade.rawValue)")
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(item.quantidade.formatted()) \(item.unidade.rawValue)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()

            Text(item.total.brl)
                .font(.callout.weight(.heavy).monospacedDigit())
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.vertical, 6)
    }
}
