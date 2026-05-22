import SwiftUI
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

struct NovaListaView: View {
    @Environment(\.dismiss) private var dismiss

    var onCreate: (String, Date?, String?, Double?, Double?) -> Void

    @State private var nome: String = ""
    @State private var usarData = false
    @State private var dataMercado = Date()
    @State private var usarLocal = false
    @State private var localQuery = ""
    @State private var localNome: String?
    @State private var localLat: Double?
    @State private var localLon: Double?
    @StateObject private var completer = SearchCompleter()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        TextField("Ex: Semana, Churrasco…", text: $nome)
                    }
                } header: {
                    Text("Nome da lista")
                }

                Section {
                    Toggle("Definir data", isOn: $usarData)
                        .tint(.green)
                    if usarData {
                        DatePicker("Data", selection: $dataMercado, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(.green)
                    }
                } header: {
                    Text("Quando vai ao mercado")
                }

                Section {
                    Toggle("Definir local", isOn: $usarLocal)
                        .tint(.green)
                    if usarLocal {
                        if let pinned = localNome, let lat = localLat, let lon = localLon {
                            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            Map(initialPosition: .region(MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                            ))) {
                                Marker(pinned, coordinate: coord)
                                    .tint(.green)
                            }
                            .frame(height: 160)
                            .listRowInsets(EdgeInsets())
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.green)
                                Text(pinned)
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    localNome = nil; localLat = nil; localLon = nil; localQuery = ""
                                    completer.clear()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                TextField("Buscar supermercado…", text: $localQuery)
                                    .onChange(of: localQuery) { _, q in completer.search(q) }
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
                } header: {
                    Text("Local do mercado")
                }
            }
            .navigationTitle("Nova lista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        onCreate(
                            nome.isEmpty ? "Lista" : nome,
                            usarData ? dataMercado : nil,
                            usarLocal ? localNome : nil,
                            usarLocal ? localLat : nil,
                            usarLocal ? localLon : nil
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.green)
                }
            }
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        let req = MKLocalSearch.Request(completion: completion)
        guard let response = try? await MKLocalSearch(request: req).start(),
              let item = response.mapItems.first else { return }
        localNome = item.name ?? completion.title
        localLat = item.placemark.coordinate.latitude
        localLon = item.placemark.coordinate.longitude
        localQuery = item.name ?? completion.title
        completer.clear()
    }
}
