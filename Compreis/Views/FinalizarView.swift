import SwiftUI

struct FinalizarView: View {
    @Environment(\.dismiss) private var dismiss
    let lista: ListaDeCompras
    var onFinalizar: (Bool) -> Void

    @State private var copiarItens = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Total da compra")
                        Spacer()
                        Text(lista.total.brl)
                            .font(.body.weight(.bold).monospacedDigit())
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Text("Itens")
                        Spacer()
                        Text("\(lista.itens.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Resumo")
                }

                Section {
                    Toggle("Copiar itens para próxima lista", isOn: $copiarItens)
                        .tint(.green)
                } header: {
                    Text("Nova lista")
                } footer: {
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
                        onFinalizar(copiarItens)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.green)
                }
            }
        }
    }
}
