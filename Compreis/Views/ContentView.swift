import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Bindable var lista: ListaDeCompras

    @State private var showAdd = false
    @State private var editingItem: Item?
    @State private var showFinalizar = false
    @State private var showDetalhes = false
    @State private var showPegos = false

    private var itensPorCategoria: [(Categoria, [Item])] {
        let unchecked = lista.itens.filter { !$0.pegou }
        let agrupados = Dictionary(grouping: unchecked, by: { $0.categoria })
        return Categoria.allCases.compactMap { cat in
            guard let grupo = agrupados[cat], !grupo.isEmpty else { return nil }
            return (cat, grupo.sorted { $0.nome < $1.nome })
        }
    }

    private var itensPegos: [Item] {
        lista.itens.filter { $0.pegou }.sorted { $0.nome < $1.nome }
    }

    private var totalItens: Int { lista.itens.count }

    var body: some View {
        Group {
            if lista.itens.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(itensPorCategoria, id: \.0) { cat, itens in
                        Section {
                            ForEach(itens) { item in
                                ItemRow(item: item, onEdit: { editingItem = item })
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(itens[i]) }
                                SyncService.shared.scheduleSync(context: context)
                            }
                        } header: {
                            Label(cat.rawValue, systemImage: cat.icone)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(cat.cor)
                        }
                    }

                    if !itensPegos.isEmpty {
                        Section {
                            if showPegos {
                                ForEach(itensPegos) { item in
                                    ItemRow(item: item, onEdit: { editingItem = item })
                                }
                                .onDelete { offsets in
                                    for i in offsets { context.delete(itensPegos[i]) }
                                    SyncService.shared.scheduleSync(context: context)
                                }
                            }
                        } header: {
                            Button {
                                withAnimation(.spring(duration: 0.3)) { showPegos.toggle() }
                            } label: {
                                HStack {
                                    Label("No carrinho · \(itensPegos.count)",
                                          systemImage: "cart.badge.checkmark")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(AppTheme.accent)
                                    Spacer()
                                    Image(systemName: showPegos ? "chevron.up" : "chevron.down")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(lista.nome)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if totalItens > 0 && !lista.finalizada { EditButton() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showDetalhes = true } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if totalItens > 0 {
                ListaTotalFooter(lista: lista, onFinalizar: { showFinalizar = true })
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !lista.finalizada {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.black)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                        .rockGlow(radius: 8)
                }
                .padding(.trailing, 20)
                .padding(.bottom, totalItens == 0 ? 20 : 110)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddItemView { nome, preco, unidade, quantidade, categoria in
                let item = Item(nome: nome, preco: preco, unidade: unidade,
                                quantidade: quantidade, categoria: categoria)
                lista.itens.append(item)
                salvarHistorico(nome: nome, preco: preco, unidade: unidade, categoria: categoria)
                SyncService.shared.scheduleSync(context: context)
            }
        }
        .sheet(item: $editingItem) { item in
            AddItemView(item: item) { nome, preco, unidade, quantidade, categoria in
                item.nome = nome
                item.preco = preco
                item.unidade = unidade
                item.quantidade = quantidade
                item.categoria = categoria
                salvarHistorico(nome: nome, preco: preco, unidade: unidade, categoria: categoria)
                SyncService.shared.scheduleSync(context: context)
            }
        }
        .sheet(isPresented: $showDetalhes) {
            ListaDetailView(lista: lista)
        }
        .sheet(isPresented: $showFinalizar) {
            FinalizarView(lista: lista) { copiar in
                lista.finalizadaEm = .now
                lista.finalizada = true
                if copiar {
                    let nova = ListaDeCompras(nome: lista.nome)
                    context.insert(nova)
                    for item in lista.itens {
                        nova.itens.append(Item(nome: item.nome, preco: item.preco,
                                               unidade: item.unidade, quantidade: item.quantidade,
                                               categoria: item.categoria))
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent.opacity(0.4))
                .rockGlow(radius: 12)
            Text("Lista vazia")
                .font(.title2.weight(.heavy))
            Text("Toque em + para adicionar produtos")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func salvarHistorico(nome: String, preco: Double, unidade: Unidade, categoria: Categoria) {
        let nomeLower = nome.lowercased()
        let fetch = FetchDescriptor<ProdutoHistorico>()
        let todos = (try? context.fetch(fetch)) ?? []
        if let existente = todos.first(where: { $0.nome.lowercased() == nomeLower }) {
            existente.preco = preco
            existente.unidadeRaw = unidade.rawValue
            existente.categoriaRaw = categoria.rawValue
        } else {
            context.insert(ProdutoHistorico(nome: nome, preco: preco, unidade: unidade, categoria: categoria))
        }
    }
}

// MARK: - Footer (struct separado para observar pegou via Observable)

private struct ListaTotalFooter: View {
    let lista: ListaDeCompras
    var onFinalizar: () -> Void

    private var pegos: [Item] { lista.itens.filter { $0.pegou } }
    private var totalCarrinho: Double { pegos.reduce(0) { $0 + $1.total } }
    private var totalItens: Int { lista.itens.count }

    var body: some View {
        HStack(spacing: 12) {
            if !lista.finalizada {
                Button("Finalizar") { onFinalizar() }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                    .rockGlow(radius: 6)
            }
            Spacer()
            if pegos.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalItens) \(totalItens == 1 ? "item" : "itens")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lista.total.brl)
                        .font(.title2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(AppTheme.spend)
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill")
                            .font(.caption2)
                        Text(totalCarrinho.brl)
                            .font(.title3.weight(.heavy).monospacedDigit())
                    }
                    .foregroundStyle(AppTheme.accent)
                    Text("de \(lista.total.brl) estimado")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }
}
