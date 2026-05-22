import SwiftUI
import MapKit

struct ListaDetailView: View {
    let lista: ListaDeCompras
    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20)
                        TextField("Nome", text: $nome)
                    }
                } header: { RockSectionHeader(title: "Nome") }

                if !lista.itens.isEmpty {
                    Section {
                        LabeledContent("Itens") {
                            Text("\(lista.itens.count) \(lista.itens.count == 1 ? "item" : "itens")")
                        }
                        LabeledContent("Total") {
                            Text(lista.total.brl)
                                .foregroundStyle(AppTheme.accent)
                                .fontWeight(.heavy)
                        }
                        LabeledContent("Status") {
                            Text(lista.finalizada ? "Finalizada" : "Em aberto")
                                .foregroundStyle(lista.finalizada ? .secondary : AppTheme.accent)
                        }
                    } header: { RockSectionHeader(title: "Resumo") }
                }

                Section {
                    Toggle("Definir data", isOn: $usarData)
                        .tint(AppTheme.accent)
                    if usarData {
                        DatePicker("Data", selection: $dataMercado, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.accent)
                    }
                } header: { RockSectionHeader(title: "Data do mercado") }

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
                                    localNome = nil; localLat = nil; localLon = nil
                                    localQuery = ""; completer.clear()
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
                                Label("Escolher no mapa", systemImage: "map")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                            }
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
                } header: { RockSectionHeader(title: "Local do mercado") }
            }
            .navigationTitle("Detalhes")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showMapPicker) {
                MapPickerView { nome, lat, lon in
                    localNome = nome; localLat = lat; localLon = lon
                    localQuery = nome; completer.clear()
                    usarLocal = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        lista.nome = nome.isEmpty ? lista.nome : nome
                        lista.dataMercado = usarData ? dataMercado : nil
                        lista.localNome = usarLocal ? localNome : nil
                        lista.localLatitude = usarLocal ? localLat : nil
                        lista.localLongitude = usarLocal ? localLon : nil
                        dismiss()
                    }
                    .fontWeight(.heavy)
                    .tint(AppTheme.accent)
                }
            }
        }
        .onAppear { loadEstado() }
    }

    private func loadEstado() {
        nome = lista.nome
        if let data = lista.dataMercado {
            usarData = true
            dataMercado = data
        }
        if let nome = lista.localNome {
            usarLocal = true
            localNome = nome
            localLat = lista.localLatitude
            localLon = lista.localLongitude
            localQuery = nome
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
