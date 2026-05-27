import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer
    @State private var selectedTab = 0
    private let tutorial = TutorialManager.shared

    init() {
        container = Self.makeContainer()
        ProdutoBase.sementar(context: container.mainContext)
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self,
                                          Mercado.self, PrecoMercado.self, CategoriaCustom.self)
        } catch {
            wipeStore()
            do {
                return try ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self,
                                              Mercado.self, PrecoMercado.self, CategoriaCustom.self)
            } catch {
                fatalError("SwiftData: \(error)")
            }
        }
    }

    private static func wipeStore() {
        let base = URL.applicationSupportDirectory
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: base.appending(path: "default.store\(suffix)"))
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ListasView()
                    .tabItem { Label("Listas", systemImage: "cart.fill") }
                    .tag(0)
                ProdutosView()
                    .tabItem { Label("Catálogo", systemImage: "shippingbox.fill") }
                    .tag(1)
                RelatorioView()
                    .tabItem { Label("Relatório", systemImage: "chart.bar.fill") }
                    .tag(2)
                PerfilView()
                    .tabItem { Label("Perfil", systemImage: "person.fill") }
                    .tag(3)
            }
            .environment(ThemeSettings.shared)
            .environment(tutorial)
            .overlayPreferenceValue(TutorialAnchorKey.self) { anchors in
                if tutorial.isActive {
                    TutorialOverlayView(
                        tutorial: tutorial,
                        anchors: anchors,
                        switchTab: { selectedTab = $0 }
                    )
                }
            }
            .onAppear {
                if !tutorial.completed {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        tutorial.start(resetTab: { selectedTab = $0 })
                    }
                }
            }
            // Sync tab when tutorial advances
            .onChange(of: tutorial.currentStep) { _, _ in
                if tutorial.isActive {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tutorial.requestedTab
                    }
                }
            }
        }
        .modelContainer(container)
    }
}
