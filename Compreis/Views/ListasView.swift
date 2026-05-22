import SwiftUI
import SwiftData

struct ListasView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ListaDeCompras.criadaEm, order: .reverse)
    private var listas: [ListaDeCompras]

    @State private var showNova = false

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
                            Section("Em aberto") {
                                ForEach(ativas) { lista in
                                    NavigationLink(destination: ContentView(lista: lista)) {
                                        ListaRow(lista: lista)
                                    }
                                }
                                .onDelete { offsets in
                                    offsets.map { ativas[$0] }.forEach { context.delete($0) }
                                }
                            }
                        }
                        if !finalizadas.isEmpty {
                            Section("Finalizadas") {
                                ForEach(finalizadas) { lista in
                                    NavigationLink(destination: ContentView(lista: lista)) {
                                        ListaRow(lista: lista)
                                    }
                                }
                                .onDelete { offsets in
                                    offsets.map { finalizadas[$0] }.forEach { context.delete($0) }
                                }
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
                    Button {
                        showNova = true
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
            }
            .sheet(isPresented: $showNova) {
                NovaListaView { nome, data in
                    let nova = ListaDeCompras(nome: nome, dataMercado: data)
                    context.insert(nova)
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
            Text("Nenhuma lista")
                .font(.title2.weight(.semibold))
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
                    .fill(lista.finalizada ? Color.secondary.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: lista.finalizada ? "checkmark.circle" : "cart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(lista.finalizada ? Color.gray : Color.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(lista.nome)
                    .font(.body.weight(.semibold))
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
                    .font(.callout.weight(.bold).monospacedDigit())
                    .foregroundStyle(lista.finalizada ? Color.gray : Color.green)
            }
        }
        .padding(.vertical, 4)
    }
}
