import SwiftUI
import SwiftData

struct ReportView: View {
    @Query(filter: #Predicate<ShoppingList> { $0.finalized },
           sort: \ShoppingList.finalizedAt, order: .reverse)
    private var lists: [ShoppingList]
    @Query private var marketPrices: [MarketPrice]

    @State private var showExamples = false

    // Markets with finalized lists: name → (total spent, visits)
    private var spendingByMarket: [(market: String, total: Double, visits: Int)] {
        var map: [String: (total: Double, visits: Int)] = [:]
        for list in lists {
            guard let name = list.marketName else { continue }
            let current = map[name] ?? (0, 0)
            map[name] = (current.total + list.total, current.visits + 1)
        }
        return map
            .map { (market: $0.key, total: $0.value.total, visits: $0.value.visits) }
            .sorted { $0.total > $1.total }
    }

    // Products common in ≥2 markets + basket cost per market
    private var basketComparison: [(market: String, basketTotal: Double)] {
        var map: [String: [String: Double]] = [:]
        for pm in marketPrices {
            map[pm.productName, default: [:]][pm.marketName] = pm.price
        }
        let common = map.filter { $0.value.count >= 2 }
        guard !common.isEmpty else { return [] }
        var totalPerMarket: [String: Double] = [:]
        for (_, markets) in common {
            for (market, price) in markets {
                totalPerMarket[market, default: 0] += price
            }
        }
        return totalPerMarket
            .map { (market: $0.key, basketTotal: $0.value) }
            .sorted { $0.basketTotal < $1.basketTotal }
    }

    private var last7Days: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return lists
            .filter { ($0.finalizedAt ?? .distantPast) >= cutoff }
            .reduce(0) { $0 + $1.total }
    }

    private var byMonth: [(month: String, lists: [ShoppingList])] {
        var map: [String: [ShoppingList]] = [:]
        for list in lists { map[list.monthYear, default: []].append(list) }
        let order = lists.map { $0.monthYear }.reduce(into: [String]()) {
            if !$0.contains($1) { $0.append($1) }
        }
        return order.map { (month: $0, lists: map[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            if lists.isEmpty {
                emptyState
                    .navigationTitle("Report")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            examplesButton
                        }
                    }
            } else {
                List {
                    Section {
                        MetricRow(title: "Last 7 days", value: last7Days.brl,
                                  icon: "clock", color: .blue)
                        let monthlyAvg = byMonth.map { $0.lists.reduce(0) { $0 + $1.total } }.reduce(0, +) / Double(max(byMonth.count, 1))
                        MetricRow(title: "Monthly average", value: monthlyAvg.brl,
                                  icon: "calendar", color: .orange)
                        let avgPerTrip = lists.reduce(0) { $0 + $1.total } / Double(lists.count)
                        MetricRow(title: "Average per trip", value: avgPerTrip.brl,
                                  icon: "cart", color: AppTheme.accent)
                    } header: { RockSectionHeader(title: "Overview") }

                    if !spendingByMarket.isEmpty {
                        Section {
                            ForEach(spendingByMarket, id: \.market) { entry in
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
                                        Text(entry.market).font(.body.weight(.semibold))
                                        Text("\(entry.visits) \(entry.visits == 1 ? "visit" : "visits")")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(entry.total.brl)
                                            .font(.body.weight(.heavy).monospacedDigit())
                                            .foregroundStyle(AppTheme.accent)
                                        Text("average \((entry.total / Double(entry.visits)).brl)")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: { RockSectionHeader(title: "Spent by market") }
                    }

                    if !basketComparison.isEmpty {
                        Section {
                            let minBasket = basketComparison.first?.basketTotal ?? 0
                            ForEach(basketComparison, id: \.market) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 5) {
                                            if entry.basketTotal == minBasket {
                                                Image(systemName: "crown.fill")
                                                    .font(.caption2).foregroundStyle(.yellow)
                                            }
                                            Text(entry.market).font(.subheadline.weight(.semibold))
                                        }
                                        if entry.basketTotal == minBasket {
                                            Text("Cheapest").font(.caption2.weight(.bold)).foregroundStyle(.green)
                                        }
                                    }
                                    Spacer()
                                    Text(entry.basketTotal.brl)
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(entry.basketTotal == minBasket ? .green : .primary)
                                }
                                .padding(.vertical, 2)
                            }
                        } header: { RockSectionHeader(title: "Basket comparison") }
                    }

                    ForEach(byMonth, id: \.month) { group in
                        Section {
                            ForEach(group.lists) { list in
                                FinalizedListRow(list: list)
                            }
                            HStack {
                                Text("Month total").font(.subheadline.weight(.heavy))
                                Spacer()
                                Text(group.lists.reduce(0) { $0 + $1.total }.brl)
                                    .font(.subheadline.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .padding(.vertical, 2)
                        } header: { RockSectionHeader(title: group.month) }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Report")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        examplesButton
                    }
                }
            }
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: $showExamples) {
            ExamplesSheet()
        }
    }

    private var examplesButton: some View {
        Button("Examples") { showExamples = true }
            .foregroundStyle(AppTheme.accent)
            .fontWeight(.semibold)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent.opacity(0.4))
                .rockGlow(radius: 12)
            Text("No finalized purchases")
                .font(.title2.weight(.heavy))
            Text("Finalize a purchase to see the report")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ExamplesSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct ExampleList {
        let name: String
        let date: String
        let items: Int
        let total: Double
    }

    private let months: [(name: String, lists: [ExampleList], color: Color)] = [
        (name: "Maio 2025", lists: [
            ExampleList(name: "Semana 1", date: "05/05 · 09:30", items: 14, total: 187.40),
            ExampleList(name: "Churrasco", date: "17/05 · 11:00", items: 8, total: 243.90),
            ExampleList(name: "Semana 4", date: "26/05 · 08:45", items: 11, total: 162.15),
        ], color: AppTheme.accent),
        (name: "Abril 2025", lists: [
            ExampleList(name: "Semana 1", date: "07/04 · 10:15", items: 16, total: 201.30),
            ExampleList(name: "Semana 3", date: "21/04 · 09:00", items: 9, total: 134.70),
        ], color: .blue),
        (name: "Março 2025", lists: [
            ExampleList(name: "Semana 2", date: "11/03 · 08:30", items: 18, total: 312.00),
            ExampleList(name: "Aniversário", date: "22/03 · 16:00", items: 22, total: 489.50),
            ExampleList(name: "Semana 4", date: "28/03 · 09:20", items: 13, total: 178.90),
        ], color: .orange),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Your report preview")
                            .font(.title2.weight(.bold))
                        Text("See how it looks after finalizing a few purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)

                    MetricRow(title: "Last 7 days", value: "R$ 162,15", icon: "clock", color: .blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    MetricRow(title: "Monthly average", value: "R$ 655,32", icon: "calendar", color: .orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    MetricRow(title: "Average per trip", value: "R$ 238,66", icon: "cart", color: AppTheme.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    ForEach(months, id: \.name) { month in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(month.name)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(month.lists.indices, id: \.self) { i in
                                    let list = month.lists[i]
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(list.name).font(.subheadline.weight(.semibold))
                                            Text("\(list.date) · \(list.items) items")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(list.total.brl)
                                            .font(.callout.weight(.bold).monospacedDigit())
                                            .foregroundStyle(month.color)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    if i < month.lists.count - 1 { Divider().padding(.leading, 20) }
                                }
                                Divider()
                                HStack {
                                    Text("Month total").font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(month.lists.reduce(0) { $0 + $1.total }.brl)
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(month.color)
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
                    Button("Close") { dismiss() }
                        .tint(AppTheme.accent)
                }
            }
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(color.opacity(0.25), lineWidth: 0.75))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.body.weight(.heavy).monospacedDigit())
                .foregroundStyle(color)
        }
    }
}

private struct FinalizedListRow: View {
    let list: ShoppingList

    private var formattedDate: String {
        guard let date = list.finalizedAt else { return "" }
        let f = DateFormatter()
        f.dateFormat = "dd/MM · HH:mm"
        return f.string(from: date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(list.name).font(.subheadline.weight(.semibold))
                Text("\(formattedDate) · \(list.items.count) \(list.items.count == 1 ? "item" : "items")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(list.total.brl)
                .font(.body.weight(.heavy).monospacedDigit())
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.vertical, 2)
    }
}
