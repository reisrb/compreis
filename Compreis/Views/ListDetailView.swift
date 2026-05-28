import SwiftUI
import SwiftData
import MapKit

struct ListDetailView: View {
    let list: ShoppingList
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var templateCreated = false
    @State private var useDate = false
    @State private var marketDate = Date()
    @State private var useLocation = false
    @State private var locationQuery = ""
    @State private var locationName: String?
    @State private var locationLat: Double?
    @State private var locationLon: Double?
    @StateObject private var completer = SearchCompleter()
    @State private var showMapPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Name", text: $name)
                    }
                } header: { RockSectionHeader(title: "Name") }

                if !list.items.isEmpty {
                    Section {
                        LabeledContent("Items") {
                            Text("\(list.items.count) \(list.items.count == 1 ? "item" : "items")")
                        }
                        LabeledContent("Total") {
                            Text(list.total.brl)
                                .foregroundStyle(AppTheme.accent)
                                .fontWeight(.heavy)
                        }
                        LabeledContent("Status") {
                            Text(list.finalized ? "Finalized" : "Open")
                                .foregroundStyle(list.finalized ? .secondary : AppTheme.accent)
                        }
                    } header: { RockSectionHeader(title: "Summary") }
                }

                if !list.isTemplate {
                    Section {
                        if templateCreated {
                            Label("Template created successfully", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                        } else {
                            Button {
                                let copy = ShoppingList(
                                    name: list.name,
                                    marketDate: nil,
                                    marketName: list.marketName,
                                    latitude: list.latitude,
                                    longitude: list.longitude
                                )
                                copy.isTemplate = true
                                for item in list.items {
                                    copy.items.append(Item(
                                        name: item.name, price: item.price,
                                        unit: item.unit, quantity: item.quantity,
                                        category: item.category
                                    ))
                                }
                                context.insert(copy)
                                templateCreated = true
                            } label: {
                                Label("Use as template", systemImage: "doc.badge.plus")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    } header: { RockSectionHeader(title: "Template") }
                }

                Section {
                    Toggle("Set date", isOn: $useDate)
                        .tint(AppTheme.accent)
                    if useDate {
                        DatePicker("Date", selection: $marketDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.accent)
                    }
                } header: { RockSectionHeader(title: "Market date") }

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
                                Marker(pinned, coordinate: coord)
                                    .tint(AppTheme.accent)
                            }
                            .frame(height: 160)
                            .listRowInsets(EdgeInsets())
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                                Text(pinned).font(.subheadline)
                                Spacer()
                                Button {
                                    locationName = nil; locationLat = nil; locationLon = nil
                                    locationQuery = ""; completer.clear()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Button {
                                showMapPicker = true
                            } label: {
                                Label("Choose on map", systemImage: "map")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                TextField("Search supermarket…", text: $locationQuery)
                                    .onChange(of: locationQuery) { _, q in completer.search(q) }
                            }
                            ForEach(completer.completions, id: \.self) { completion in
                                Button {
                                    Task { await resolve(completion) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.title)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        if !completion.subtitle.isEmpty {
                                            Text(completion.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: { RockSectionHeader(title: "Market location") }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showMapPicker) {
                MapPickerView { n, lat, lon in
                    locationName = n; locationLat = lat; locationLon = lon
                    locationQuery = n; completer.clear()
                    useLocation = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.name = name.isEmpty ? list.name : name
                        list.marketDate = useDate ? marketDate : nil
                        list.marketName = useLocation ? locationName : nil
                        list.latitude = useLocation ? locationLat : nil
                        list.longitude = useLocation ? locationLon : nil
                        dismiss()
                    }
                    .fontWeight(.heavy)
                    .tint(AppTheme.accent)
                }
            }
        }
        .onAppear { loadState() }
    }

    private func loadState() {
        name = list.name
        if let date = list.marketDate {
            useDate = true
            marketDate = date
        }
        if let n = list.marketName {
            useLocation = true
            locationName = n
            locationLat = list.latitude
            locationLon = list.longitude
            locationQuery = n
        }
        let listName = list.name
        let desc = FetchDescriptor<ShoppingList>(
            predicate: #Predicate { $0.isTemplate == true && $0.isPredefined == false && $0.name == listName }
        )
        if let count = try? context.fetchCount(desc) {
            templateCreated = count > 0
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
