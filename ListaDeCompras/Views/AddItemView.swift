import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss

    var item: Item?
    var onSave: (String, Double, Unidade, Double) -> Void

    @State private var nome: String = ""
    @State private var precoText: String = ""
    @State private var unidade: Unidade = .unidade
    @State private var quantidadeText: String = "1"

    var body: some View {
        NavigationStack {
            Form {
                Section("Produto") {
                    TextField("Nome", text: $nome)
                }
                Section("Preço") {
                    HStack {
                        TextField("0,00", text: $precoText)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $unidade) {
                            ForEach(Unidade.allCases, id: \.self) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
                Section("Quantidade") {
                    TextField("1", text: $quantidadeText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(item == nil ? "Novo item" : "Editar item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear { populate() }
        }
    }

    private var isValid: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(precoText.replacingOccurrences(of: ",", with: ".")) != nil
            && Double(quantidadeText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func populate() {
        guard let item else { return }
        nome = item.nome
        precoText = String(item.preco)
        unidade = item.unidade
        quantidadeText = String(item.quantidade)
    }

    private func save() {
        let preco = Double(precoText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let quantidade = Double(quantidadeText.replacingOccurrences(of: ",", with: ".")) ?? 1
        onSave(nome.trimmingCharacters(in: .whitespaces), preco, unidade, quantidade)
        dismiss()
    }
}
