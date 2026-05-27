import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var item: Item?
    var listaUF: String? = nil
    var nomesExistentes: [String] = []
    var emAndamento: Bool = false
    var onSave: (String, Double, Unidade, Double, Categoria, Bool) -> Void

    @State private var nome: String = ""
    @State private var precoText: String = "0,00"
    @State private var precoCentavos: Int = 0
    @State private var unidade: Unidade = .unidade
    @State private var categoria: Categoria = .outros
    @State private var quantidadeInt: Int = 1
    @State private var pesoDisplay: String = "0,000"
    @State private var pesoGramas: Int = 0
    @State private var sugestoes: [ProdutoHistorico] = []
    @State private var mlResultados: [MLProduto] = []
    @State private var mlBuscando = false
    @State private var mlTask: Task<Void, Never>?
    @State private var conabInfo: (preco: Double, uf: String)?
    @State private var conabTask: Task<Void, Never>?
    @State private var confirmandoDelecao: ProdutoHistorico? = nil
    @State private var itensEmUso: [Item] = []
    @State private var showDeleteAlert = false
    @State private var showRenomearSheet = false
    @State private var novoNomeRenomear = ""
    @State private var showDuplicataAlert = false
    @State private var showDestinoDialog = false

    private var pesoValor: Double { Double(pesoGramas) / 1000.0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Product name", text: $nome)
                            .onChange(of: nome) { _, novo in
                                buscarSugestoes(novo)
                                agendarBuscaML(novo)
                                agendarBuscaCONAB(novo)
                            }
                    }
                    if !sugestoes.isEmpty {
                        ForEach(sugestoes) { s in
                            Button { aplicarSugestao(s) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.nome).foregroundStyle(.primary)
                                        Text("\(s.preco.brl) / \(s.unidade.rawValue)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption).foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet { tentarDeletar(sugestoes[idx]) }
                        }
                    }
                    if let info = conabInfo {
                        Button { aplicarCONAB(info.preco) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CONAB Ref. · \(info.uf) (wholesale)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("\(info.preco.brl) / kg")
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption).foregroundStyle(Color.green.opacity(0.8))
                            }
                        }
                    }
                    if mlBuscando {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text("Searching products…")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if !mlResultados.isEmpty {
                        ForEach(mlResultados) { p in
                            Button { aplicarML(p) } label: {
                                HStack(spacing: 10) {
                                    AsyncImage(url: p.thumbnail) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.secondary.opacity(0.15)
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.titulo)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        Text("Fill in the price")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        Image(systemName: categoria.icone)
                            .foregroundStyle(categoria.cor)
                            .frame(width: 20)
                        Picker("Category", selection: $categoria) {
                            ForEach(Categoria.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icone).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.accent)
                    }
                } header: { RockSectionHeader(title: "Product") }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "brazilianrealsign")
                            .foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("0,00", text: $precoText)
                            .keyboardType(.numberPad)
                            .monospacedDigit()
                            .onChange(of: precoText) { _, newVal in
                                let digits = String(newVal.filter { $0.isNumber }.prefix(8))
                                let n = Int(digits) ?? 0
                                precoCentavos = n
                                let formatted = String(format: "%d,%02d", n / 100, n % 100)
                                if precoText != formatted { precoText = formatted }
                            }
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(AppTheme.accent).frame(width: 20)
                        Picker("Unit", selection: $unidade) {
                            ForEach(Unidade.allCases, id: \.self) { u in
                                Text(u.rawValue == "un" ? "Per unit" : "Per kg").tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.accent)
                    }
                } header: { RockSectionHeader(title: "Price") }

                Section {
                    if unidade == .kg {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(AppTheme.accent).frame(width: 20)
                            TextField("0,000", text: $pesoDisplay)
                                .keyboardType(.numberPad)
                                .monospacedDigit()
                                .onChange(of: pesoDisplay) { _, newVal in
                                    let digits = String(newVal.filter { $0.isNumber }.prefix(7))
                                    let n = Int(digits) ?? 0
                                    pesoGramas = n
                                    let formatted = String(format: "%d,%03d", n / 1000, n % 1000)
                                    if pesoDisplay != formatted { pesoDisplay = formatted }
                                }
                            Text("kg")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    } else {
                        HStack {
                            Button {
                                if quantidadeInt > 1 { quantidadeInt -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(quantidadeInt > 1 ? Color.green : Color.gray)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("\(quantidadeInt)")
                                .font(.title2.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 40, alignment: .center)
                            Spacer()
                            Button {
                                quantidadeInt += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundStyle(Color.green)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                } header: { Text(unidade == .kg ? "Weight — \(pesoGramas)g" : "Quantity") }

                if isValid {
                    Section {
                        HStack {
                            Text("Item total").foregroundStyle(.secondary)
                            Spacer()
                            let preco = Double(precoCentavos) / 100.0
                            let qtd = unidade == .kg ? pesoValor : Double(quantidadeInt)
                            Text((preco * qtd).brl)
                                .font(.body.weight(.bold).monospacedDigit())
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .tint(AppTheme.accent)
                }
            }
            .onAppear { populate() }
            .confirmationDialog("Where to add?", isPresented: $showDestinoDialog) {
                Button("Cart (already picked)") { confirmarSave(pegou: true) }
                Button("List") { confirmarSave(pegou: false) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Add to cart or to list?") }
            .alert("Product already in list", isPresented: $showDuplicataAlert) {
                Button("Add anyway") { confirmarSave(pegou: false) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\"\(nome.trimmingCharacters(in: .whitespaces))\" is already in this list.")
            }
            .alert("Product in use", isPresented: $showDeleteAlert, presenting: confirmandoDelecao) { hist in
                Button("Delete and remove from lists", role: .destructive) {
                    for item in itensEmUso { context.delete(item) }
                    context.delete(hist)
                    sugestoes.removeAll { $0.nome == hist.nome }
                    confirmandoDelecao = nil; itensEmUso = []
                }
                Button("Rename items") {
                    novoNomeRenomear = hist.nome
                    showRenomearSheet = true
                }
                Button("Cancel", role: .cancel) {
                    confirmandoDelecao = nil; itensEmUso = []
                }
            } message: { hist in
                let n = itensEmUso.count
                Text("\"\(hist.nome)\" is in \(n) \(n == 1 ? "item" : "items") in active lists. What do you want to do?")
            }
            .sheet(isPresented: $showRenomearSheet) {
                RenomearProdutoSheet(
                    nomeAtual: confirmandoDelecao?.nome ?? "",
                    onConfirmar: { novoNome in
                        if let hist = confirmandoDelecao {
                            let nomeAntigo = hist.nome
                            for item in itensEmUso { item.nome = novoNome }
                            let descH = FetchDescriptor<ProdutoHistorico>(predicate: #Predicate { $0.nome == novoNome })
                            let existeNovo = ((try? context.fetch(descH))?.first) != nil
                            if !existeNovo, let primeiro = itensEmUso.first {
                                context.insert(ProdutoHistorico(
                                    nome: novoNome, preco: primeiro.preco,
                                    unidade: primeiro.unidade, categoria: primeiro.categoria
                                ))
                            }
                            context.delete(hist)
                            if nome.localizedCaseInsensitiveCompare(nomeAntigo) == .orderedSame {
                                nome = novoNome
                            }
                            sugestoes.removeAll { $0.nome == nomeAntigo }
                            buscarSugestoes(nome)
                            confirmandoDelecao = nil; itensEmUso = []
                        }
                    },
                    onCancelar: {
                        confirmandoDelecao = nil; itensEmUso = []
                    }
                )
            }
        }
    }

    private var isValid: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(precoText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func populate() {
        guard let item else { return }
        nome = item.nome
        precoCentavos = Int((item.preco * 100).rounded())
        precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
        unidade = item.unidade
        categoria = item.categoria
        if item.unidade == .unidade {
            quantidadeInt = Int(item.quantidade)
        } else {
            pesoGramas = Int((item.quantidade * 1000).rounded())
            pesoDisplay = String(format: "%d,%03d", pesoGramas / 1000, pesoGramas % 1000)
        }
    }

    private func buscarSugestoes(_ texto: String) {
        guard texto.count >= 2 else { sugestoes = []; return }
        let fetch = FetchDescriptor<ProdutoHistorico>()
        let todos = (try? context.fetch(fetch)) ?? []
        sugestoes = todos
            .filter { $0.nome.localizedCaseInsensitiveContains(texto) }
            .sorted { $0.nome < $1.nome }
            .prefix(4)
            .map { $0 }
    }

    private func aplicarSugestao(_ s: ProdutoHistorico) {
        nome = s.nome
        precoCentavos = Int((s.preco * 100).rounded())
        precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
        unidade = s.unidade
        categoria = s.categoria
        quantidadeInt = 1
        pesoGramas = 0
        pesoDisplay = "0,000"
        sugestoes = []
    }

    private func agendarBuscaML(_ texto: String) {
        mlTask?.cancel()
        mlResultados = []
        guard texto.count >= 3 else { mlBuscando = false; return }
        mlTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await MainActor.run { mlBuscando = true }
            let resultados = await MLService.buscar(texto)
            await MainActor.run {
                mlResultados = resultados
                mlBuscando = false
            }
        }
    }

    private func aplicarML(_ p: MLProduto) {
        nome = p.titulo
        // Search saved price in history for this product
        let fetch = FetchDescriptor<ProdutoHistorico>()
        let hist = (try? context.fetch(fetch)) ?? []
        if let match = hist.first(where: { $0.nome.localizedCaseInsensitiveContains(p.titulo) ||
                                           p.titulo.localizedCaseInsensitiveContains($0.nome) }),
           match.preco > 0 {
            precoCentavos = Int((match.preco * 100).rounded())
            precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
            unidade = match.unidade
            categoria = match.categoria
        } else {
            precoCentavos = 0
            precoText = "0,00"
        }
        quantidadeInt = 1
        mlResultados = []
        sugestoes = []
    }

    private func agendarBuscaCONAB(_ texto: String) {
        conabTask?.cancel()
        conabInfo = nil
        guard let uf = listaUF, texto.count >= 3 else { return }
        conabTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            let preco = await CONABService.shared.preco(nomeProduto: texto, uf: uf)
            await MainActor.run {
                if let p = preco { conabInfo = (p, uf) }
            }
        }
    }

    private func aplicarCONAB(_ preco: Double) {
        precoCentavos = Int((preco * 100).rounded())
        precoText = String(format: "%d,%02d", precoCentavos / 100, precoCentavos % 100)
        unidade = .kg
        conabInfo = nil
    }

    private func tentarDeletar(_ historico: ProdutoHistorico) {
        let nomeH = historico.nome
        let desc = FetchDescriptor<Item>(predicate: #Predicate { $0.nome == nomeH })
        let usados = (try? context.fetch(desc)) ?? []
        confirmandoDelecao = historico
        itensEmUso = usados
        if usados.isEmpty {
            context.delete(historico)
            sugestoes.removeAll { $0.nome == nomeH }
            confirmandoDelecao = nil
        } else {
            showDeleteAlert = true
        }
    }

    private func save() {
        let nomeFinal = nome.trimmingCharacters(in: .whitespaces)
        let jaExiste = item == nil && nomesExistentes.contains { $0.localizedCaseInsensitiveCompare(nomeFinal) == .orderedSame }
        if jaExiste {
            showDuplicataAlert = true
            return
        }
        if emAndamento && item == nil {
            showDestinoDialog = true
            return
        }
        confirmarSave(pegou: item?.pegou ?? false)
    }

    private func confirmarSave(pegou: Bool) {
        let preco = Double(precoCentavos) / 100.0
        let quantidade = unidade == .kg ? pesoValor : Double(quantidadeInt)
        onSave(nome.trimmingCharacters(in: .whitespaces), preco, unidade, quantidade, categoria, pegou)
        dismiss()
    }
}

// MARK: - Rename sheet

private struct RenomearProdutoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let nomeAtual: String
    let onConfirmar: (String) -> Void
    let onCancelar: () -> Void

    @State private var novoNome: String = ""
    @State private var historico: [ProdutoHistorico] = []

    private var sugestoes: [ProdutoHistorico] {
        historico.filter { $0.nome != nomeAtual && (novoNome.isEmpty || $0.nome.localizedCaseInsensitiveContains(novoNome)) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("New name", text: $novoNome)
                        .autocorrectionDisabled()
                } header: { Text("Rename \"\(nomeAtual)\" to") }

                if !sugestoes.isEmpty {
                    Section {
                        ForEach(sugestoes) { s in
                            Button { novoNome = s.nome } label: {
                                HStack {
                                    Text(s.nome).foregroundStyle(.primary)
                                    Spacer()
                                    if novoNome == s.nome {
                                        Image(systemName: "checkmark").foregroundStyle(AppTheme.accent)
                                    }
                                }
                            }
                        }
                    } header: { Text("From history") }
                }
            }
            .navigationTitle("Rename product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancelar(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onConfirmar(novoNome.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(novoNome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                novoNome = ""
                let fetch = FetchDescriptor<ProdutoHistorico>(sortBy: [SortDescriptor(\.nome)])
                historico = (try? context.fetch(fetch)) ?? []
            }
        }
    }
}
