import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [Item]

    @State private var showAdd = false
    @State private var editingItem: Item?

    var total: Double { items.reduce(0) { $0 + $1.total } }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(items) { item in
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                }
                if !items.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !items.isEmpty {
                    totalFooter
                }
            }
            .sheet(isPresented: $showAdd) {
                AddItemView { nome, preco, unidade, quantidade in
                    context.insert(Item(nome: nome, preco: preco, unidade: unidade, quantidade: quantidade))
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
        }
        .tint(.green)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.4))
            Text("Lista vazia")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Toque em + para adicionar produtos")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var totalFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(items.count) \(items.count == 1 ? "item" : "itens")")
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
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(items[i]) }
    }

    private func salvarHistorico(nome: String, preco: Double, unidade: Unidade) {
        let nomeLower = nome.lowercased()
        let fetch = FetchDescriptor<ProdutoHistorico>(
            predicate: #Predicate { $0.nome.localizedStandardContains(nomeLower) }
        )
        if let existente = try? context.fetch(fetch).first(where: { $0.nome.lowercased() == nomeLower }) {
            existente.preco = preco
            existente.unidadeRaw = unidade.rawValue
        } else {
            context.insert(ProdutoHistorico(nome: nome, preco: preco, unidade: unidade))
        }
    }
}
