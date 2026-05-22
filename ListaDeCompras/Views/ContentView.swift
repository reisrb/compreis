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
            List {
                ForEach(items) { item in
                    ItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture { editingItem = item }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Lista de Compras")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
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
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(total.brl)
                            .font(.headline.monospacedDigit())
                    }
                    .padding()
                    .background(.regularMaterial)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddItemView { nome, preco, unidade, quantidade in
                    context.insert(Item(nome: nome, preco: preco, unidade: unidade, quantidade: quantidade))
                }
            }
            .sheet(item: $editingItem) { item in
                AddItemView(item: item) { nome, preco, unidade, quantidade in
                    item.nome = nome
                    item.preco = preco
                    item.unidade = unidade
                    item.quantidade = quantidade
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(items[i]) }
    }
}
