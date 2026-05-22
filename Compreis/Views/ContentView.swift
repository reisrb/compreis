import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Bindable var lista: ListaDeCompras

    @State private var showAdd = false
    @State private var editingItem: Item?
    @State private var showFinalizar = false
    @State private var showDetalhes = false

    private var itens: [Item] { lista.itens.sorted { $0.nome < $1.nome } }

    var body: some View {
        Group {
            if itens.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(itens) { item in
                        ItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { editingItem = item }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(lista.nome)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !itens.isEmpty && !lista.finalizada { EditButton() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button { showDetalhes = true } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !itens.isEmpty { totalFooter }
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
                .padding(.bottom, itens.isEmpty ? 20 : 78)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddItemView { nome, preco, unidade, quantidade in
                let item = Item(nome: nome, preco: preco, unidade: unidade, quantidade: quantidade)
                lista.itens.append(item)
                salvarHistorico(nome: nome, preco: preco, unidade: unidade)
            }
        }
        .sheet(item: $editingItem) { item in
            AddItemView(item: item) { nome, preco, unidade, quantidade in
                item.nome = nome
                item.preco = preco
                item.unidade = unidade
                item.quantidade = quantidade
                salvarHistorico(nome: nome, preco: preco, unidade: unidade)
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
                                               unidade: item.unidade, quantidade: item.quantidade))
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

    private var totalFooter: some View {
        HStack(spacing: 12) {
            if !lista.finalizada {
                Button("Finalizar") { showFinalizar = true }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                    .rockGlow(radius: 6)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(itens.count) \(itens.count == 1 ? "item" : "itens")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(lista.total.brl)
                    .font(.title2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(AppTheme.accent)
                    .rockGlow(radius: 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(itens[i]) }
    }

    private func salvarHistorico(nome: String, preco: Double, unidade: Unidade) {
        let nomeLower = nome.lowercased()
        let fetch = FetchDescriptor<ProdutoHistorico>()
        let todos = (try? context.fetch(fetch)) ?? []
        if let existente = todos.first(where: { $0.nome.lowercased() == nomeLower }) {
            existente.preco = preco
            existente.unidadeRaw = unidade.rawValue
        } else {
            context.insert(ProdutoHistorico(nome: nome, preco: preco, unidade: unidade))
        }
    }
}
