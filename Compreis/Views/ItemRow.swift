import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "cart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.nome)
                    .font(.body.weight(.semibold))
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
                .font(.callout.weight(.bold).monospacedDigit())
                .foregroundStyle(.green)
        }
        .padding(.vertical, 6)
    }
}
