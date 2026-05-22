import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<ListaDeCompras> { !$0.finalizada },
           sort: \ListaDeCompras.criadaEm, order: .reverse)
    private var listasAtivas: [ListaDeCompras]

    @State private var showAdd = false
    @State private var editingItem: Item?
    @State private var showFinalizar = false

    private var lista: ListaDeCompras? { listasAtivas.first }
    private var itens: [Item] { lista?.itens.sorted { $0.nome < $1.nome } ?? [] }
    private var total: Double { lista?.total ?? 0 }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Compreis")
            .toolbar {
                if !itens.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Finalizar") { showFinalizar = true }
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    if !itens.isEmpty { totalFooter }
                    HStack {
                        Spacer()
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(.green)
                                .clipShape(Circle())
                                .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.vertical, 16)
                    }
                    .background(.clear)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddItemView { nome, preco, unidade, quantidade in
                    let item = Item(nome: nome, preco: preco, unidade: unidade, quantidade: quantidade)
                    garantirListaAtiva().itens.append(item)
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
            .sheet(isPresented: $showFinalizar) {
                if let lista {
                    FinalizarView(lista: lista) { copiar in
                        lista.finalizadaEm = .now
                        lista.finalizada = true
                        if copiar {
                            let nova = ListaDeCompras()
                            context.insert(nova)
                            for item in lista.itens {
                                let copia = Item(nome: item.nome, preco: item.preco,
                                                 unidade: item.unidade, quantidade: item.quantidade)
                                nova.itens.append(copia)
                            }
                        }
                    }
                }
            }
        }
        .tint(.green)
        .onAppear { garantirListaAtiva() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.4))
            Text("Lista vazia")
                .font(.title2.weight(.semibold))
            Text("Toque no botão + para adicionar produtos")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var totalFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(itens.count) \(itens.count == 1 ? "item" : "itens")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Total estimado")
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
            Text(total.brl)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    @discardableResult
    private func garantirListaAtiva() -> ListaDeCompras {
        if let lista { return lista }
        let nova = ListaDeCompras()
        context.insert(nova)
        return nova
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
