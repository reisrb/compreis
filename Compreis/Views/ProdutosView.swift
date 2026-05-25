import SwiftUI
import SwiftData

struct ProdutosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProdutoHistorico.nome) private var produtos: [ProdutoHistorico]

    @State private var editando: ProdutoHistorico? = nil
    @State private var busca = ""

    private var filtrados: [ProdutoHistorico] {
        busca.isEmpty ? produtos : produtos.filter { $0.nome.localizedCaseInsensitiveContains(busca) }
    }

    var body: some View {
        List {
            ForEach(filtrados) { p in
                Button { editando = p } label: {
                    HStack(spacing: 12) {
                        Image(systemName: p.categoria.icone)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(p.categoria.cor)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.nome)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Text(p.preco.brl)
                                Text("/ \(p.unidade.rawValue)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        context.delete(p)
                    } label: { Label("Excluir", systemImage: "trash") }
                }
            }
        }
        .searchable(text: $busca, prompt: "Buscar produto")
        .navigationTitle("Produtos")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(.insetGrouped)
        .overlay {
            if produtos.isEmpty {
                ContentUnavailableView(
                    "Nenhum produto",
                    systemImage: "shippingbox",
                    description: Text("Adicione itens às listas para criar o histórico")
                )
            }
        }
        .sheet(item: $editando) { p in
            ProdutoEditSheet(produto: p)
        }
    }
}

// MARK: - Edit sheet

private struct ProdutoEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var produto: ProdutoHistorico

    @State private var nome: String = ""
    @State private var precoCentavos: Int = 0
    @State private var precoText: String = "0,00"
    @State private var unidade: Unidade = .unidade
    @State private var categoria: Categoria = .outros

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Nome", text: $nome)
                            .autocorrectionDisabled()
                    }
                } header: { Text("Nome") }

                Section {
                    HStack(spacing: 12) {
                        Text("R$").foregroundStyle(.secondary)
                        TextField("0,00", text: $precoText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: precoText) { _, novo in
                                let digits = String(novo.filter { $0.isNumber }.prefix(7))
                                precoCentavos = Int(digits) ?? 0
                                let formatted = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
                                if precoText != formatted { precoText = formatted }
                            }
                    }
                } header: { Text("Preço") }

                Section {
                    Picker("Unidade", selection: $unidade) {
                        ForEach(Unidade.allCases, id: \.self) { u in
                            Text(u.rawValue).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Unidade") }

                Section {
                    Picker("Categoria", selection: $categoria) {
                        ForEach(Categoria.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icone).tag(cat)
                        }
                    }
                } header: { Text("Categoria") }
            }
            .navigationTitle("Editar produto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        produto.nome = nome.trimmingCharacters(in: .whitespaces)
                        produto.preco = Double(precoCentavos) / 100.0
                        produto.unidade = unidade
                        produto.categoria = categoria
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                nome = produto.nome
                precoCentavos = Int((produto.preco * 100).rounded())
                precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
                unidade = produto.unidade
                categoria = produto.categoria
            }
        }
    }
}
