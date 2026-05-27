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
    @Query(filter: #Predicate<ListaDeCompras> { $0.isTemplate == true && $0.isPredefined == false })
    private var templates: [ListaDeCompras]
    @Query(filter: #Predicate<ListaDeCompras> { $0.isTemplate == true && $0.isPredefined == true })
    private var predefinedTemplates: [ListaDeCompras]

    var titulo: String = "New list"
    var isTemplate: Bool = false
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
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Static model
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

                    let previewDisponivel = (modeloSelecionado != .vazia && templateUsuario == nil)
                        || templateUsuario != nil
                    if previewDisponivel {
                        Button { showPreview = true } label: {
                            HStack {
                                Image(systemName: "eye")
                                let count = templateUsuario.map { $0.itens.count }
                                    ?? modeloSelecionado.produtos.count
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
                                        VStack(spacing: 6) {
                                            Image(systemName: "star.fill")
                                                .font(.title2.weight(.semibold))
                                                .foregroundStyle(sel ? AppTheme.accent : .secondary)
                                            Text(t.nome)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(sel ? AppTheme.accent : .primary)
                                                .lineLimit(1)
                                            Text("\(t.itens.count) \(t.itens.count == 1 ? "item" : "items")")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(width: 110)
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
                        TextField("Ex: Week, BBQ…", text: $nome)
                    }
                } header: { Text(isTemplate ? "Template name" : "List name") }

                // MARK: Date
                if !isTemplate {
                Section {
                    Toggle("Set date", isOn: $usarData)
                        .tint(AppTheme.accent)
                    if usarData {
                        DatePicker("Date", selection: $dataMercado, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.accent)
                    }
                } header: { Text("When going to the market") }
                } // if !isTemplate

                // MARK: Location
                if !isTemplate {
                Section {
                    Toggle("Set location", isOn: $usarLocal)
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
                                Label("Choose on map", systemImage: "map")
                                    .font(.subheadline).foregroundStyle(AppTheme.accent)
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary).frame(width: 20)
                                TextField("Search supermarket…", text: $localQuery)
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
                } header: { Text("Market location") }
                } // if !isTemplate
            }
            .navigationTitle(titulo)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPreview) {
                if let t = templateUsuario {
                    TemplatePreviewSheet(nome: t.nome, itens: t.itens.map {
                        ProdutoSemente(nome: $0.nome, categoria: $0.categoria, unidade: $0.unidade)
                    })
                } else if let stored = predefinedTemplates.first(where: { $0.nome == modeloSelecionado.rawValue }) {
                    TemplatePreviewSheet(nome: stored.nome, itens: stored.itens.map {
                        ProdutoSemente(nome: $0.nome, categoria: $0.categoria, unidade: $0.unidade)
                    })
                } else {
                    TemplatePreviewSheet(nome: modeloSelecionado.rawValue,
                                         itens: modeloSelecionado.produtos)
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapPickerView { nome, lat, lon in
                    localNome = nome; localLat = lat; localLon = lon
                    localQuery = nome; completer.clear(); usarLocal = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(
                            nome.isEmpty ? "List" : nome,
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

// MARK: - Preview sheet

private struct TemplatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let nome: String
    let itens: [ProdutoSemente]

    private var porCategoria: [(Categoria, [ProdutoSemente])] {
        let agrupados = Dictionary(grouping: itens, by: { $0.categoria })
        return Categoria.allCases.compactMap { cat in
            guard let grupo = agrupados[cat], !grupo.isEmpty else { return nil }
            return (cat, grupo.sorted { $0.nome < $1.nome })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(porCategoria, id: \.0) { cat, produtos in
                    Section {
                        ForEach(produtos, id: \.nome) { p in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icone)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(cat.cor)
                                    .frame(width: 20)
                                Text(p.nome)
                                    .font(.subheadline)
                                Spacer()
                                Text(p.unidade.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Label(cat.rawValue, systemImage: cat.icone)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(cat.cor)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(nome)
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
