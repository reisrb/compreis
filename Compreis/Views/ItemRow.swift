import SwiftUI

struct ItemRow: View {
    let item: Item
    var onEdit: () -> Void = {}
    var onPick: (() -> Void)? = nil
    var onMove: (() -> Void)? = nil
    var cheapestAlt: (market: String, price: Double)? = nil
    var onMoveToCheapestMarket: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !item.picked, let onPick {
                    onPick()
                } else {
                    withAnimation(.spring(duration: 0.25)) { item.picked.toggle() }
                }
            } label: {
                Image(systemName: item.picked ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(item.picked ? AppTheme.accent : Color.secondary.opacity(0.35))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.body.weight(.bold))
                            .strikethrough(item.picked, color: .secondary)
                            .foregroundStyle(item.picked ? .secondary : .primary)
                        HStack(spacing: 4) {
                            Text(item.price.brl)
                            Text("/ \(item.unit.rawValue)")
                            Text("·")
                            Text("\(item.quantity.formatted()) \(item.unit.rawValue)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if let alt = cheapestAlt, !item.picked {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Text("Cheaper at \(alt.market): \(alt.price.brl)/\(item.unit.rawValue)")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Button {
                                    onMoveToCheapestMarket?(alt.market)
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
                        .foregroundStyle(item.picked ? .secondary : AppTheme.spend)
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let onMove {
                    Button { onMove() } label: {
                        Label("Move to another list", systemImage: "arrow.right.doc.on.clipboard")
                    }
                }
                if let alt = cheapestAlt, let onMoveToCheapestMarket {
                    Button { onMoveToCheapestMarket(alt.market) } label: {
                        Label("Go to cheapest market (\(alt.market))", systemImage: "tag.fill")
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
