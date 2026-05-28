import SwiftUI
import SwiftData

struct CatalogueView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProductHistory.name) private var products: [ProductHistory]

    @State private var editing: ProductHistory? = nil
    @State private var showDetail: ProductHistory? = nil
    @State private var showNew = false
    @State private var search = ""
    @State private var expandedCategories: Set<ItemCategory> = Set(ItemCategory.allCases)

    private var filtered: [ProductHistory] {
        search.isEmpty ? products : products.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var byCategory: [(ItemCategory, [ProductHistory])] {
        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        return ItemCategory.allCases.compactMap { cat in
            guard let group = grouped[cat], !group.isEmpty else { return nil }
            return (cat, group.sorted { $0.name < $1.name })
        }
    }

    private var allExpanded: Bool { byCategory.allSatisfy { expandedCategories.contains($0.0) } }

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "Empty catalogue",
                        systemImage: "shippingbox",
                        description: Text("Tap + to add products")
                    )
                } else {
                    List {
                        ForEach(byCategory, id: \.0) { cat, group in
                            Section {
                                if expandedCategories.contains(cat) {
                                    ForEach(group) { p in
                                        Button { showDetail = p } label: {
                                            HStack(spacing: 12) {
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(p.name)
                                                        .font(.body.weight(.semibold))
                                                        .foregroundStyle(.primary)
                                                    HStack(spacing: 4) {
                                                        Text(p.price.brl)
                                                        Text("/ \(p.unit.rawValue)")
                                                    }
                                                    .font(.caption).foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                context.delete(p)
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                    }
                                }
                            } header: {
                                Button {
                                    withAnimation(.spring(duration: 0.25)) {
                                        if expandedCategories.contains(cat) {
                                            expandedCategories.remove(cat)
                                        } else {
                                            expandedCategories.insert(cat)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                        Text(cat.rawValue)
                                        Text("· \(group.count)")
                                            .foregroundStyle(cat.color.opacity(0.7))
                                        Spacer()
                                        Image(systemName: expandedCategories.contains(cat) ? "chevron.up" : "chevron.down")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(cat.color.opacity(0.7))
                                    }
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(cat.color)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $search, prompt: "Search product")
                }
            }
            .navigationTitle("Catalogue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            if allExpanded {
                                expandedCategories = []
                            } else {
                                expandedCategories = Set(ItemCategory.allCases)
                            }
                        }
                    } label: {
                        Text(allExpanded ? "Collapse" : "Expand")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button { showNew = true } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.black)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                        .rockGlow(radius: 8)
                }
                .tutorialAnchor(.catalogoFAB)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .sheet(item: $showDetail) { p in
                ProductDetailSheet(product: p, onEdit: { editing = p })
            }
            .sheet(item: $editing) { p in
                ProductEditSheet(product: p)
            }
            .sheet(isPresented: $showNew) {
                NewProductSheet()
            }
        }
    }
}

// MARK: - Product detail

private struct ProductDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let product: ProductHistory
    var onEdit: () -> Void

    @State private var marketPrices: [(market: String, price: Double)] = []

    private var lowestPrice: Double? { marketPrices.map { $0.price }.min() }
    private var cheapestMarket: String? {
        marketPrices.min(by: { $0.price < $1.price })?.market
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(product.category.color.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: product.category.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(product.category.color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.name).font(.headline)
                            HStack(spacing: 4) {
                                Text(product.price.brl)
                                Text("/ \(product.unit.rawValue)")
                            }
                            .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Product") }

                if marketPrices.isEmpty {
                    Section {
                        Label("No market registered yet", systemImage: "mappin.slash")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } header: { Text("Prices by market") }
                } else {
                    Section {
                        ForEach(marketPrices.sorted { $0.price < $1.price }, id: \.market) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(entry.market == cheapestMarket ? AppTheme.accent : .secondary)
                                        Text(entry.market).font(.subheadline.weight(.semibold))
                                    }
                                    if entry.market == cheapestMarket {
                                        Text("Cheapest")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                Spacer()
                                Text("\(entry.price.brl) / \(product.unit.rawValue)")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(entry.market == cheapestMarket ? AppTheme.accent : .primary)
                            }
                            .padding(.vertical, 2)
                        }
                    } header: { Text("Prices by market") }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onEdit() }
                    }
                    .tint(AppTheme.accent)
                }
            }
            .onAppear { loadPrices() }
        }
    }

    private func loadPrices() {
        let fetch = FetchDescriptor<MarketPrice>()
        let all = (try? context.fetch(fetch)) ?? []
        let nameLower = product.name.lowercased()
        let filtered = all.filter { $0.productName.lowercased() == nameLower }
        marketPrices = filtered.map { ($0.marketName, $0.price) }
    }
}

// MARK: - New product

struct NewProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var priceCents = 0
    @State private var priceText = "0,00"
    @State private var unit: ItemUnit = .each
    @State private var category: ItemCategory = .other
    @State private var suggestions: [ProductHistory] = []
    @State private var existingProduct: ProductHistory? = nil
    @State private var editingExisting: ProductHistory? = nil
    @State private var showDuplicateAlert = false

    private func loadSuggestions(_ text: String) {
        guard text.count >= 2 else { suggestions = []; existingProduct = nil; return }
        let fetch = FetchDescriptor<ProductHistory>()
        let all = (try? context.fetch(fetch)) ?? []
        suggestions = all
            .filter { $0.name.localizedCaseInsensitiveContains(text) }
            .sorted { $0.name < $1.name }
            .prefix(4)
            .map { $0 }
        existingProduct = all.first(where: { $0.name.localizedCaseInsensitiveCompare(text) == .orderedSame })
    }

    private func apply(_ p: ProductHistory) {
        name = p.name
        priceCents = Int((p.price * 100).rounded())
        priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
        unit = p.unit
        category = p.category
        suggestions = []
        existingProduct = p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag").foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("Product name", text: $name)
                            .autocorrectionDisabled()
                            .onChange(of: name) { _, newVal in loadSuggestions(newVal) }
                    }
                    if !suggestions.isEmpty {
                        ForEach(suggestions) { s in
                            Button { apply(s) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.name).foregroundStyle(.primary)
                                        HStack(spacing: 4) {
                                            Text(s.price.brl)
                                            Text("/ \(s.unit.rawValue)")
                                        }
                                        .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption).foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                    }
                    if existingProduct != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle").foregroundStyle(.orange)
                            Text("Product already in catalogue")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        .padding(.vertical, 2)
                    }
                } header: { Text("Name") }

                Section {
                    HStack(spacing: 12) {
                        Text("R$").foregroundStyle(.secondary)
                        TextField("0,00", text: $priceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: priceText) { _, newVal in
                                let digits = String(newVal.filter { $0.isNumber }.prefix(7))
                                priceCents = Int(digits) ?? 0
                                let f = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
                                if priceText != f { priceText = f }
                            }
                    }
                } header: { Text("Reference price") }

                Section {
                    Picker("Unit", selection: $unit) {
                        ForEach(ItemUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                } header: { Text("Unit") }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: $0.icon).tag($0)
                        }
                    }
                } header: { Text("Category") }
            }
            .navigationTitle("New product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalName = name.trimmingCharacters(in: .whitespaces)
                        let price = Double(priceCents) / 100.0
                        let fetch = FetchDescriptor<ProductHistory>()
                        let all = (try? context.fetch(fetch)) ?? []
                        if let existing = all.first(where: { $0.name.localizedCaseInsensitiveCompare(finalName) == .orderedSame }) {
                            editingExisting = existing
                            showDuplicateAlert = true
                        } else {
                            context.insert(ProductHistory(name: finalName, price: price, unit: unit, category: category))
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Product already registered", isPresented: $showDuplicateAlert) {
                Button("Edit existing") { }
                Button("Cancel", role: .cancel) { editingExisting = nil }
            } message: {
                Text("\"\(editingExisting?.name ?? "")\" already exists in the catalogue.")
            }
            .sheet(item: $editingExisting) { p in
                ProductEditSheet(product: p)
            }
        }
    }
}

// MARK: - Edit sheet

private struct ProductEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var product: ProductHistory

    @State private var name: String = ""
    @State private var priceCents: Int = 0
    @State private var priceText: String = "0,00"
    @State private var unit: ItemUnit = .each
    @State private var category: ItemCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag").foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("Name", text: $name).autocorrectionDisabled()
                    }
                } header: { Text("Name") }

                Section {
                    HStack(spacing: 12) {
                        Text("R$").foregroundStyle(.secondary)
                        TextField("0,00", text: $priceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: priceText) { _, newVal in
                                let digits = String(newVal.filter { $0.isNumber }.prefix(7))
                                priceCents = Int(digits) ?? 0
                                let formatted = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
                                if priceText != formatted { priceText = formatted }
                            }
                    }
                } header: { Text("Price") }

                Section {
                    Picker("Unit", selection: $unit) {
                        ForEach(ItemUnit.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                    }.pickerStyle(.segmented)
                } header: { Text("Unit") }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                } header: { Text("Category") }
            }
            .navigationTitle("Edit product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        product.name = name.trimmingCharacters(in: .whitespaces)
                        product.price = Double(priceCents) / 100.0
                        product.unit = unit
                        product.category = category
                        dismiss()
                    }
                    .fontWeight(.semibold).tint(AppTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = product.name
                priceCents = Int((product.price * 100).rounded())
                priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
                unit = product.unit
                category = product.category
            }
        }
    }
}
