import SwiftUI

struct FinalizarView: View {
    @Environment(\.dismiss) private var dismiss
    let lista: ListaDeCompras
    var onFinalizar: (Bool) -> Void

    @State private var copiarItens = true
    @State private var ajustarTotal = false
    @State private var totalText: String = ""

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
                        Text("Total calculado")
                        Spacer()
                        Text(lista.totalCalculado.brl)
                            .font(.body.weight(.bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Ajustar total real", isOn: $ajustarTotal)
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
                                Text(diff >= 0 ? "Diferença" : "Economia")
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
                        Text("Total a registrar")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(totalFinal.brl)
                            .font(.body.weight(.heavy).monospacedDigit())
                            .foregroundStyle(AppTheme.spend)
                    }

                    HStack {
                        Text("Itens")
                        Spacer()
                        Text("\(lista.itens.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: { RockSectionHeader(title: "Resumo") }

                Section {
                    Toggle("Copiar itens para próxima lista", isOn: $copiarItens)
                        .tint(AppTheme.accent)
                } header: { RockSectionHeader(title: "Nova lista") } footer: {
                    Text("Os mesmos produtos aparecem na próxima lista com os preços salvos.")
                }
            }
            .navigationTitle("Finalizar compra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
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
