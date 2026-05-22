import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.nome)
                    .font(.body)
                Text("\(item.preco.brl)/\(item.unidade.rawValue) × \(item.quantidade.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.total.brl)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}
