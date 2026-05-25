import SwiftUI
import SwiftData

struct ProdutosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProdutoHistorico.nome) private var produtos: [ProdutoHistorico]

    @State private var editando: ProdutoHistorico? = nil
    @State private var showNovo = false
    @State private var busca = ""

    private var filtrados: [ProdutoHistorico] {
        busca.isEmpty ? produtos : produtos.filter { $0.nome.localizedCaseInsensitiveContains(busca) }
    }

    private var porCategoria: [(Categoria, [ProdutoHistorico])] {
        let agrupados = Dictionary(grouping: filtrados, by: { $0.categoria })
        return Categoria.allCases.compactMap { cat in
            guard let grupo = agrupados[cat], !grupo.isEmpty else { return nil }
            return (cat, grupo.sorted { $0.nome < $1.nome })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if produtos.isEmpty {
                    ContentUnavailableView(
                        "Catálogo vazio",
                        systemImage: "shippingbox",
                        description: Text("Toque em + para cadastrar produtos")
                    )
                } else {
                    List {
                        ForEach(porCategoria, id: \.0) { cat, grupo in
                            Section {
                                ForEach(grupo) { p in
                                    Button { editando = p } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(p.nome)
                                                    .font(.body.weight(.semibold))
                                                    .foregroundStyle(.primary)
                                                HStack(spacing: 4) {
                                                    Text(p.preco.brl)
                                                    Text("/ \(p.unidade.rawValue)")
                                                }
                                                .font(.caption).foregroundStyle(.secondary)
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
                            } header: {
                                Label(cat.rawValue, systemImage: cat.icone)
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(cat.cor)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $busca, prompt: "Buscar produto")
                }
            }
            .navigationTitle("Catálogo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNovo = true } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .sheet(item: $editando) { p in
                ProdutoEditSheet(produto: p)
            }
            .sheet(isPresented: $showNovo) {
                NovoProdutoSheet()
            }
        }
    }
}

// MARK: - Novo produto

struct NovoProdutoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var nome = ""
    @State private var precoCentavos = 0
    @State private var precoText = "0,00"
    @State private var unidade: Unidade = .unidade
    @State private var categoria: Categoria = .outros
    @State private var sugestoes: [ProdutoHistorico] = []
    @State private var produtoExistente: ProdutoHistorico? = nil

    private func buscarSugestoes(_ texto: String) {
        guard texto.count >= 2 else { sugestoes = []; produtoExistente = nil; return }
        let fetch = FetchDescriptor<ProdutoHistorico>()
        let todos = (try? context.fetch(fetch)) ?? []
        sugestoes = todos
            .filter { $0.nome.localizedCaseInsensitiveContains(texto) }
            .sorted { $0.nome < $1.nome }
            .prefix(4)
            .map { $0 }
        produtoExistente = todos.first(where: { $0.nome.localizedCaseInsensitiveCompare(texto) == .orderedSame })
    }

    private func aplicar(_ p: ProdutoHistorico) {
        nome = p.nome
        precoCentavos = Int((p.preco * 100).rounded())
        precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
        unidade = p.unidade
        categoria = p.categoria
        sugestoes = []
        produtoExistente = p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag").foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("Nome do produto", text: $nome)
                            .autocorrectionDisabled()
                            .onChange(of: nome) { _, novo in buscarSugestoes(novo) }
                    }
                    if !sugestoes.isEmpty {
                        ForEach(sugestoes) { s in
                            Button { aplicar(s) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.nome).foregroundStyle(.primary)
                                        HStack(spacing: 4) {
                                            Text(s.preco.brl)
                                            Text("/ \(s.unidade.rawValue)")
                                        }
                                        .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption).foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                    }
                    if let existente = produtoExistente {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle").foregroundStyle(.orange)
                            Text("Produto já cadastrado — salvar irá atualizar o preço")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        .padding(.vertical, 2)
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
                                let f = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
                                if precoText != f { precoText = f }
                            }
                    }
                } header: { Text("Preço de referência") }

                Section {
                    Picker("Unidade", selection: $unidade) {
                        ForEach(Unidade.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                } header: { Text("Unidade") }

                Section {
                    Picker("Categoria", selection: $categoria) {
                        ForEach(Categoria.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: $0.icone).tag($0)
                        }
                    }
                } header: { Text("Categoria") }
            }
            .navigationTitle("Novo produto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let nomeFinal = nome.trimmingCharacters(in: .whitespaces)
                        let preco = Double(precoCentavos) / 100.0
                        let fetch = FetchDescriptor<ProdutoHistorico>()
                        let todos = (try? context.fetch(fetch)) ?? []
                        if let existente = todos.first(where: { $0.nome.localizedCaseInsensitiveCompare(nomeFinal) == .orderedSame }) {
                            existente.preco = preco
                            existente.unidade = unidade
                            existente.categoria = categoria
                        } else {
                            context.insert(ProdutoHistorico(nome: nomeFinal, preco: preco, unidade: unidade, categoria: categoria))
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
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
                        Image(systemName: "tag").foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("Nome", text: $nome).autocorrectionDisabled()
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
                        ForEach(Unidade.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                    }.pickerStyle(.segmented)
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
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        produto.nome = nome.trimmingCharacters(in: .whitespaces)
                        produto.preco = Double(precoCentavos) / 100.0
                        produto.unidade = unidade
                        produto.categoria = categoria
                        dismiss()
                    }
                    .fontWeight(.semibold).tint(AppTheme.accent)
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
