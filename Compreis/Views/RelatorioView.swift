import SwiftUI
import SwiftData

struct RelatorioView: View {
    @Query(filter: #Predicate<ListaDeCompras> { $0.finalizada },
           sort: \ListaDeCompras.finalizadaEm, order: .reverse)
    private var listas: [ListaDeCompras]
    @Query private var precosMercado: [PrecoMercado]

    @State private var showExemplos = false

    // Mercados com listas finalizadas: nome → (total gasto, visitas)
    private var gastosPorMercado: [(mercado: String, total: Double, visitas: Int)] {
        var mapa: [String: (total: Double, visitas: Int)] = [:]
        for lista in listas {
            guard let nome = lista.localNome else { continue }
            let atual = mapa[nome] ?? (0, 0)
            mapa[nome] = (atual.total + lista.total, atual.visitas + 1)
        }
        return mapa
            .map { (mercado: $0.key, total: $0.value.total, visitas: $0.value.visitas) }
            .sorted { $0.total > $1.total }
    }

    // Produtos comuns em ≥2 mercados + custo de cesta por mercado
    private var comparacaoCesta: [(mercado: String, totalCesta: Double)] {
        // Produto → mercado → preco
        var mapa: [String: [String: Double]] = [:]
        for pm in precosMercado {
            mapa[pm.produtoNome, default: [:]][pm.mercadoNome] = pm.preco
        }
        // Produtos que aparecem em ≥2 mercados
        let comuns = mapa.filter { $0.value.count >= 2 }
        guard !comuns.isEmpty else { return [] }
        // Soma por mercado (usando preço de referência do produto × 1 unidade)
        var totalPorMercado: [String: Double] = [:]
        for (_, mercados) in comuns {
            for (mercado, preco) in mercados {
                totalPorMercado[mercado, default: 0] += preco
            }
        }
        return totalPorMercado
            .map { (mercado: $0.key, totalCesta: $0.value) }
            .sorted { $0.totalCesta < $1.totalCesta }
    }

    private var ultimos7dias: Double {
        let corte = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return listas
            .filter { ($0.finalizadaEm ?? .distantPast) >= corte }
            .reduce(0) { $0 + $1.total }
    }

    private var porMes: [(mes: String, listas: [ListaDeCompras])] {
        var mapa: [String: [ListaDeCompras]] = [:]
        for lista in listas { mapa[lista.mesAno, default: []].append(lista) }
        let ordem = listas.map { $0.mesAno }.reduce(into: [String]()) {
            if !$0.contains($1) { $0.append($1) }
        }
        return ordem.map { (mes: $0, listas: mapa[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            if listas.isEmpty {
                emptyState
                    .navigationTitle("Relatório")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            exemplosButton
                        }
                    }
            } else {
                List {
                    Section {
                        MetricaRow(titulo: "Últimos 7 dias", valor: ultimos7dias.brl,
                                   icone: "clock", cor: .blue)
                        let mediaMensal = porMes.map { $0.listas.reduce(0) { $0 + $1.total } }.reduce(0, +) / Double(max(porMes.count, 1))
                        MetricaRow(titulo: "Média mensal", valor: mediaMensal.brl,
                                   icone: "calendar", cor: .orange)
                        let mediaCompra = listas.reduce(0) { $0 + $1.total } / Double(listas.count)
                        MetricaRow(titulo: "Média por compra", valor: mediaCompra.brl,
                                   icone: "cart", cor: AppTheme.accent)
                    } header: { RockSectionHeader(title: "Visão geral") }

                    if !gastosPorMercado.isEmpty {
                        Section {
                            ForEach(gastosPorMercado, id: \.mercado) { entry in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.green)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.mercado).font(.body.weight(.semibold))
                                        Text("\(entry.visitas) \(entry.visitas == 1 ? "visita" : "visitas")")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(entry.total.brl)
                                            .font(.body.weight(.heavy).monospacedDigit())
                                            .foregroundStyle(AppTheme.accent)
                                        Text("média \((entry.total / Double(entry.visitas)).brl)")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: { RockSectionHeader(title: "Gasto por mercado") }
                    }

                    if !comparacaoCesta.isEmpty {
                        Section {
                            let minCesta = comparacaoCesta.first?.totalCesta ?? 0
                            ForEach(comparacaoCesta, id: \.mercado) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 5) {
                                            if entry.totalCesta == minCesta {
                                                Image(systemName: "crown.fill")
                                                    .font(.caption2).foregroundStyle(.yellow)
                                            }
                                            Text(entry.mercado).font(.subheadline.weight(.semibold))
                                        }
                                        if entry.totalCesta == minCesta {
                                            Text("Mais barato").font(.caption2.weight(.bold)).foregroundStyle(.green)
                                        }
                                    }
                                    Spacer()
                                    Text(entry.totalCesta.brl)
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(entry.totalCesta == minCesta ? .green : .primary)
                                }
                                .padding(.vertical, 2)
                            }
                        } header: { RockSectionHeader(title: "Comparação de cesta") }
                        // Note: "cesta" = soma dos preços de produtos comuns em ≥2 mercados
                    }

                    ForEach(porMes, id: \.mes) { grupo in
                        Section {
                            ForEach(grupo.listas) { lista in
                                ListaFinalizadaRow(lista: lista)
                            }
                            HStack {
                                Text("Total do mês").font(.subheadline.weight(.heavy))
                                Spacer()
                                Text(grupo.listas.reduce(0) { $0 + $1.total }.brl)
                                    .font(.subheadline.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .padding(.vertical, 2)
                        } header: { RockSectionHeader(title: grupo.mes) }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Relatório")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        exemplosButton
                    }
                }
            }
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: $showExemplos) {
            ExemplosSheet()
        }
    }

    private var exemplosButton: some View {
        Button("Exemplos") { showExemplos = true }
            .foregroundStyle(AppTheme.accent)
            .fontWeight(.semibold)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent.opacity(0.4))
                .rockGlow(radius: 12)
            Text("Sem compras finalizadas")
                .font(.title2.weight(.heavy))
            Text("Finalize uma compra para ver o relatório")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ExemplosSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct ExemploLista {
        let nome: String
        let data: String
        let itens: Int
        let total: Double
    }

    private let meses: [(nome: String, listas: [ExemploLista], cor: Color)] = [
        (nome: "Maio 2025", listas: [
            ExemploLista(nome: "Semana 1", data: "05/05 · 09:30", itens: 14, total: 187.40),
            ExemploLista(nome: "Churrasco", data: "17/05 · 11:00", itens: 8, total: 243.90),
            ExemploLista(nome: "Semana 4", data: "26/05 · 08:45", itens: 11, total: 162.15),
        ], cor: AppTheme.accent),
        (nome: "Abril 2025", listas: [
            ExemploLista(nome: "Semana 1", data: "07/04 · 10:15", itens: 16, total: 201.30),
            ExemploLista(nome: "Semana 3", data: "21/04 · 09:00", itens: 9, total: 134.70),
        ], cor: .blue),
        (nome: "Março 2025", listas: [
            ExemploLista(nome: "Semana 2", data: "11/03 · 08:30", itens: 18, total: 312.00),
            ExemploLista(nome: "Aniversário", data: "22/03 · 16:00", itens: 22, total: 489.50),
            ExemploLista(nome: "Semana 4", data: "28/03 · 09:20", itens: 13, total: 178.90),
        ], cor: .orange),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Como fica o seu relatório")
                            .font(.title2.weight(.bold))
                        Text("Veja como ficará após finalizar algumas compras")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)

                    MetricaRow(titulo: "Últimos 7 dias", valor: "R$ 162,15", icone: "clock", cor: .blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    MetricaRow(titulo: "Média mensal", valor: "R$ 655,32", icone: "calendar", cor: .orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    MetricaRow(titulo: "Média por compra", valor: "R$ 238,66", icone: "cart", cor: AppTheme.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    ForEach(meses, id: \.nome) { mes in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(mes.nome)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(mes.listas.indices, id: \.self) { i in
                                    let lista = mes.listas[i]
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(lista.nome).font(.subheadline.weight(.semibold))
                                            Text("\(lista.data) · \(lista.itens) itens")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(lista.total.brl)
                                            .font(.callout.weight(.bold).monospacedDigit())
                                            .foregroundStyle(mes.cor)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    if i < mes.listas.count - 1 { Divider().padding(.leading, 20) }
                                }
                                Divider()
                                HStack {
                                    Text("Total do mês").font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(mes.listas.reduce(0) { $0 + $1.total }.brl)
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(mes.cor)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
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
                    .overlay(Circle().strokeBorder(cor.opacity(0.25), lineWidth: 0.75))
                Image(systemName: icone)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(cor)
            }
            Text(titulo)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
            Text(valor)
                .font(.body.weight(.heavy).monospacedDigit())
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
                Text(lista.nome).font(.subheadline.weight(.semibold))
                Text("\(dataFormatada) · \(lista.itens.count) \(lista.itens.count == 1 ? "item" : "itens")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(lista.total.brl)
                .font(.body.weight(.heavy).monospacedDigit())
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.vertical, 2)
    }
}
