import SwiftUI
import MapKit
import CoreLocation

struct MapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: (String, Double, Double) -> Void

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var pinCoord: CLLocationCoordinate2D?
    @State private var pinNome: String?
    @State private var resolving = false
    @StateObject private var locationManager = LocationPermission()

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position) {
                    UserAnnotation()
                    if let coord = pinCoord {
                        Marker(pinNome ?? "Local selecionado", coordinate: coord)
                            .tint(AppTheme.accent)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { point in
                    guard let coord = proxy.convert(point, from: .local) else { return }
                    pinCoord = coord
                    pinNome = nil
                    resolving = true
                    Task { await reverseGeocode(coord) }
                }
            }
            .navigationTitle("Escolher local")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        guard let coord = pinCoord else { return }
                        onSelect(pinNome ?? "Local selecionado", coord.latitude, coord.longitude)
                        dismiss()
                    }
                    .fontWeight(.heavy)
                    .tint(AppTheme.accent)
                    .disabled(pinCoord == nil)
                }
            }
            .safeAreaInset(edge: .bottom) { statusBar }
            .onAppear { locationManager.request() }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            if resolving {
                ProgressView()
                Text("Identificando local…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let nome = pinNome {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text(nome)
                    .font(.subheadline.weight(.semibold))
            } else {
                Image(systemName: "hand.tap")
                    .foregroundStyle(.secondary)
                Text("Toque no mapa para marcar o local")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        if let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
           let p = placemarks.first {
            pinNome = p.name ?? p.thoroughfare ?? p.locality ?? "Local selecionado"
        } else {
            pinNome = "Local selecionado"
        }
        resolving = false
    }
}

@MainActor
private final class LocationPermission: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}
