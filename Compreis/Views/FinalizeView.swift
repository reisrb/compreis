import SwiftUI

struct FinalizeView: View {
    @Environment(\.dismiss) private var dismiss
    let list: ShoppingList
    var onFinalize: (Bool) -> Void

    @State private var copyItems = true
    @State private var adjustTotal = false
    @State private var totalText: String = ""
    private var auth: GoogleAuth { GoogleAuth.shared }

    private var finalTotal: Double {
        if adjustTotal, let v = Double(totalText.replacingOccurrences(of: ",", with: ".")) {
            return v
        }
        return list.computedTotal
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Calculated total")
                        Spacer()
                        Text(list.computedTotal.brl)
                            .font(.body.weight(.bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Adjust real total", isOn: $adjustTotal)
                        .tint(AppTheme.accent)

                    if adjustTotal {
                        HStack(spacing: 12) {
                            Image(systemName: "brazilianrealsign")
                                .foregroundStyle(AppTheme.spend)
                                .frame(width: 20)
                            TextField("0,00", text: $totalText)
                                .keyboardType(.decimalPad)
                                .font(.body.weight(.semibold).monospacedDigit())
                        }

                        if let v = Double(totalText.replacingOccurrences(of: ",", with: ".")) {
                            let diff = v - list.computedTotal
                            HStack {
                                Text(diff >= 0 ? "Difference" : "Savings")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text((abs(diff)).brl)
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(diff >= 0 ? AppTheme.spend : AppTheme.accent)
                            }
                        }
                    }

                    HStack {
                        Text("Total to register")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(finalTotal.brl)
                            .font(.body.weight(.heavy).monospacedDigit())
                            .foregroundStyle(AppTheme.spend)
                    }

                    HStack {
                        Text("Items")
                        Spacer()
                        Text("\(list.items.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: { RockSectionHeader(title: "Summary") }

                Section {
                    Toggle("Copy items to next list", isOn: $copyItems)
                        .tint(AppTheme.accent)
                } header: { RockSectionHeader(title: "New list") } footer: {
                    Text("The same products appear in the next list with saved prices.")
                }

                if auth.isConnected {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text("Will be synced with Google Sheets")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } header: { RockSectionHeader(title: "Cloud") }
                }
            }
            .navigationTitle("Finalize purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        list.totalPaid = adjustTotal ? finalTotal : nil
                        onFinalize(copyItems)
                        dismiss()
                    }
                    .fontWeight(.heavy)
                    .tint(AppTheme.accent)
                }
            }
            .onAppear {
                totalText = String(format: "%.2f", list.computedTotal)
                    .replacingOccurrences(of: ".", with: ",")
            }
        }
    }
}
