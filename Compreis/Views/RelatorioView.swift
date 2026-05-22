import SwiftUI
import SwiftData

struct RelatorioView: View {
    @Query(filter: #Predicate<ListaDeCompras> { $0.finalizada },
           sort: \ListaDeCompras.finalizadaEm, order: .reverse)
    private var listas: [ListaDeCompras]

    private var ultimos7dias: Double {
        let corte = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return listas
            .filter { ($0.finalizadaEm ?? .distantPast) >= corte }
            .reduce(0) { $0 + $1.total }
    }

    private var porMes: [(mes: String, listas: [ListaDeCompras])] {
        var grupos: [(mes: String, listas: [ListaDeCompras])] = []
        var mapa: [String: [ListaDeCompras]] = [:]
        for lista in listas {
            let chave = lista.mesAno
            mapa[chave, default: []].append(lista)
        }
        let ordenadas = listas.map { $0.mesAno }.reduce(into: [String]()) {
            if !$0.contains($1) { $0.append($1) }
        }
        for mes in ordenadas {
            grupos.append((mes: mes, listas: mapa[mes] ?? []))
        }
        return grupos
    }

    var body: some View {
        NavigationStack {
            if listas.isEmpty {
                emptyState
                    .navigationTitle("Relatório")
            } else {
                List {
                    Section {
                        MetricaRow(titulo: "Últimos 7 dias", valor: ultimos7dias.brl,
                                   icone: "clock", cor: .blue)
                        if !listas.isEmpty {
                            let mediaMensal = porMes.map { $0.listas.reduce(0) { $0 + $1.total } }.reduce(0, +) / Double(max(porMes.count, 1))
                            MetricaRow(titulo: "Média mensal", valor: mediaMensal.brl,
                                       icone: "calendar", cor: .orange)
                            let mediaCompra = listas.reduce(0) { $0 + $1.total } / Double(listas.count)
                            MetricaRow(titulo: "Média por compra", valor: mediaCompra.brl,
                                       icone: "cart", cor: .green)
                        }
                    } header: {
                        Text("Visão geral")
                    }

                    ForEach(porMes, id: \.mes) { grupo in
                        Section {
                            ForEach(grupo.listas) { lista in
                                ListaFinalizadaRow(lista: lista)
                            }
                            HStack {
                                Text("Total do mês")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(grupo.listas.reduce(0) { $0 + $1.total }.brl)
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.green)
                            }
                            .padding(.vertical, 2)
                        } header: {
                            Text(grupo.mes)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Relatório")
            }
        }
        .tint(.green)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.4))
            Text("Sem compras finalizadas")
                .font(.title2.weight(.semibold))
            Text("Finalize uma compra para ver o relatório")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MetricaRow: View {
    let titulo: String
    let valor: String
    let icone: String
    let cor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(cor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icone)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(cor)
            }
            Text(titulo)
                .foregroundStyle(.primary)
            Spacer()
            Text(valor)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(cor)
        }
    }
}

private struct ListaFinalizadaRow: View {
    let lista: ListaDeCompras

    private var dataFormatada: String {
        guard let data = lista.finalizadaEm else { return "" }
        let f = DateFormatter()
        f.dateFormat = "dd/MM · HH:mm"
        return f.string(from: data)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(dataFormatada)
                    .font(.subheadline)
                Text("\(lista.itens.count) \(lista.itens.count == 1 ? "item" : "itens")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(lista.total.brl)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}
