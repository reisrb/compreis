import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self)
        } catch {
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            container = try! ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ListasView()
                    .tabItem { Label("Listas", systemImage: "cart.fill") }
                RelatorioView()
                    .tabItem { Label("Relatório", systemImage: "chart.bar.fill") }
            }
        }
        .modelContainer(container)
    }
}
