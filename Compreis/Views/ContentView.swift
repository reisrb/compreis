import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Bindable var lista: ListaDeCompras

    @State private var showAdd = false
    @State private var editingItem: Item?
    @State private var listaUF: String?
    @State private var showFinalizar = false
    @State private var showDetalhes = false
    @State private var categoriasExpandidas: Set<Categoria> = []
    @State private var pegarItem: Item? = nil
    @State private var moverItem: Item? = nil

    private struct GrupoCategoria {
        let categoria: Categoria
        let pendentes: [Item]
        let pegos: [Item]
    }

    private var grupos: [GrupoCategoria] {
        let porCat = Dictionary(grouping: lista.itens, by: { $0.categoria })
        return Categoria.allCases.compactMap { cat in
            let todos = porCat[cat] ?? []
            guard !todos.isEmpty else { return nil }
            return GrupoCategoria(
                categoria: cat,
                pendentes: todos.filter { !$0.pegou }.sorted { $0.nome < $1.nome },
                pegos:     todos.filter {  $0.pegou }.sorted { $0.nome < $1.nome }
            )
        }
    }

    private var totalItens: Int { lista.itens.count }

    var body: some View {
        Group {
            if lista.itens.isEmpty {
                VStack(spacing: 0) {
                    if !lista.finalizada && !lista.isTemplate {
                        HStack(spacing: 10) {
                            Image(systemName: lista.emAndamento ? "cart.fill.badge.checkmark" : "cart.badge.plus")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(lista.emAndamento ? .orange : .secondary)
                            Text("Modo mercado")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(lista.emAndamento ? .orange : .secondary)
                            Spacer()
                            Button {
                                withAnimation(.spring(duration: 0.2)) { lista.emAndamento.toggle() }
                            } label: {
                                Text(lista.emAndamento ? "Desativar" : "Ativar")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(lista.emAndamento ? Color.orange : AppTheme.accent, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(lista.emAndamento ? Color.orange.opacity(0.10) : Color(.secondarySystemGroupedBackground))
                        Divider()
                    }
                    emptyState
                }
            } else {
                List {
                    if !lista.finalizada && !lista.isTemplate {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: lista.emAndamento ? "cart.fill.badge.checkmark" : "cart.badge.plus")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(lista.emAndamento ? .orange : .secondary)
                                Text("Modo mercado")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(lista.emAndamento ? .orange : .secondary)
                                Spacer()
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { lista.emAndamento.toggle() }
                                } label: {
                                    Text(lista.emAndamento ? "Desativar" : "Ativar")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(lista.emAndamento ? Color.orange : AppTheme.accent, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(lista.emAndamento ? Color.orange.opacity(0.10) : Color(.secondarySystemGroupedBackground))
                    }
                    ForEach(grupos, id: \.categoria) { grupo in
                        Section {
                            // Itens pendentes
                            ForEach(grupo.pendentes) { item in
                                ItemRow(item: item,
                                        onEdit: { editingItem = item },
                                        onPegar: lista.finalizada ? nil : { pegarItem = item },
                                        onMover: lista.finalizada ? nil : { moverItem = item })
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(grupo.pendentes[i]) }
                                SyncService.shared.scheduleSync(context: context)
                            }

                            // Mini-carrinho da categoria
                            if !grupo.pegos.isEmpty {
                                let expandido = categoriasExpandidas.contains(grupo.categoria)
                                Button {
                                    withAnimation(.spring(duration: 0.25)) {
                                        if expandido {
                                            categoriasExpandidas.remove(grupo.categoria)
                                        } else {
                                            categoriasExpandidas.insert(grupo.categoria)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "cart.badge.checkmark")
                                            .font(.caption.weight(.semibold))
                                        Text("No carrinho · \(grupo.pegos.count)")
                                            .font(.caption.weight(.semibold))
                                        Spacer()
                                        Image(systemName: expandido ? "chevron.up" : "chevron.down")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)

                                if expandido {
                                    ForEach(grupo.pegos) { item in
                                        ItemRow(item: item,
                                                onEdit: { editingItem = item },
                                                onMover: lista.finalizada ? nil : { moverItem = item })
                                    }
                                    .onDelete { offsets in
                                        for i in offsets { context.delete(grupo.pegos[i]) }
                                        SyncService.shared.scheduleSync(context: context)
                                    }
                                }
                            }
                        } header: {
                            Label(grupo.categoria.rawValue, systemImage: grupo.categoria.icone)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(grupo.categoria.cor)
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
        .task {
            if let lat = lista.localLatitude, let lon = lista.localLongitude {
                listaUF = await CONABService.uf(lat: lat, lon: lon)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddItemView(listaUF: listaUF, nomesExistentes: lista.itens.map { $0.nome }, emAndamento: lista.emAndamento) { nome, preco, unidade, quantidade, categoria, pegou in
                adicionarItem(nome: nome, preco: preco, unidade: unidade, quantidade: quantidade, categoria: categoria, pegou: pegou)
            }
        }
        .sheet(item: $pegarItem) { item in
            ConfirmarPrecoSheet(item: item) { novoPreco in
                withAnimation(.spring(duration: 0.25)) {
                    item.pegou = true
                    if novoPreco != item.preco {
                        item.preco = novoPreco
                        sincronizarItemGlobal(nomeOriginal: item.nome, novoNome: item.nome, preco: novoPreco, excluindo: item)
                        salvarHistorico(nome: item.nome, preco: novoPreco, unidade: item.unidade, categoria: item.categoria)
                    }
                }
            }
        }
        .sheet(item: $moverItem) { item in
            MoverItemSheet(item: item, listaAtual: lista) { destino in
                if let idx = lista.itens.firstIndex(where: { $0 === item }) {
                    lista.itens.remove(at: idx)
                }
                destino.itens.append(item)
                SyncService.shared.scheduleSync(context: context)
            }
        }
        .sheet(item: $editingItem) { item in
            AddItemView(item: item, listaUF: listaUF) { nome, preco, unidade, quantidade, categoria, _ in
                let nomeOriginal = item.nome
                item.nome = nome
                item.preco = preco
                item.unidade = unidade
                item.quantidade = quantidade
                item.categoria = categoria
                sincronizarItemGlobal(nomeOriginal: nomeOriginal, novoNome: nome, preco: preco, excluindo: item)
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

    private func adicionarItem(nome: String, preco: Double, unidade: Unidade, quantidade: Double, categoria: Categoria, pegou: Bool) {
        let item = Item(nome: nome, preco: preco, unidade: unidade, quantidade: quantidade, categoria: categoria)
        item.pegou = pegou
        lista.itens.append(item)
        sincronizarItemGlobal(nomeOriginal: nome, novoNome: nome, preco: preco, excluindo: item)
        salvarHistorico(nome: nome, preco: preco, unidade: unidade, categoria: categoria)
        SyncService.shared.scheduleSync(context: context)
    }

    private func sincronizarItemGlobal(nomeOriginal: String, novoNome: String, preco: Double, excluindo: Item? = nil) {
        let desc = FetchDescriptor<Item>(predicate: #Predicate { $0.nome == nomeOriginal })
        let todos = (try? context.fetch(desc)) ?? []
        for outro in todos where outro !== excluindo {
            outro.nome = novoNome
            outro.preco = preco
        }
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

// MARK: - Footer

private struct ListaTotalFooter: View {
    let lista: ListaDeCompras
    var onFinalizar: () -> Void

    @State private var showCarrinho = false

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

            if !pegos.isEmpty {
                Button { showCarrinho = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "cart.fill")
                            .font(.caption.weight(.semibold))
                        Text("\(pegos.count)")
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent.opacity(0.85))
                    .clipShape(Capsule())
                }
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
                        Image(systemName: "cart.fill").font(.caption2)
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
        .sheet(isPresented: $showCarrinho) {
            CarrinhoSheet(pegos: pegos, total: totalCarrinho)
        }
    }
}

// MARK: - Carrinho Sheet

private struct CarrinhoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let pegos: [Item]
    let total: Double

    private var porCategoria: [(Categoria, [Item])] {
        let agrupados = Dictionary(grouping: pegos, by: { $0.categoria })
        return Categoria.allCases.compactMap { cat in
            guard let grupo = agrupados[cat], !grupo.isEmpty else { return nil }
            return (cat, grupo.sorted { $0.nome < $1.nome })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(porCategoria, id: \.0) { cat, itens in
                    Section {
                        ForEach(itens) { item in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icone)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(cat.cor)
                                    .frame(width: 20)
                                Text(item.nome)
                                    .font(.subheadline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.total.brl)
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(AppTheme.accent)
                                    Text("\(item.preco.brl) × \(item.unidade == .kg ? String(format: "%.3f kg", item.quantidade) : String(format: "%.0f", item.quantidade))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Label(cat.rawValue, systemImage: cat.icone)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(cat.cor)
                    }
                }

                Section {
                    HStack {
                        Text("Total no carrinho")
                            .font(.body.weight(.bold))
                        Spacer()
                        Text(total.brl)
                            .font(.title3.weight(.heavy).monospacedDigit())
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Carrinho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                        .tint(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Confirmar preço ao colocar no carrinho

private struct ConfirmarPrecoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: Item
    var onConfirmar: (Double) -> Void

    @State private var precoCentavos: Int = 0
    @State private var precoText: String = "0,00"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.nome).font(.headline)
                    HStack(spacing: 4) {
                        Text(item.preco.brl)
                        Text("/ \(item.unidade.rawValue)")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Produto") }

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
                } header: { Text("Confirmar preço") }
            }
            .navigationTitle("Adicionar ao carrinho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        onConfirmar(Double(precoCentavos) / 100.0)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                }
            }
            .onAppear {
                precoCentavos = Int((item.preco * 100).rounded())
                precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
            }
        }
    }
}

// MARK: - Mover item entre listas

private struct MoverItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: Item
    let listaAtual: ListaDeCompras
    var onMover: (ListaDeCompras) -> Void

    @Query(filter: #Predicate<ListaDeCompras> { $0.finalizada == false && $0.isTemplate == false })
    private var ativas: [ListaDeCompras]

    private var destinos: [ListaDeCompras] { ativas.filter { $0.nome != listaAtual.nome } }

    var body: some View {
        NavigationStack {
            List {
                if destinos.isEmpty {
                    Text("Nenhuma outra lista ativa")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(destinos) { lista in
                        Button {
                            onMover(lista)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "cart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(lista.nome).font(.body.weight(.semibold)).foregroundStyle(.primary)
                                    Text("\(lista.itens.count) \(lista.itens.count == 1 ? "item" : "itens")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Mover \"\(item.nome)\" para")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

