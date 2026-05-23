import SwiftUI
import SwiftData

struct ListasView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ListaDeCompras.criadaEm, order: .reverse)
    private var listas: [ListaDeCompras]

    @State private var showNova = false
    @State private var showTemplates = false
    @State private var showingDetail: ListaDeCompras?

    private var ativas:     [ListaDeCompras] { listas.filter { !$0.finalizada && !$0.isTemplate } }
    private var finalizadas:[ListaDeCompras] { listas.filter {  $0.finalizada && !$0.isTemplate } }

    var body: some View {
        NavigationStack {
            Group {
                if ativas.isEmpty && finalizadas.isEmpty {
                    emptyState
                } else {
                    List {
                        if !ativas.isEmpty {
                            Section {
                                ForEach(ativas) { lista in
                                    NavigationLink(destination: ContentView(lista: lista)) {
                                        ListaRow(lista: lista)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(lista)
                                            SyncService.shared.scheduleSync(context: context)
                                        } label: { Label("Excluir", systemImage: "trash") }
                                        .tint(.red)
                                        Button { showingDetail = lista } label: {
                                            Label("Detalhes", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: { RockSectionHeader(title: "Em aberto") }
                        }

                        if !finalizadas.isEmpty {
                            Section {
                                ForEach(finalizadas) { lista in
                                    NavigationLink(destination: ContentView(lista: lista)) {
                                        ListaRow(lista: lista)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(lista)
                                            SyncService.shared.scheduleSync(context: context)
                                        } label: { Label("Excluir", systemImage: "trash") }
                                        .tint(.red)
                                        Button { showingDetail = lista } label: {
                                            Label("Detalhes", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: { RockSectionHeader(title: "Finalizadas") }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Compreis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showTemplates = true } label: {
                        Label("Templates", systemImage: "star")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button { showNova = true } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(.black)
                            .frame(width: 58, height: 58)
                            .background(AppTheme.accent)
                            .clipShape(Circle())
                            .rockGlow(radius: 10)
                    }
                    .padding(.trailing, 24)
                    .padding(.vertical, 16)
                }
            }
            .sheet(isPresented: $showNova) {
                NovaListaView { nome, data, localNome, lat, lon, modelo, templateUsuario in
                    let nova = ListaDeCompras(nome: nome, dataMercado: data,
                                             localNome: localNome,
                                             localLatitude: lat, localLongitude: lon)
                    context.insert(nova)
                    if let t = templateUsuario {
                        for item in t.itens {
                            nova.itens.append(Item(nome: item.nome, preco: item.preco,
                                                   unidade: item.unidade, quantidade: item.quantidade,
                                                   categoria: item.categoria))
                        }
                    } else if modelo != .vazia {
                        ProdutoBase.criarItens(para: nova, modelo: modelo, context: context)
                    }
                    SyncService.shared.scheduleSync(context: context)
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatesView()
            }
            .sheet(item: $showingDetail) { lista in
                ListaDetailView(lista: lista)
            }
        }
        .tint(AppTheme.accent)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent.opacity(0.4))
                .rockGlow(radius: 12)
            Text("Nenhuma lista")
                .font(.title2.weight(.heavy))
            Text("Toque em + para criar uma lista")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Templates management

private struct TemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<ListaDeCompras> { $0.isTemplate == true && $0.isPredefined == true },
           sort: \ListaDeCompras.criadaEm, order: .forward)
    private var predefined: [ListaDeCompras]
    @Query(filter: #Predicate<ListaDeCompras> { $0.isTemplate == true && $0.isPredefined == false },
           sort: \ListaDeCompras.criadaEm, order: .reverse)
    private var userTemplates: [ListaDeCompras]

    @State private var showNovo = false
    @State private var showingDetail: ListaDeCompras?

    var body: some View {
        NavigationStack {
            List {
                if !predefined.isEmpty {
                    Section {
                        ForEach(predefined) { t in
                            NavigationLink(destination: ContentView(lista: t)) {
                                ListaRow(lista: t, isTemplate: true)
                            }
                        }
                    } header: { RockSectionHeader(title: "Padrão") }
                }

                Section {
                    if userTemplates.isEmpty {
                        Button { showNovo = true } label: {
                            Label("Criar template", systemImage: "plus")
                                .foregroundStyle(AppTheme.accent)
                        }
                    } else {
                        ForEach(userTemplates) { t in
                            NavigationLink(destination: ContentView(lista: t)) {
                                ListaRow(lista: t, isTemplate: true)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(t)
                                } label: { Label("Excluir", systemImage: "trash") }
                                .tint(.red)
                                Button { showingDetail = t } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                } header: { RockSectionHeader(title: "Meus templates") }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNovo = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNovo) {
                NovaListaView(titulo: "Novo template") { nome, data, localNome, lat, lon, modelo, templateOrigem in
                    let novo = ListaDeCompras(nome: nome, dataMercado: data,
                                              localNome: localNome,
                                              localLatitude: lat, localLongitude: lon)
                    novo.isTemplate = true
                    context.insert(novo)
                    if let t = templateOrigem {
                        for item in t.itens {
                            novo.itens.append(Item(nome: item.nome, preco: item.preco,
                                                   unidade: item.unidade, quantidade: item.quantidade,
                                                   categoria: item.categoria))
                        }
                    } else if modelo != .vazia {
                        ProdutoBase.criarItens(para: novo, modelo: modelo, context: context)
                    }
                }
            }
            .sheet(item: $showingDetail) { t in
                ListaDetailView(lista: t)
            }
        }
        .tint(AppTheme.accent)
    }
}

// MARK: - Row

private struct ListaRow: View {
    let lista: ListaDeCompras
    var isTemplate: Bool = false

    private var dataFormatada: String? {
        guard let data = lista.dataMercado else { return nil }
        let f = DateFormatter()
        f.dateFormat = "dd/MM · HH:mm"
        return f.string(from: data)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isTemplate
                          ? Color.orange.opacity(0.12)
                          : lista.finalizada
                              ? Color.secondary.opacity(0.12)
                              : AppTheme.accentSubtle)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(
                        isTemplate ? Color.orange.opacity(0.4)
                            : lista.finalizada ? Color.clear : AppTheme.accentBorder,
                        lineWidth: 0.75))
                Image(systemName: isTemplate ? "star.fill"
                      : lista.finalizada ? "checkmark.circle" : "cart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isTemplate ? Color.orange
                                     : lista.finalizada ? Color.gray : AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(lista.nome).font(.body.weight(.bold))
                    if lista.localNome != nil {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent.opacity(0.7))
                    }
                }
                HStack(spacing: 6) {
                    Text("\(lista.itens.count) \(lista.itens.count == 1 ? "item" : "itens")")
                        .foregroundStyle(.secondary)
                    if let data = dataFormatada {
                        Text("·").foregroundStyle(.secondary)
                        Text(data).foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if !lista.itens.isEmpty {
                Text(lista.total.brl)
                    .font(.callout.weight(.heavy).monospacedDigit())
                    .foregroundStyle(isTemplate ? Color.orange
                                     : lista.finalizada ? Color.secondary : AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
