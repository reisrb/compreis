import SwiftUI

struct NovaListaView: View {
    @Environment(\.dismiss) private var dismiss

    var onCreate: (String, Date?) -> Void

    @State private var nome: String = ""
    @State private var usarData = false
    @State private var dataMercado = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        TextField("Ex: Semana, Churrasco…", text: $nome)
                    }
                } header: {
                    Text("Nome da lista")
                }

                Section {
                    Toggle("Definir data", isOn: $usarData)
                        .tint(.green)
                    if usarData {
                        DatePicker("Data", selection: $dataMercado, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(.green)
                    }
                } header: {
                    Text("Quando vai ao mercado")
                }
            }
            .navigationTitle("Nova lista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        onCreate(nome.isEmpty ? "Lista" : nome, usarData ? dataMercado : nil)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.green)
                }
            }
        }
    }
}
