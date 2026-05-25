import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer

    init() {
        container = Self.makeContainer()
        ProdutoBase.sementar(context: container.mainContext)
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self)
        } catch {
            wipeStore()
            do {
                return try ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self)
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
            TabView {
                ListasView()
                    .tabItem { Label("Listas", systemImage: "cart.fill") }
                ProdutosView()
                    .tabItem { Label("Catálogo", systemImage: "shippingbox.fill") }
                RelatorioView()
                    .tabItem { Label("Relatório", systemImage: "chart.bar.fill") }
                PerfilView()
                    .tabItem { Label("Perfil", systemImage: "person.fill") }
            }
        }
        .modelContainer(container)
    }
}
