import SwiftUI
import SwiftData

struct ListasView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ListaDeCompras.criadaEm, order: .reverse)
    private var listas: [ListaDeCompras]

    @State private var showNova = false
    @State private var showingDetail: ListaDeCompras?

    private var ativas: [ListaDeCompras] { listas.filter { !$0.finalizada } }
    private var finalizadas: [ListaDeCompras] { listas.filter { $0.finalizada } }

    var body: some View {
        NavigationStack {
            Group {
                if listas.isEmpty {
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
                                        Button(role: .destructive) { context.delete(lista) } label: {
                                            Label("Excluir", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        Button { showingDetail = lista } label: {
                                            Label("Detalhes", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: {
                                RockSectionHeader(title: "Em aberto")
                            }
                        }
                        if !finalizadas.isEmpty {
                            Section {
                                ForEach(finalizadas) { lista in
                                    NavigationLink(destination: ContentView(lista: lista)) {
                                        ListaRow(lista: lista)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { context.delete(lista) } label: {
                                            Label("Excluir", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        Button { showingDetail = lista } label: {
                                            Label("Detalhes", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: {
                                RockSectionHeader(title: "Finalizadas")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Compreis")
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
                NovaListaView { nome, data, localNome, lat, lon in
                    let nova = ListaDeCompras(nome: nome, dataMercado: data,
                                             localNome: localNome,
                                             localLatitude: lat, localLongitude: lon)
                    context.insert(nova)
                }
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

private struct ListaRow: View {
    let lista: ListaDeCompras

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
                    .fill(lista.finalizada
                          ? Color.secondary.opacity(0.12)
                          : AppTheme.accentSubtle)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(
                        lista.finalizada ? Color.clear : AppTheme.accentBorder,
                        lineWidth: 0.75))
                Image(systemName: lista.finalizada ? "checkmark.circle" : "cart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(lista.finalizada ? Color.gray : AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(lista.nome)
                        .font(.body.weight(.bold))
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
                    .foregroundStyle(lista.finalizada ? Color.secondary : AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
