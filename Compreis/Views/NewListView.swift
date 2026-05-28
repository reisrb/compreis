import SwiftUI
import SwiftData
import MapKit

@MainActor
final class SearchCompleter: NSObject, ObservableObject, @preconcurrency MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func search(_ query: String) {
        guard !query.isEmpty else { completions = []; return }
        completer.queryFragment = query
    }

    func clear() { completions = [] }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
    }
}

struct NewListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<ShoppingList> { $0.isTemplate == true && $0.isPredefined == false })
    private var userTemplates: [ShoppingList]
    @Query(filter: #Predicate<ShoppingList> { $0.isTemplate == true && $0.isPredefined == true })
    private var predefinedTemplates: [ShoppingList]

    var title: String = "New list"
    var isTemplate: Bool = false
    var onCreate: (String, Date?, String?, Double?, Double?, ListTemplate, ShoppingList?) -> Void

    @State private var name: String = ""
    @State private var useDate = false
    @State private var marketDate = Date()
    @State private var useLocation = false
    @State private var locationQuery = ""
    @State private var locationName: String?
    @State private var locationLat: Double?
    @State private var locationLon: Double?
    @StateObject private var completer = SearchCompleter()
    @State private var showMapPicker = false
    @State private var selectedTemplate: ListTemplate = .empty
    @State private var selectedUserTemplate: ShoppingList?
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Static template model
                Section {
                    HStack(spacing: 8) {
                        ForEach(ListTemplate.allCases, id: \.self) { template in
                            let selected = selectedTemplate == template && selectedUserTemplate == nil
                            Button {
                                selectedTemplate = template
                                selectedUserTemplate = nil
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: template.icon)
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(selected ? AppTheme.accent : .secondary)
                                    Text(template.rawValue)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(selected ? AppTheme.accent : .primary)
                                    Text(template.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selected
                                    ? AppTheme.accentSubtle
                                    : Color.secondary.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(selected ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    let previewAvailable = (selectedTemplate != .empty && selectedUserTemplate == nil)
                        || selectedUserTemplate != nil
                    if previewAvailable {
                        Button { showPreview = true } label: {
                            HStack {
                                Image(systemName: "eye")
                                let count = selectedUserTemplate.map { $0.items.count }
                                    ?? selectedTemplate.products.count
                                Text("See \(count) included items")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                } header: { Text("Model") }

                // MARK: User templates
                if !userTemplates.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(userTemplates) { t in
                                    let selected = selectedUserTemplate?.id == t.id
                                    Button {
                                        selectedUserTemplate = t
                                        selectedTemplate = .empty
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: "star.fill")
                                                .font(.title2.weight(.semibold))
                                                .foregroundStyle(selected ? AppTheme.accent : .secondary)
                                            Text(t.name)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(selected ? AppTheme.accent : .primary)
                                                .lineLimit(1)
                                            Text("\(t.items.count) \(t.items.count == 1 ? "item" : "items")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(width: 110)
                                        .padding(.vertical, 12)
                                        .background(selected
                                            ? AppTheme.accentSubtle
                                            : Color.secondary.opacity(0.07),
                                            in: RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(selected ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } header: { Text("Your templates") }
                }

                // MARK: Name
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Ex: Week, BBQ…", text: $name)
                    }
                } header: { Text(isTemplate ? "Template name" : "List name") }

                // MARK: Date
                if !isTemplate {
                Section {
                    Toggle("Set date", isOn: $useDate)
                        .tint(AppTheme.accent)
                    if useDate {
                        DatePicker("Date", selection: $marketDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.accent)
                    }
                } header: { Text("When going to the market") }
                }

                // MARK: Location
                if !isTemplate {
                Section {
                    Toggle("Set location", isOn: $useLocation)
                        .tint(AppTheme.accent)
                    if useLocation {
                        if let pinned = locationName, let lat = locationLat, let lon = locationLon {
                            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            Map(initialPosition: .region(MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                            ))) {
                                Marker(pinned, coordinate: coord).tint(AppTheme.accent)
                            }
                            .frame(height: 160)
                            .listRowInsets(EdgeInsets())
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            HStack {
                                Image(systemName: "mappin.circle.fill").foregroundStyle(AppTheme.accent)
                                Text(pinned).font(.subheadline)
                                Spacer()
                                Button {
                                    locationName = nil; locationLat = nil; locationLon = nil
                                    locationQuery = ""; completer.clear()
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Button { showMapPicker = true } label: {
                                Label("Choose on map", systemImage: "map")
                                    .font(.subheadline).foregroundStyle(AppTheme.accent)
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary).frame(width: 20)
                                TextField("Search supermarket…", text: $locationQuery)
                                    .onChange(of: locationQuery) { _, q in completer.search(q) }
                            }
                            ForEach(completer.completions, id: \.self) { completion in
                                Button { Task { await resolve(completion) } } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.title).font(.subheadline).foregroundStyle(.primary)
                                        if !completion.subtitle.isEmpty {
                                            Text(completion.subtitle).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: { Text("Market location") }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPreview) {
                if let t = selectedUserTemplate {
                    TemplatePreviewSheet(name: t.name, seeds: t.items.map {
                        ProductSeed(name: $0.name, category: $0.category, unit: $0.unit)
                    })
                } else if let stored = predefinedTemplates.first(where: { $0.name == selectedTemplate.rawValue }) {
                    TemplatePreviewSheet(name: stored.name, seeds: stored.items.map {
                        ProductSeed(name: $0.name, category: $0.category, unit: $0.unit)
                    })
                } else {
                    TemplatePreviewSheet(name: selectedTemplate.rawValue,
                                        seeds: selectedTemplate.products)
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapPickerView { n, lat, lon in
                    locationName = n; locationLat = lat; locationLon = lon
                    locationQuery = n; completer.clear(); useLocation = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(
                            name.isEmpty ? "List" : name,
                            useDate ? marketDate : nil,
                            useLocation ? locationName : nil,
                            useLocation ? locationLat : nil,
                            useLocation ? locationLon : nil,
                            selectedTemplate,
                            selectedUserTemplate
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                }
            }
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        let req = MKLocalSearch.Request(completion: completion)
        guard let response = try? await MKLocalSearch(request: req).start(),
              let item = response.mapItems.first else { return }
        locationName = item.name ?? completion.title
        locationLat = item.placemark.coordinate.latitude
        locationLon = item.placemark.coordinate.longitude
        locationQuery = item.name ?? completion.title
        completer.clear()
    }
}

// MARK: - Template preview sheet

private struct TemplatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let name: String
    let seeds: [ProductSeed]

    private var byCategory: [(ItemCategory, [ProductSeed])] {
        let grouped = Dictionary(grouping: seeds, by: { $0.category })
        return ItemCategory.allCases.compactMap { cat in
            guard let group = grouped[cat], !group.isEmpty else { return nil }
            return (cat, group.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(byCategory, id: \.0) { cat, products in
                    Section {
                        ForEach(products, id: \.name) { p in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(cat.color)
                                    .frame(width: 20)
                                Text(p.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(p.unit.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Label(cat.rawValue, systemImage: cat.icon)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(cat.color)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(name)
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
