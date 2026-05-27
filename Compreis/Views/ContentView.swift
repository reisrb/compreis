import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Bindable var lista: ListaDeCompras
    @Query private var todosPrecosMercado: [PrecoMercado]

    @State private var showAdd = false
    @State private var editingItem: Item?
    @State private var listaUF: String?
    @State private var showFinalizar = false
    @State private var showDetalhes = false
    @State private var categoriasExpandidas: Set<Categoria> = []
    @State private var pegarItem: Item? = nil
    @State private var moverItem: Item? = nil
    @State private var mercadoBaratoItem: Item? = nil
    @State private var mercadoBaratoDestino: String? = nil

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
                            Text("Market mode")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(lista.emAndamento ? .orange : .secondary)
                            Spacer()
                            Button {
                                withAnimation(.spring(duration: 0.2)) { lista.emAndamento.toggle() }
                            } label: {
                                Text(lista.emAndamento ? "Disable" : "Enable")
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
                                Text("Market mode")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(lista.emAndamento ? .orange : .secondary)
                                Spacer()
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { lista.emAndamento.toggle() }
                                } label: {
                                    Text(lista.emAndamento ? "Disable" : "Enable")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(lista.emAndamento ? Color.orange : AppTheme.accent, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                            .tutorialAnchor(.modoMercadoBanner)
                        }
                        .listRowBackground(lista.emAndamento ? Color.orange.opacity(0.10) : Color(.secondarySystemGroupedBackground))
                    }
                    ForEach(grupos, id: \.categoria) { grupo in
                        Section {
                            // Pending items
                            ForEach(grupo.pendentes) { item in
                                ItemRow(item: item,
                                        onEdit: { editingItem = item },
                                        onPegar: lista.finalizada ? nil : { pegarItem = item },
                                        onMover: lista.finalizada ? nil : { moverItem = item },
                                        cheapestAlt: lista.finalizada ? nil : cheapestAlt(for: item),
                                        onMoverParaMercadoBarato: lista.finalizada ? nil : { mercado in
                                            mercadoBaratoItem = item
                                            mercadoBaratoDestino = mercado
                                        })
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(grupo.pendentes[i]) }
                                SyncService.shared.scheduleSync(context: context)
                            }

                            // Category mini-cart
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
                                        Text("In cart · \(grupo.pegos.count)")
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
                        .background(lista.emAndamento ? Color.orange : AppTheme.accent)
                        .clipShape(Circle())
                        .rockGlow(radius: 8)
                }
                .tutorialAnchor(.addItemFAB)
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
            ConfirmarPrecoSheet(item: item, mercadoNome: lista.localNome) { novoPreco, novaQuantidade in
                withAnimation(.spring(duration: 0.25)) {
                    item.pegou = true
                    if novoPreco != item.preco {
                        item.preco = novoPreco
                        sincronizarItemGlobal(nomeOriginal: item.nome, novoNome: item.nome, preco: novoPreco, excluindo: item)
                        salvarHistorico(nome: item.nome, preco: novoPreco, unidade: item.unidade, categoria: item.categoria)
                    }
                    if novaQuantidade != item.quantidade {
                        item.quantidade = novaQuantidade
                    }
                    salvarPrecoMercado(nome: item.nome, preco: novoPreco, unidade: item.unidade)
                }
            }
        }
        .sheet(item: $mercadoBaratoItem) { item in
            if let destino = mercadoBaratoDestino {
                MercadoBaratoSheet(item: item, mercadoNome: destino, listaAtual: lista)
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
            Text("Empty list")
                .font(.title2.weight(.heavy))
            Text("Tap + to add products")
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

    private func cheapestAlt(for item: Item) -> (mercado: String, preco: Double)? {
        guard let mercadoAtual = lista.localNome else { return nil }
        let nomeLower = item.nome.lowercased()
        let outros = todosPrecosMercado.filter {
            $0.produtoNome.lowercased() == nomeLower && $0.mercadoNome != mercadoAtual
        }
        guard let cheapest = outros.min(by: { $0.preco < $1.preco }),
              cheapest.preco < item.preco else { return nil }
        return (cheapest.mercadoNome, cheapest.preco)
    }

    private func salvarPrecoMercado(nome: String, preco: Double, unidade: Unidade) {
        guard let mercado = lista.localNome else { return }
        let fetch = FetchDescriptor<PrecoMercado>()
        let todos = (try? context.fetch(fetch)) ?? []
        let nomeLower = nome.lowercased()
        if let existente = todos.first(where: {
            $0.produtoNome.lowercased() == nomeLower && $0.mercadoNome == mercado
        }) {
            existente.preco = preco
            existente.atualizadoEm = .now
        } else {
            context.insert(PrecoMercado(produtoNome: nome, mercadoNome: mercado, preco: preco, unidade: unidade))
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
                Button("Finalize") { onFinalizar() }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(lista.emAndamento ? Color.orange : AppTheme.accent)
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
                    .background(lista.emAndamento ? Color.orange.opacity(0.85) : AppTheme.accent.opacity(0.85))
                    .clipShape(Capsule())
                }
            }

            Spacer()
            if pegos.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalItens) \(totalItens == 1 ? "item" : "items")")
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
                    Text("of \(lista.total.brl) estimated")
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

// MARK: - Cart Sheet

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
                        Text("Total in cart")
                            .font(.body.weight(.bold))
                        Spacer()
                        Text(total.brl)
                            .font(.title3.weight(.heavy).monospacedDigit())
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .tint(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Confirm price when adding to cart

private struct ConfirmarPrecoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: Item
    var mercadoNome: String?
    var onConfirmar: (Double, Double) -> Void  // preco, quantidade

    @State private var precoCentavos: Int = 0
    @State private var precoText: String = "0,00"
    @State private var pesoGramas: Int = 0
    @State private var pesoDisplay: String = "0,000"
    @State private var quantidadeInt: Int = 1
    @State private var precoMercado: Double? = nil  // preço salvo neste mercado

    private var pesoValor: Double { Double(pesoGramas) / 1000.0 }
    private var totalKg: Double { (Double(precoCentavos) / 100.0) * pesoValor }
    private var totalUn: Double { (Double(precoCentavos) / 100.0) * Double(quantidadeInt) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Text(item.nome).font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(item.preco.brl)
                            Text("/ \(item.unidade.rawValue)")
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    if let mercado = mercadoNome {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill").foregroundStyle(AppTheme.accent).font(.caption)
                            Text(mercado).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let pm = precoMercado {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath").foregroundStyle(.orange).font(.caption)
                            Text("Last purchase here: \(pm.brl) / \(item.unidade.rawValue)")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                } header: { Text("Product") }

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
                } header: { Text(item.unidade == .kg ? "Price per kg" : "Confirm price") }

                if item.unidade == .kg {
                    Section {
                        HStack(spacing: 12) {
                            TextField("0,000", text: $pesoDisplay)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: pesoDisplay) { _, novo in
                                    let digits = String(novo.filter { $0.isNumber }.prefix(6))
                                    pesoGramas = Int(digits) ?? 0
                                    let formatted = String(format: "%d,%03d", pesoGramas / 1000, pesoGramas % 1000)
                                    if pesoDisplay != formatted { pesoDisplay = formatted }
                                }
                            Text("kg").foregroundStyle(.secondary)
                        }
                    } header: { Text("Weight") }

                    if pesoValor > 0 {
                        Section {
                            HStack {
                                Text("Total")
                                Spacer()
                                Text(totalKg.brl).font(.headline).foregroundStyle(AppTheme.spend)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Button {
                                if quantidadeInt > 1 { quantidadeInt -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(quantidadeInt > 1 ? AppTheme.accent : Color.gray)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("\(quantidadeInt)")
                                .font(.title2.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 40, alignment: .center)
                            Spacer()
                            Button { quantidadeInt += 1 } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundStyle(AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    } header: { Text("Quantity") }

                    if quantidadeInt > 1 {
                        Section {
                            HStack {
                                Text("Total")
                                Spacer()
                                Text(totalUn.brl).font(.headline).foregroundStyle(AppTheme.spend)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        let novoPreco = Double(precoCentavos) / 100.0
                        let novaQuantidade = item.unidade == .kg ? pesoValor : Double(quantidadeInt)
                        onConfirmar(novoPreco, novaQuantidade)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                }
            }
            .onAppear {
                precoCentavos = Int((item.preco * 100).rounded())
                precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
                if item.unidade == .kg {
                    pesoGramas = Int((item.quantidade * 1000).rounded())
                    pesoDisplay = String(format: "%d,%03d", pesoGramas / 1000, pesoGramas % 1000)
                } else {
                    quantidadeInt = max(1, Int(item.quantidade))
                }
                // fetch price for this market
                if let mercado = mercadoNome {
                    let fetch = FetchDescriptor<PrecoMercado>()
                    let todos = (try? context.fetch(fetch)) ?? []
                    let nomeLower = item.nome.lowercased()
                    precoMercado = todos.first(where: {
                        $0.produtoNome.lowercased() == nomeLower && $0.mercadoNome == mercado
                    })?.preco
                }
            }
        }
    }
}

// MARK: - Go to cheapest market

private struct MercadoBaratoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: Item
    let mercadoNome: String
    let listaAtual: ListaDeCompras

    @Query(filter: #Predicate<ListaDeCompras> { $0.finalizada == false && $0.isTemplate == false })
    private var ativas: [ListaDeCompras]

    private var listaDestino: ListaDeCompras? {
        ativas.first { $0.localNome == mercadoNome && $0 !== listaAtual }
    }

    @State private var precoNesteMercado: Double? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3).foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mercadoNome).font(.headline)
                            if let p = precoNesteMercado {
                                HStack(spacing: 4) {
                                    Text(p.brl)
                                    Text("/ \(item.unidade.rawValue)")
                                }
                                .font(.subheadline).foregroundStyle(.green)
                                let economia = (item.preco - p) * item.quantidade
                                if economia > 0 {
                                    Text("Savings: \(economia.brl)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Cheapest market for \"\(item.nome)\"") }

                Section {
                    if let destino = listaDestino {
                        Button {
                            if let idx = listaAtual.itens.firstIndex(where: { $0 === item }) {
                                listaAtual.itens.remove(at: idx)
                            }
                            destino.itens.append(item)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.doc.on.clipboard")
                                    .foregroundStyle(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Move to \"\(destino.nome)\"")
                                        .font(.body.weight(.semibold)).foregroundStyle(.primary)
                                    Text("\(destino.itens.count) \(destino.itens.count == 1 ? "item" : "items") · \(mercadoNome)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Button {
                            let nova = ListaDeCompras(nome: mercadoNome,
                                                     localNome: mercadoNome)
                            context.insert(nova)
                            if let idx = listaAtual.itens.firstIndex(where: { $0 === item }) {
                                listaAtual.itens.remove(at: idx)
                            }
                            nova.itens.append(item)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create list at \"\(mercadoNome)\"")
                                        .font(.body.weight(.semibold)).foregroundStyle(.primary)
                                    Text("Move item to new list")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: { Text("Action") }
            }
            .navigationTitle("Cheapest market")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                let fetch = FetchDescriptor<PrecoMercado>()
                let todos = (try? context.fetch(fetch)) ?? []
                let nomeLower = item.nome.lowercased()
                precoNesteMercado = todos.first(where: {
                    $0.produtoNome.lowercased() == nomeLower && $0.mercadoNome == mercadoNome
                })?.preco
            }
        }
    }
}

// MARK: - Move item between lists

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
                    Text("No other active list")
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
                                    Text("\(lista.itens.count) \(lista.itens.count == 1 ? "item" : "items")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Move \"\(item.nome)\" to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
