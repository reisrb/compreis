import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var item: Item?
    var onSave: (String, Double, Unidade, Double) -> Void

    @State private var nome: String = ""
    @State private var precoText: String = ""
    @State private var unidade: Unidade = .unidade
    @State private var quantidadeInt: Int = 1
    @State private var pesoDisplay: String = "0,000"
    @State private var pesoGramas: Int = 0
    @State private var sugestoes: [ProdutoHistorico] = []
    @State private var mlResultados: [MLProduto] = []
    @State private var mlBuscando = false
    @State private var mlTask: Task<Void, Never>?

    private var pesoValor: Double { Double(pesoGramas) / 1000.0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Nome do produto", text: $nome)
                            .onChange(of: nome) { _, novo in
                                buscarSugestoes(novo)
                                agendarBuscaML(novo)
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
                    }
                    if mlBuscando {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text("Buscando no Mercado Livre…")
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
                                        Text(p.preco.brl)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: { RockSectionHeader(title: "Produto") }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "brazilianrealsign")
                            .foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("0,00", text: $precoText)
                            .keyboardType(.decimalPad)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(AppTheme.accent).frame(width: 20)
                        Picker("Unidade", selection: $unidade) {
                            ForEach(Unidade.allCases, id: \.self) { u in
                                Text(u.rawValue == "un" ? "Por unidade" : "Por kg").tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.accent)
                    }
                } header: { RockSectionHeader(title: "Preço") }

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
                } header: { Text(unidade == .kg ? "Peso — \(pesoGramas)g" : "Quantidade") }

                if isValid {
                    Section {
                        HStack {
                            Text("Total do item").foregroundStyle(.secondary)
                            Spacer()
                            let preco = Double(precoText.replacingOccurrences(of: ",", with: ".")) ?? 0
                            let qtd = unidade == .kg ? pesoValor : Double(quantidadeInt)
                            Text((preco * qtd).brl)
                                .font(.body.weight(.bold).monospacedDigit())
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "Novo item" : "Editar item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!isValid)
                        .tint(AppTheme.accent)
                }
            }
            .onAppear { populate() }
        }
    }

    private var isValid: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(precoText.replacingOccurrences(of: ",", with: ".")) != nil
            && (unidade == .unidade || pesoValor > 0)
    }

    private func populate() {
        guard let item else { return }
        nome = item.nome
        precoText = String(item.preco)
        unidade = item.unidade
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
        precoText = String(s.preco)
        unidade = s.unidade
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
        precoText = String(format: "%.2f", p.preco).replacingOccurrences(of: ".", with: ",")
        unidade = .unidade
        quantidadeInt = 1
        mlResultados = []
        sugestoes = []
    }

    private func save() {
        let preco = Double(precoText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let quantidade = unidade == .kg ? pesoValor : Double(quantidadeInt)
        onSave(nome.trimmingCharacters(in: .whitespaces), preco, unidade, quantidade)
        dismiss()
    }
}
