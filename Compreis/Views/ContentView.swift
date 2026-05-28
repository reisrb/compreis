import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Bindable var list: ShoppingList
    @Query private var allMarketPrices: [MarketPrice]

    @State private var showAdd = false
    @State private var editingItem: Item?
    @State private var listUF: String?
    @State private var showFinalize = false
    @State private var showDetails = false
    @State private var expandedCategories: Set<ItemCategory> = []
    @State private var pickItem: Item? = nil
    @State private var moveItem: Item? = nil
    @State private var cheapestMarketItem: Item? = nil
    @State private var cheapestMarketDest: String? = nil

    private struct CategoryGroup {
        let category: ItemCategory
        let pending: [Item]
        let picked: [Item]
    }

    private var groups: [CategoryGroup] {
        let byCat = Dictionary(grouping: list.items, by: { $0.category })
        return ItemCategory.allCases.compactMap { cat in
            let all = byCat[cat] ?? []
            guard !all.isEmpty else { return nil }
            return CategoryGroup(
                category: cat,
                pending: all.filter { !$0.picked }.sorted { $0.name < $1.name },
                picked:  all.filter {  $0.picked }.sorted { $0.name < $1.name }
            )
        }
    }

    private var totalItems: Int { list.items.count }

    var body: some View {
        Group {
            if list.items.isEmpty {
                VStack(spacing: 0) {
                    if !list.finalized && !list.isTemplate {
                        HStack(spacing: 10) {
                            Image(systemName: list.inProgress ? "cart.fill.badge.checkmark" : "cart.badge.plus")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(list.inProgress ? .orange : .secondary)
                            Text("Market mode")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(list.inProgress ? .orange : .secondary)
                            Spacer()
                            Button {
                                withAnimation(.spring(duration: 0.2)) { list.inProgress.toggle() }
                            } label: {
                                Text(list.inProgress ? "Disable" : "Enable")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(list.inProgress ? Color.orange : AppTheme.accent, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(list.inProgress ? Color.orange.opacity(0.10) : Color(.secondarySystemGroupedBackground))
                        Divider()
                    }
                    emptyState
                }
            } else {
                List {
                    if !list.finalized && !list.isTemplate {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: list.inProgress ? "cart.fill.badge.checkmark" : "cart.badge.plus")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(list.inProgress ? .orange : .secondary)
                                Text("Market mode")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(list.inProgress ? .orange : .secondary)
                                Spacer()
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { list.inProgress.toggle() }
                                } label: {
                                    Text(list.inProgress ? "Disable" : "Enable")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(list.inProgress ? Color.orange : AppTheme.accent, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                            .tutorialAnchor(.modoMercadoBanner)
                        }
                        .listRowBackground(list.inProgress ? Color.orange.opacity(0.10) : Color(.secondarySystemGroupedBackground))
                    }
                    ForEach(groups, id: \.category) { group in
                        Section {
                            // Pending items
                            ForEach(group.pending) { item in
                                ItemRow(item: item,
                                        onEdit: { editingItem = item },
                                        onPick: list.finalized ? nil : { pickItem = item },
                                        onMove: list.finalized ? nil : { moveItem = item },
                                        cheapestAlt: list.finalized ? nil : cheapestAlt(for: item),
                                        onMoveToCheapestMarket: list.finalized ? nil : { market in
                                            cheapestMarketItem = item
                                            cheapestMarketDest = market
                                        })
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(group.pending[i]) }
                                SyncService.shared.scheduleSync(context: context)
                            }

                            // Picked items mini-cart
                            if !group.picked.isEmpty {
                                let expanded = expandedCategories.contains(group.category)
                                Button {
                                    withAnimation(.spring(duration: 0.25)) {
                                        if expanded {
                                            expandedCategories.remove(group.category)
                                        } else {
                                            expandedCategories.insert(group.category)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "cart.badge.checkmark")
                                            .font(.caption.weight(.semibold))
                                        Text("In cart · \(group.picked.count)")
                                            .font(.caption.weight(.semibold))
                                        Spacer()
                                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)

                                if expanded {
                                    ForEach(group.picked) { item in
                                        ItemRow(item: item,
                                                onEdit: { editingItem = item },
                                                onMove: list.finalized ? nil : { moveItem = item })
                                    }
                                    .onDelete { offsets in
                                        for i in offsets { context.delete(group.picked[i]) }
                                        SyncService.shared.scheduleSync(context: context)
                                    }
                                }
                            }
                        } header: {
                            Label(group.category.rawValue, systemImage: group.category.icon)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(group.category.color)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if totalItems > 0 && !list.finalized { EditButton() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showDetails = true } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if totalItems > 0 {
                ListTotalFooter(list: list, onFinalize: { showFinalize = true })
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !list.finalized {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.black)
                        .frame(width: 48, height: 48)
                        .background(list.inProgress ? Color.orange : AppTheme.accent)
                        .clipShape(Circle())
                        .rockGlow(radius: 8)
                }
                .tutorialAnchor(.addItemFAB)
                .padding(.trailing, 20)
                .padding(.bottom, totalItems == 0 ? 20 : 110)
            }
        }
        .task {
            if let lat = list.latitude, let lon = list.longitude {
                listUF = await CONABService.uf(lat: lat, lon: lon)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddItemView(marketName: list.marketName, listUF: listUF, existingNames: list.items.map { $0.name }, inProgress: list.inProgress) { name, price, unit, quantity, category, picked in
                addItem(name: name, price: price, unit: unit, quantity: quantity, category: category, picked: picked)
            }
        }
        .sheet(item: $pickItem) { item in
            ConfirmPriceSheet(item: item, marketName: list.marketName) { newPrice, newQuantity in
                withAnimation(.spring(duration: 0.25)) {
                    item.picked = true
                    if newPrice != item.price {
                        item.price = newPrice
                        syncItemGlobally(originalName: item.name, newName: item.name, price: newPrice, excluding: item)
                        saveHistory(name: item.name, price: newPrice, unit: item.unit, category: item.category)
                    }
                    if newQuantity != item.quantity {
                        item.quantity = newQuantity
                    }
                    saveMarketPrice(name: item.name, price: newPrice, unit: item.unit)
                }
            }
        }
        .sheet(item: $cheapestMarketItem) { item in
            if let dest = cheapestMarketDest {
                CheapestMarketSheet(item: item, marketName: dest, currentList: list)
            }
        }
        .sheet(item: $moveItem) { item in
            MoveItemSheet(item: item, currentList: list) { dest in
                if let idx = list.items.firstIndex(where: { $0 === item }) {
                    list.items.remove(at: idx)
                }
                dest.items.append(item)
                SyncService.shared.scheduleSync(context: context)
            }
        }
        .sheet(item: $editingItem) { item in
            AddItemView(item: item, listUF: listUF) { name, price, unit, quantity, category, _ in
                let originalName = item.name
                item.name = name
                item.price = price
                item.unit = unit
                item.quantity = quantity
                item.category = category
                syncItemGlobally(originalName: originalName, newName: name, price: price, excluding: item)
                saveHistory(name: name, price: price, unit: unit, category: category)
                SyncService.shared.scheduleSync(context: context)
            }
        }
        .sheet(isPresented: $showDetails) {
            ListDetailView(list: list)
        }
        .sheet(isPresented: $showFinalize) {
            FinalizeView(list: list) { copy in
                list.finalizedAt = .now
                list.finalized = true
                if copy {
                    let newList = ShoppingList(name: list.name)
                    context.insert(newList)
                    for item in list.items {
                        newList.items.append(Item(name: item.name, price: item.price,
                                               unit: item.unit, quantity: item.quantity,
                                               category: item.category))
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

    private func addItem(name: String, price: Double, unit: ItemUnit, quantity: Double, category: ItemCategory, picked: Bool) {
        let item = Item(name: name, price: price, unit: unit, quantity: quantity, category: category)
        item.picked = picked
        list.items.append(item)
        syncItemGlobally(originalName: name, newName: name, price: price, excluding: item)
        saveHistory(name: name, price: price, unit: unit, category: category)
        SyncService.shared.scheduleSync(context: context)
    }

    private func syncItemGlobally(originalName: String, newName: String, price: Double, excluding: Item? = nil) {
        let desc = FetchDescriptor<Item>(predicate: #Predicate { $0.name == originalName })
        let all = (try? context.fetch(desc)) ?? []
        for other in all where other !== excluding {
            other.name = newName
            other.price = price
        }
    }

    private func cheapestAlt(for item: Item) -> (market: String, price: Double)? {
        guard let currentMarket = list.marketName else { return nil }
        let nameLower = item.name.lowercased()
        let others = allMarketPrices.filter {
            $0.productName.lowercased() == nameLower && $0.marketName != currentMarket
        }
        guard let cheapest = others.min(by: { $0.price < $1.price }),
              cheapest.price < item.price else { return nil }
        return (cheapest.marketName, cheapest.price)
    }

    private func saveMarketPrice(name: String, price: Double, unit: ItemUnit) {
        guard let market = list.marketName else { return }
        let fetch = FetchDescriptor<MarketPrice>()
        let all = (try? context.fetch(fetch)) ?? []
        let nameLower = name.lowercased()
        if let existing = all.first(where: {
            $0.productName.lowercased() == nameLower && $0.marketName == market
        }) {
            existing.price = price
            existing.updatedAt = .now
        } else {
            context.insert(MarketPrice(productName: name, marketName: market, price: price, unit: unit))
        }
    }

    private func saveHistory(name: String, price: Double, unit: ItemUnit, category: ItemCategory) {
        let nameLower = name.lowercased()
        let fetch = FetchDescriptor<ProductHistory>()
        let all = (try? context.fetch(fetch)) ?? []
        if let existing = all.first(where: { $0.name.lowercased() == nameLower }) {
            existing.price = price
            existing.unitRaw = unit.rawValue
            existing.categoryRaw = category.rawValue
        } else {
            context.insert(ProductHistory(name: name, price: price, unit: unit, category: category))
        }
    }
}

// MARK: - Footer

private struct ListTotalFooter: View {
    let list: ShoppingList
    var onFinalize: () -> Void

    @State private var showCart = false

    private var picked: [Item] { list.items.filter { $0.picked } }
    private var cartTotal: Double { picked.reduce(0) { $0 + $1.total } }
    private var totalItems: Int { list.items.count }

    var body: some View {
        HStack(spacing: 12) {
            if !list.finalized {
                Button("Finalize") { onFinalize() }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(list.inProgress ? Color.orange : AppTheme.accent)
                    .clipShape(Capsule())
                    .rockGlow(radius: 6)
            }

            if !picked.isEmpty {
                Button { showCart = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "cart.fill")
                            .font(.caption.weight(.semibold))
                        Text("\(picked.count)")
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(list.inProgress ? Color.orange.opacity(0.85) : AppTheme.accent.opacity(0.85))
                    .clipShape(Capsule())
                }
            }

            Spacer()
            if picked.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalItems) \(totalItems == 1 ? "item" : "items")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(list.total.brl)
                        .font(.title2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(AppTheme.spend)
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill").font(.caption2)
                        Text(cartTotal.brl)
                            .font(.title3.weight(.heavy).monospacedDigit())
                    }
                    .foregroundStyle(AppTheme.accent)
                    Text("of \(list.total.brl) estimated")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
        .sheet(isPresented: $showCart) {
            CartSheet(picked: picked, total: cartTotal)
        }
    }
}

// MARK: - Cart Sheet

private struct CartSheet: View {
    @Environment(\.dismiss) private var dismiss
    let picked: [Item]
    let total: Double

    private var byCategory: [(ItemCategory, [Item])] {
        let grouped = Dictionary(grouping: picked, by: { $0.category })
        return ItemCategory.allCases.compactMap { cat in
            guard let group = grouped[cat], !group.isEmpty else { return nil }
            return (cat, group.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(byCategory, id: \.0) { cat, items in
                    Section {
                        ForEach(items) { item in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(cat.color)
                                    .frame(width: 20)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.total.brl)
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(AppTheme.accent)
                                    Text("\(item.price.brl) × \(item.unit == .kg ? String(format: "%.3f kg", item.quantity) : String(format: "%.0f", item.quantity))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Label(cat.rawValue, systemImage: cat.icon)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(cat.color)
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

private struct ConfirmPriceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: Item
    var marketName: String?
    var onConfirm: (Double, Double) -> Void  // price, quantity

    @State private var priceCents: Int = 0
    @State private var priceText: String = "0,00"
    @State private var weightGrams: Int = 0
    @State private var weightDisplay: String = "0,000"
    @State private var quantityInt: Int = 1
    @State private var marketStoredPrice: Double? = nil

    private var weightValue: Double { Double(weightGrams) / 1000.0 }
    private var totalKg: Double { (Double(priceCents) / 100.0) * weightValue }
    private var totalUnit: Double { (Double(priceCents) / 100.0) * Double(quantityInt) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Text(item.name).font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(item.price.brl)
                            Text("/ \(item.unit.rawValue)")
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    if let market = marketName {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill").foregroundStyle(AppTheme.accent).font(.caption)
                            Text(market).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let pm = marketStoredPrice {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath").foregroundStyle(.orange).font(.caption)
                            Text("Last purchase here: \(pm.brl) / \(item.unit.rawValue)")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                } header: { Text("Product") }

                Section {
                    HStack(spacing: 12) {
                        Text("R$").foregroundStyle(.secondary)
                        TextField("0,00", text: $priceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: priceText) { _, new in
                                let digits = String(new.filter { $0.isNumber }.prefix(7))
                                priceCents = Int(digits) ?? 0
                                let formatted = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
                                if priceText != formatted { priceText = formatted }
                            }
                    }
                } header: { Text(item.unit == .kg ? "Price per kg" : "Confirm price") }

                if item.unit == .kg {
                    Section {
                        HStack(spacing: 12) {
                            TextField("0,000", text: $weightDisplay)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: weightDisplay) { _, new in
                                    let digits = String(new.filter { $0.isNumber }.prefix(6))
                                    weightGrams = Int(digits) ?? 0
                                    let formatted = String(format: "%d,%03d", weightGrams / 1000, weightGrams % 1000)
                                    if weightDisplay != formatted { weightDisplay = formatted }
                                }
                            Text("kg").foregroundStyle(.secondary)
                        }
                    } header: { Text("Weight") }

                    if weightValue > 0 {
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
                                if quantityInt > 1 { quantityInt -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(quantityInt > 1 ? AppTheme.accent : Color.gray)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("\(quantityInt)")
                                .font(.title2.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 40, alignment: .center)
                            Spacer()
                            Button { quantityInt += 1 } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundStyle(AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    } header: { Text("Quantity") }

                    if quantityInt > 1 {
                        Section {
                            HStack {
                                Text("Total")
                                Spacer()
                                Text(totalUnit.brl).font(.headline).foregroundStyle(AppTheme.spend)
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
                        let newPrice = Double(priceCents) / 100.0
                        let newQuantity = item.unit == .kg ? weightValue : Double(quantityInt)
                        onConfirm(newPrice, newQuantity)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                }
            }
            .onAppear {
                var basePrice = item.price
                if let market = marketName {
                    let fetch = FetchDescriptor<MarketPrice>()
                    let all = (try? context.fetch(fetch)) ?? []
                    let nameLower = item.name.lowercased()
                    let forProduct = all.filter { $0.productName.lowercased() == nameLower }
                    if let mp = forProduct.first(where: { $0.marketName == market }) {
                        marketStoredPrice = mp.price
                        basePrice = mp.price
                    } else if let highest = forProduct.max(by: { $0.price < $1.price }) {
                        basePrice = highest.price
                    }
                }
                priceCents = Int((basePrice * 100).rounded())
                priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
                if item.unit == .kg {
                    weightGrams = Int((item.quantity * 1000).rounded())
                    weightDisplay = String(format: "%d,%03d", weightGrams / 1000, weightGrams % 1000)
                } else {
                    quantityInt = max(1, Int(item.quantity))
                }
            }
        }
    }
}

// MARK: - Go to cheapest market

private struct CheapestMarketSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: Item
    let marketName: String
    let currentList: ShoppingList

    @Query(filter: #Predicate<ShoppingList> { $0.finalized == false && $0.isTemplate == false })
    private var active: [ShoppingList]

    private var targetList: ShoppingList? {
        active.first { $0.marketName == marketName && $0 !== currentList }
    }

    @State private var priceAtMarket: Double? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3).foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(marketName).font(.headline)
                            if let p = priceAtMarket {
                                HStack(spacing: 4) {
                                    Text(p.brl)
                                    Text("/ \(item.unit.rawValue)")
                                }
                                .font(.subheadline).foregroundStyle(.green)
                                let savings = (item.price - p) * item.quantity
                                if savings > 0 {
                                    Text("Savings: \(savings.brl)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Cheapest market for \"\(item.name)\"") }

                Section {
                    if let dest = targetList {
                        Button {
                            if let idx = currentList.items.firstIndex(where: { $0 === item }) {
                                currentList.items.remove(at: idx)
                            }
                            dest.items.append(item)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.doc.on.clipboard")
                                    .foregroundStyle(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Move to \"\(dest.name)\"")
                                        .font(.body.weight(.semibold)).foregroundStyle(.primary)
                                    Text("\(dest.items.count) \(dest.items.count == 1 ? "item" : "items") · \(marketName)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Button {
                            let newList = ShoppingList(name: marketName, marketName: marketName)
                            context.insert(newList)
                            if let idx = currentList.items.firstIndex(where: { $0 === item }) {
                                currentList.items.remove(at: idx)
                            }
                            newList.items.append(item)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create list at \"\(marketName)\"")
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
                let fetch = FetchDescriptor<MarketPrice>()
                let all = (try? context.fetch(fetch)) ?? []
                let nameLower = item.name.lowercased()
                priceAtMarket = all.first(where: {
                    $0.productName.lowercased() == nameLower && $0.marketName == marketName
                })?.price
            }
        }
    }
}

// MARK: - Move item between lists

private struct MoveItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: Item
    let currentList: ShoppingList
    var onMove: (ShoppingList) -> Void

    @Query(filter: #Predicate<ShoppingList> { $0.finalized == false && $0.isTemplate == false })
    private var active: [ShoppingList]

    private var destinations: [ShoppingList] { active.filter { $0.name != currentList.name } }

    var body: some View {
        NavigationStack {
            List {
                if destinations.isEmpty {
                    Text("No other active list")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(destinations) { list in
                        Button {
                            onMove(list)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "cart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(list.name).font(.body.weight(.semibold)).foregroundStyle(.primary)
                                    Text("\(list.items.count) \(list.items.count == 1 ? "item" : "items")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Move \"\(item.name)\" to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
