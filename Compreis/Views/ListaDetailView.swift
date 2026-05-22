import SwiftUI
import MapKit

struct ListaDetailView: View {
    let lista: ListaDeCompras
    @Environment(\.dismiss) private var dismiss

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = lista.localLatitude, let lon = lista.localLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var body: some View {
        NavigationStack {
            List {
                if let coord = coordinate {
                    Section("Local") {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))) {
                            Marker(lista.localNome ?? "", coordinate: coord)
                                .tint(.green)
                        }
                        .frame(height: 180)
                        .listRowInsets(EdgeInsets())
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.green)
                            Text(lista.localNome ?? "")
                                .font(.subheadline)
                        }
                    }
                }

                Section("Detalhes") {
                    LabeledContent("Nome", value: lista.nome)

                    LabeledContent("Status") {
                        if lista.finalizada {
                            Text("Finalizada").foregroundStyle(.secondary)
                        } else {
                            Text("Em aberto").foregroundStyle(.green)
                        }
                    }

                    LabeledContent("Itens") {
                        Text("\(lista.itens.count) \(lista.itens.count == 1 ? "item" : "itens")")
                    }

                    if !lista.itens.isEmpty {
                        LabeledContent("Total", value: lista.total.brl)
                    }

                    if let data = lista.dataMercado {
                        LabeledContent("Data do mercado", value: data.formatted(date: .abbreviated, time: .shortened))
                    }

                    LabeledContent("Criada em", value: lista.criadaEm.formatted(date: .abbreviated, time: .shortened))

                    if let fim = lista.finalizadaEm {
                        LabeledContent("Finalizada em", value: fim.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Detalhes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(.green)
                }
            }
        }
    }
}
