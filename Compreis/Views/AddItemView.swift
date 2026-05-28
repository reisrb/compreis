import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var item: Item?
    var listUF: String? = nil
    var existingNames: [String] = []
    var inProgress: Bool = false
    var onSave: (String, Double, ItemUnit, Double, ItemCategory, Bool) -> Void

    @State private var name: String = ""
    @State private var priceText: String = "0,00"
    @State private var priceCents: Int = 0
    @State private var unit: ItemUnit = .each
    @State private var category: ItemCategory = .other
    @State private var quantityInt: Int = 1
    @State private var weightDisplay: String = "0,000"
    @State private var weightGrams: Int = 0
    @State private var suggestions: [ProductHistory] = []
    @State private var mlResults: [MLProduct] = []
    @State private var mlSearching = false
    @State private var mlTask: Task<Void, Never>?
    @State private var conabInfo: (price: Double, uf: String)?
    @State private var conabTask: Task<Void, Never>?
    @State private var deletingProduct: ProductHistory? = nil
    @State private var itemsInUse: [Item] = []
    @State private var showDeleteAlert = false
    @State private var showRenameSheet = false
    @State private var renameNewName = ""
    @State private var showDuplicateAlert = false
    @State private var showDestinationDialog = false

    private var weightValue: Double { Double(weightGrams) / 1000.0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Product name", text: $name)
                            .onChange(of: name) { _, newVal in
                                loadSuggestions(newVal)
                                scheduleMLSearch(newVal)
                                scheduleCONABSearch(newVal)
                            }
                    }
                    if !suggestions.isEmpty {
                        ForEach(suggestions) { s in
                            Button { applySuggestion(s) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.name).foregroundStyle(.primary)
                                        Text("\(s.price.brl) / \(s.unit.rawValue)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption).foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet { attemptDelete(suggestions[idx]) }
                        }
                    }
                    if let info = conabInfo {
                        Button { applyCONAB(info.price) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CONAB Ref. · \(info.uf) (wholesale)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("\(info.price.brl) / kg")
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption).foregroundStyle(Color.green.opacity(0.8))
                            }
                        }
                    }
                    if mlSearching {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text("Searching products…")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if !mlResults.isEmpty {
                        ForEach(mlResults) { p in
                            Button { applyML(p) } label: {
                                HStack(spacing: 10) {
                                    AsyncImage(url: p.thumbnail) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.secondary.opacity(0.15)
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.title)
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
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                            .frame(width: 20)
                        Picker("Category", selection: $category) {
                            ForEach(ItemCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
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
                        TextField("0,00", text: $priceText)
                            .keyboardType(.numberPad)
                            .monospacedDigit()
                            .onChange(of: priceText) { _, newVal in
                                let digits = String(newVal.filter { $0.isNumber }.prefix(8))
                                let n = Int(digits) ?? 0
                                priceCents = n
                                let formatted = String(format: "%d,%02d", n / 100, n % 100)
                                if priceText != formatted { priceText = formatted }
                            }
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(AppTheme.accent).frame(width: 20)
                        Picker("Unit", selection: $unit) {
                            ForEach(ItemUnit.allCases, id: \.self) { u in
                                Text(u.rawValue == "un" ? "Per unit" : "Per kg").tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.accent)
                    }
                } header: { RockSectionHeader(title: "Price") }

                Section {
                    if unit == .kg {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(AppTheme.accent).frame(width: 20)
                            TextField("0,000", text: $weightDisplay)
                                .keyboardType(.numberPad)
                                .monospacedDigit()
                                .onChange(of: weightDisplay) { _, newVal in
                                    let digits = String(newVal.filter { $0.isNumber }.prefix(7))
                                    let n = Int(digits) ?? 0
                                    weightGrams = n
                                    let formatted = String(format: "%d,%03d", n / 1000, n % 1000)
                                    if weightDisplay != formatted { weightDisplay = formatted }
                                }
                            Text("kg")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    } else {
                        HStack {
                            Button {
                                if quantityInt > 1 { quantityInt -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(quantityInt > 1 ? Color.green : Color.gray)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("\(quantityInt)")
                                .font(.title2.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 40, alignment: .center)
                            Spacer()
                            Button {
                                quantityInt += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundStyle(Color.green)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                } header: { Text(unit == .kg ? "Weight — \(weightGrams)g" : "Quantity") }

                if isValid {
                    Section {
                        HStack {
                            Text("Item total").foregroundStyle(.secondary)
                            Spacer()
                            let price = Double(priceCents) / 100.0
                            let qty = unit == .kg ? weightValue : Double(quantityInt)
                            Text((price * qty).brl)
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
            .confirmationDialog("Where to add?", isPresented: $showDestinationDialog) {
                Button("Cart (already picked)") { confirmSave(picked: true) }
                Button("List") { confirmSave(picked: false) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Add to cart or to list?") }
            .alert("Product already in list", isPresented: $showDuplicateAlert) {
                Button("Add anyway") { confirmSave(picked: false) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\"\(name.trimmingCharacters(in: .whitespaces))\" is already in this list.")
            }
            .alert("Product in use", isPresented: $showDeleteAlert, presenting: deletingProduct) { hist in
                Button("Delete and remove from lists", role: .destructive) {
                    for i in itemsInUse { context.delete(i) }
                    context.delete(hist)
                    suggestions.removeAll { $0.name == hist.name }
                    deletingProduct = nil; itemsInUse = []
                }
                Button("Rename items") {
                    renameNewName = hist.name
                    showRenameSheet = true
                }
                Button("Cancel", role: .cancel) {
                    deletingProduct = nil; itemsInUse = []
                }
            } message: { hist in
                let n = itemsInUse.count
                Text("\"\(hist.name)\" is in \(n) \(n == 1 ? "item" : "items") in active lists. What do you want to do?")
            }
            .sheet(isPresented: $showRenameSheet) {
                RenameProductSheet(
                    currentName: deletingProduct?.name ?? "",
                    onConfirm: { newName in
                        if let hist = deletingProduct {
                            let oldName = hist.name
                            for i in itemsInUse { i.name = newName }
                            let descH = FetchDescriptor<ProductHistory>(predicate: #Predicate { $0.name == newName })
                            let newExists = ((try? context.fetch(descH))?.first) != nil
                            if !newExists, let first = itemsInUse.first {
                                context.insert(ProductHistory(
                                    name: newName, price: first.price,
                                    unit: first.unit, category: first.category
                                ))
                            }
                            context.delete(hist)
                            if name.localizedCaseInsensitiveCompare(oldName) == .orderedSame {
                                name = newName
                            }
                            suggestions.removeAll { $0.name == oldName }
                            loadSuggestions(name)
                            deletingProduct = nil; itemsInUse = []
                        }
                    },
                    onCancel: {
                        deletingProduct = nil; itemsInUse = []
                    }
                )
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(priceText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func populate() {
        guard let item else { return }
        name = item.name
        priceCents = Int((item.price * 100).rounded())
        priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
        unit = item.unit
        category = item.category
        if item.unit == .each {
            quantityInt = Int(item.quantity)
        } else {
            weightGrams = Int((item.quantity * 1000).rounded())
            weightDisplay = String(format: "%d,%03d", weightGrams / 1000, weightGrams % 1000)
        }
    }

    private func loadSuggestions(_ text: String) {
        guard text.count >= 2 else { suggestions = []; return }
        let fetch = FetchDescriptor<ProductHistory>()
        let all = (try? context.fetch(fetch)) ?? []
        suggestions = all
            .filter { $0.name.localizedCaseInsensitiveContains(text) }
            .sorted { $0.name < $1.name }
            .prefix(4)
            .map { $0 }
    }

    private func applySuggestion(_ s: ProductHistory) {
        name = s.name
        priceCents = Int((s.price * 100).rounded())
        priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
        unit = s.unit
        category = s.category
        quantityInt = 1
        weightGrams = 0
        weightDisplay = "0,000"
        suggestions = []
    }

    private func scheduleMLSearch(_ text: String) {
        mlTask?.cancel()
        mlResults = []
        guard text.count >= 3 else { mlSearching = false; return }
        mlTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await MainActor.run { mlSearching = true }
            let results = await MLService.search(text)
            await MainActor.run {
                mlResults = results
                mlSearching = false
            }
        }
    }

    private func applyML(_ p: MLProduct) {
        name = p.title
        let fetch = FetchDescriptor<ProductHistory>()
        let hist = (try? context.fetch(fetch)) ?? []
        if let match = hist.first(where: { $0.name.localizedCaseInsensitiveContains(p.title) ||
                                           p.title.localizedCaseInsensitiveContains($0.name) }),
           match.price > 0 {
            priceCents = Int((match.price * 100).rounded())
            priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
            unit = match.unit
            category = match.category
        } else {
            priceCents = 0
            priceText = "0,00"
        }
        quantityInt = 1
        mlResults = []
        suggestions = []
    }

    private func scheduleCONABSearch(_ text: String) {
        conabTask?.cancel()
        conabInfo = nil
        guard let uf = listUF, text.count >= 3 else { return }
        conabTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            let price = await CONABService.shared.price(productName: text, state: uf)
            await MainActor.run {
                if let p = price { conabInfo = (p, uf) }
            }
        }
    }

    private func applyCONAB(_ price: Double) {
        priceCents = Int((price * 100).rounded())
        priceText = String(format: "%d,%02d", priceCents / 100, priceCents % 100)
        unit = .kg
        conabInfo = nil
    }

    private func attemptDelete(_ history: ProductHistory) {
        let histName = history.name
        let desc = FetchDescriptor<Item>(predicate: #Predicate { $0.name == histName })
        let used = (try? context.fetch(desc)) ?? []
        deletingProduct = history
        itemsInUse = used
        if used.isEmpty {
            context.delete(history)
            suggestions.removeAll { $0.name == histName }
            deletingProduct = nil
        } else {
            showDeleteAlert = true
        }
    }

    private func save() {
        let finalName = name.trimmingCharacters(in: .whitespaces)
        let alreadyExists = item == nil && existingNames.contains { $0.localizedCaseInsensitiveCompare(finalName) == .orderedSame }
        if alreadyExists {
            showDuplicateAlert = true
            return
        }
        if inProgress && item == nil {
            showDestinationDialog = true
            return
        }
        confirmSave(picked: item?.picked ?? false)
    }

    private func confirmSave(picked: Bool) {
        let price = Double(priceCents) / 100.0
        let quantity = unit == .kg ? weightValue : Double(quantityInt)
        onSave(name.trimmingCharacters(in: .whitespaces), price, unit, quantity, category, picked)
        dismiss()
    }
}

// MARK: - Rename sheet

private struct RenameProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let currentName: String
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    @State private var newName: String = ""
    @State private var history: [ProductHistory] = []

    private var suggestions: [ProductHistory] {
        history.filter { $0.name != currentName && (newName.isEmpty || $0.name.localizedCaseInsensitiveContains(newName)) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("New name", text: $newName)
                        .autocorrectionDisabled()
                } header: { Text("Rename \"\(currentName)\" to") }

                if !suggestions.isEmpty {
                    Section {
                        ForEach(suggestions) { s in
                            Button { newName = s.name } label: {
                                HStack {
                                    Text(s.name).foregroundStyle(.primary)
                                    Spacer()
                                    if newName == s.name {
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
                    Button("Cancel") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onConfirm(newName.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                newName = ""
                let fetch = FetchDescriptor<ProductHistory>(sortBy: [SortDescriptor(\.name)])
                history = (try? context.fetch(fetch)) ?? []
            }
        }
    }
}
