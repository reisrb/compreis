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
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        TextField("Nome do produto", text: $nome)
                    }
                } header: {
                    Text("Produto")
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "brazilianrealsign")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        TextField("0,00", text: $precoText)
                            .keyboardType(.decimalPad)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        Picker("Unidade", selection: $unidade) {
                            ForEach(Unidade.allCases, id: \.self) { u in
                                Text(u.rawValue == "un" ? "Por unidade" : "Por kg").tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.green)
                    }
                } header: {
                    Text("Preço")
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "number")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        TextField("1", text: $quantidadeText)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Quantidade")
                }

                if isValid {
                    Section {
                        HStack {
                            Text("Total do item")
                                .foregroundStyle(.secondary)
                            Spacer()
                            let preco = Double(precoText.replacingOccurrences(of: ",", with: ".")) ?? 0
                            let qtd = Double(quantidadeText.replacingOccurrences(of: ",", with: ".")) ?? 1
                            Text((preco * qtd).brl)
                                .font(.body.weight(.bold).monospacedDigit())
                                .foregroundStyle(.green)
                        }
                    }
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
                        .tint(.green)
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
