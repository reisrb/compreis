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

struct NovaListaView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<ListaDeCompras> { $0.isTemplate })
    private var templates: [ListaDeCompras]

    var onCreate: (String, Date?, String?, Double?, Double?, ListaModelo, ListaDeCompras?) -> Void

    @State private var nome: String = ""
    @State private var usarData = false
    @State private var dataMercado = Date()
    @State private var usarLocal = false
    @State private var localQuery = ""
    @State private var localNome: String?
    @State private var localLat: Double?
    @State private var localLon: Double?
    @StateObject private var completer = SearchCompleter()
    @State private var showMapPicker = false
    @State private var modeloSelecionado: ListaModelo = .vazia
    @State private var templateUsuario: ListaDeCompras?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Modelo estático
                Section {
                    HStack(spacing: 8) {
                        ForEach(ListaModelo.allCases, id: \.self) { modelo in
                            let sel = modeloSelecionado == modelo && templateUsuario == nil
                            Button {
                                modeloSelecionado = modelo
                                templateUsuario = nil
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: modelo.icone)
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(sel ? AppTheme.accent : .secondary)
                                    Text(modelo.rawValue)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(sel ? AppTheme.accent : .primary)
                                    Text(modelo.detalhe)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(sel
                                    ? AppTheme.accentSubtle
                                    : Color.secondary.opacity(0.07),
                                    in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(sel ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Modelo") }

                // MARK: Templates do usuário
                if !templates.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(templates) { t in
                                    let sel = templateUsuario?.id == t.id
                                    Button {
                                        templateUsuario = t
                                        modeloSelecionado = .vazia
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Image(systemName: "star.fill")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(sel ? AppTheme.accent : Color.secondary)
                                            Text(t.nome)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(sel ? AppTheme.accent : .primary)
                                                .lineLimit(1)
                                            Text("\(t.itens.count) \(t.itens.count == 1 ? "item" : "itens")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(sel
                                            ? AppTheme.accentSubtle
                                            : Color.secondary.opacity(0.07),
                                            in: RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(sel ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    } header: { Text("Seus templates") }
                }

                // MARK: Nome
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Ex: Semana, Churrasco…", text: $nome)
                    }
                } header: { Text("Nome da lista") }

                // MARK: Data
                Section {
                    Toggle("Definir data", isOn: $usarData)
                        .tint(AppTheme.accent)
                    if usarData {
                        DatePicker("Data", selection: $dataMercado, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.accent)
                    }
                } header: { Text("Quando vai ao mercado") }

                // MARK: Local
                Section {
                    Toggle("Definir local", isOn: $usarLocal)
                        .tint(AppTheme.accent)
                    if usarLocal {
                        if let pinned = localNome, let lat = localLat, let lon = localLon {
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
                                    localNome = nil; localLat = nil; localLon = nil
                                    localQuery = ""; completer.clear()
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Button { showMapPicker = true } label: {
                                Label("Escolher no mapa", systemImage: "map")
                                    .font(.subheadline).foregroundStyle(AppTheme.accent)
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary).frame(width: 20)
                                TextField("Buscar supermercado…", text: $localQuery)
                                    .onChange(of: localQuery) { _, q in completer.search(q) }
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
                } header: { Text("Local do mercado") }
            }
            .navigationTitle("Nova lista")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showMapPicker) {
                MapPickerView { nome, lat, lon in
                    localNome = nome; localLat = lat; localLon = lon
                    localQuery = nome; completer.clear(); usarLocal = true
                }
            }
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
                            usarLocal ? localLon : nil,
                            modeloSelecionado,
                            templateUsuario
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
        localNome = item.name ?? completion.title
        localLat = item.placemark.coordinate.latitude
        localLon = item.placemark.coordinate.longitude
        localQuery = item.name ?? completion.title
        completer.clear()
    }
}
