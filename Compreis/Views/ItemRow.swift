import SwiftUI

struct ItemRow: View {
    let item: Item
    var onEdit: () -> Void = {}
    var onPegar: (() -> Void)? = nil
    var onMover: (() -> Void)? = nil
    var cheapestAlt: (mercado: String, preco: Double)? = nil
    var onMoverParaMercadoBarato: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !item.pegou, let onPegar {
                    onPegar()
                } else {
                    withAnimation(.spring(duration: 0.25)) { item.pegou.toggle() }
                }
            } label: {
                Image(systemName: item.pegou ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(item.pegou ? AppTheme.accent : Color.secondary.opacity(0.35))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.nome)
                            .font(.body.weight(.bold))
                            .strikethrough(item.pegou, color: .secondary)
                            .foregroundStyle(item.pegou ? .secondary : .primary)
                        HStack(spacing: 4) {
                            Text(item.preco.brl)
                            Text("/ \(item.unidade.rawValue)")
                            Text("·")
                            Text("\(item.quantidade.formatted()) \(item.unidade.rawValue)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if let alt = cheapestAlt, !item.pegou {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Text("Cheaper at \(alt.mercado): \(alt.preco.brl)/\(item.unidade.rawValue)")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Button {
                                    onMoverParaMercadoBarato?(alt.mercado)
                                } label: {
                                    Text("Go")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 1)
                        }
                    }

                    Spacer()

                    Text(item.total.brl)
                        .font(.callout.weight(.heavy).monospacedDigit())
                        .foregroundStyle(item.pegou ? .secondary : AppTheme.spend)
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let onMover {
                    Button { onMover() } label: {
                        Label("Move to another list", systemImage: "arrow.right.doc.on.clipboard")
                    }
                }
                if let alt = cheapestAlt, let onMoverParaMercadoBarato {
                    Button { onMoverParaMercadoBarato(alt.mercado) } label: {
                        Label("Go to cheapest market (\(alt.mercado))", systemImage: "tag.fill")
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
