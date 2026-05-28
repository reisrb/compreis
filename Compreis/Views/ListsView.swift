import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ShoppingList.createdAt, order: .reverse)
    private var lists: [ShoppingList]

    @State private var showNew = false
    @State private var showTemplates = false
    @State private var showingDetail: ShoppingList?

    private var active:     [ShoppingList] { lists.filter { !$0.finalized && !$0.isTemplate } }
    private var finalized:  [ShoppingList] { lists.filter {  $0.finalized && !$0.isTemplate } }
    private var activeTotal: Double { active.reduce(0) { $0 + $1.computedTotal } }

    var body: some View {
        NavigationStack {
            Group {
                if active.isEmpty && finalized.isEmpty {
                    emptyState
                } else {
                    List {
                        if !active.isEmpty {
                            Section {
                                ForEach(active) { list in
                                    NavigationLink(destination: ContentView(list: list)) {
                                        ListRow(list: list)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(list)
                                            SyncService.shared.scheduleSync(context: context)
                                        } label: { Label("Delete", systemImage: "trash") }
                                        .tint(.red)
                                        Button { showingDetail = list } label: {
                                            Label("Details", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: {
                                HStack {
                                    RockSectionHeader(title: "Open")
                                    Spacer()
                                    if activeTotal > 0 {
                                        Text(activeTotal.brl)
                                            .font(.caption.weight(.bold).monospacedDigit())
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                            }
                        }

                        if !finalized.isEmpty {
                            Section {
                                ForEach(finalized) { list in
                                    NavigationLink(destination: ContentView(list: list)) {
                                        ListRow(list: list)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(list)
                                            SyncService.shared.scheduleSync(context: context)
                                        } label: { Label("Delete", systemImage: "trash") }
                                        .tint(.red)
                                        Button { showingDetail = list } label: {
                                            Label("Details", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: { RockSectionHeader(title: "Finalized") }
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
                    Button { showNew = true } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(.black)
                            .frame(width: 58, height: 58)
                            .background(AppTheme.accent)
                            .clipShape(Circle())
                            .rockGlow(radius: 10)
                    }
                    .tutorialAnchor(.novaListaFAB)
                    .padding(.trailing, 24)
                    .padding(.vertical, 16)
                }
            }
            .sheet(isPresented: $showNew) {
                NewListView { name, date, marketName, lat, lon, template, userTemplate in
                    let nova = ShoppingList(name: name, marketDate: date,
                                           marketName: marketName,
                                           latitude: lat, longitude: lon)
                    context.insert(nova)
                    if let marketName {
                        let fetch = FetchDescriptor<Market>(predicate: #Predicate { $0.name == marketName })
                        if (try? context.fetch(fetch))?.isEmpty != false {
                            context.insert(Market(name: marketName, latitude: lat, longitude: lon))
                        }
                    }
                    if let t = userTemplate {
                        for item in t.items {
                            nova.items.append(Item(name: item.name, price: item.price,
                                                   unit: item.unit, quantity: item.quantity,
                                                   category: item.category))
                        }
                    } else if template != .empty {
                        ProductBase.createItems(for: nova, template: template, context: context)
                    }
                    SyncService.shared.scheduleSync(context: context)
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatesView()
            }
            .sheet(item: $showingDetail) { list in
                ListDetailView(list: list)
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
            Text("No lists")
                .font(.title2.weight(.heavy))
            Text("Tap + to create a list")
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
    @Query(filter: #Predicate<ShoppingList> { $0.isTemplate == true && $0.isPredefined == true },
           sort: \ShoppingList.createdAt, order: .forward)
    private var predefined: [ShoppingList]
    @Query(filter: #Predicate<ShoppingList> { $0.isTemplate == true && $0.isPredefined == false },
           sort: \ShoppingList.createdAt, order: .reverse)
    private var userTemplates: [ShoppingList]

    @State private var showNew = false
    @State private var showingDetail: ShoppingList?

    var body: some View {
        NavigationStack {
            List {
                if !predefined.isEmpty {
                    Section {
                        ForEach(predefined) { t in
                            NavigationLink(destination: ContentView(list: t)) {
                                ListRow(list: t, isTemplate: true)
                            }
                        }
                    } header: { RockSectionHeader(title: "Default") }
                }

                Section {
                    if userTemplates.isEmpty {
                        Button { showNew = true } label: {
                            Label("Create template", systemImage: "plus")
                                .foregroundStyle(AppTheme.accent)
                        }
                    } else {
                        ForEach(userTemplates) { t in
                            NavigationLink(destination: ContentView(list: t)) {
                                ListRow(list: t, isTemplate: true)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(t)
                                } label: { Label("Delete", systemImage: "trash") }
                                .tint(.red)
                                Button { showingDetail = t } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                } header: { RockSectionHeader(title: "My templates") }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNew) {
                NewListView(title: "New template", isTemplate: true) { name, date, marketName, lat, lon, template, userTemplate in
                    let novo = ShoppingList(name: name, marketDate: date,
                                           marketName: marketName,
                                           latitude: lat, longitude: lon)
                    novo.isTemplate = true
                    context.insert(novo)
                    if let t = userTemplate {
                        for item in t.items {
                            novo.items.append(Item(name: item.name, price: item.price,
                                                   unit: item.unit, quantity: item.quantity,
                                                   category: item.category))
                        }
                    } else if template != .empty {
                        ProductBase.createItems(for: novo, template: template, context: context)
                    }
                }
            }
            .sheet(item: $showingDetail) { t in
                ListDetailView(list: t)
            }
        }
        .tint(AppTheme.accent)
    }
}

// MARK: - Row

private struct ListRow: View {
    let list: ShoppingList
    var isTemplate: Bool = false

    private var formattedDate: String? {
        guard let date = list.marketDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "dd/MM · HH:mm"
        return f.string(from: date)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isTemplate
                          ? Color.orange.opacity(0.12)
                          : list.finalized
                              ? Color.secondary.opacity(0.12)
                              : list.inProgress
                                  ? Color.orange.opacity(0.12)
                                  : AppTheme.accentSubtle)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(
                        isTemplate ? Color.orange.opacity(0.4)
                            : list.finalized ? Color.clear
                            : list.inProgress ? Color.orange.opacity(0.4)
                            : AppTheme.accentBorder,
                        lineWidth: 0.75))
                Image(systemName: isTemplate ? "star.fill"
                      : list.finalized ? "checkmark.circle"
                      : list.inProgress ? "cart.fill.badge.checkmark"
                      : "cart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isTemplate ? Color.orange
                                     : list.finalized ? Color.gray
                                     : list.inProgress ? Color.orange
                                     : AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(list.name).font(.body.weight(.bold))
                    if list.marketName != nil {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(list.inProgress ? Color.orange.opacity(0.7) : AppTheme.accent.opacity(0.7))
                    }
                }
                HStack(spacing: 6) {
                    Text("\(list.items.count) \(list.items.count == 1 ? "item" : "items")")
                        .foregroundStyle(.secondary)
                    if let date = formattedDate {
                        Text("·").foregroundStyle(.secondary)
                        Text(date).foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if !list.items.isEmpty {
                Text(list.total.brl)
                    .font(.callout.weight(.heavy).monospacedDigit())
                    .foregroundStyle(isTemplate ? Color.orange
                                     : list.finalized ? Color.secondary : AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
