import SwiftUI

struct FinalizarView: View {
    @Environment(\.dismiss) private var dismiss
    let lista: ListaDeCompras
    var onFinalizar: (Bool) -> Void

    @State private var copiarItens = true
    @State private var ajustarTotal = false
    @State private var totalText: String = ""
    private var auth: GoogleAuth { GoogleAuth.shared }

    private var totalFinal: Double {
        if ajustarTotal, let v = Double(totalText.replacingOccurrences(of: ",", with: ".")) {
            return v
        }
        return lista.totalCalculado
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Calculated total")
                        Spacer()
                        Text(lista.totalCalculado.brl)
                            .font(.body.weight(.bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Adjust real total", isOn: $ajustarTotal)
                        .tint(AppTheme.accent)

                    if ajustarTotal {
                        HStack(spacing: 12) {
                            Image(systemName: "brazilianrealsign")
                                .foregroundStyle(AppTheme.spend)
                                .frame(width: 20)
                            TextField("0,00", text: $totalText)
                                .keyboardType(.decimalPad)
                                .font(.body.weight(.semibold).monospacedDigit())
                        }

                        if let v = Double(totalText.replacingOccurrences(of: ",", with: ".")) {
                            let diff = v - lista.totalCalculado
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
                        Text(totalFinal.brl)
                            .font(.body.weight(.heavy).monospacedDigit())
                            .foregroundStyle(AppTheme.spend)
                    }

                    HStack {
                        Text("Items")
                        Spacer()
                        Text("\(lista.itens.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: { RockSectionHeader(title: "Summary") }

                Section {
                    Toggle("Copy items to next list", isOn: $copiarItens)
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
                        lista.totalPago = ajustarTotal ? totalFinal : nil
                        onFinalizar(copiarItens)
                        dismiss()
                    }
                    .fontWeight(.heavy)
                    .tint(AppTheme.accent)
                }
            }
            .onAppear {
                totalText = String(format: "%.2f", lista.totalCalculado)
                    .replacingOccurrences(of: ".", with: ",")
            }
        }
    }
}
