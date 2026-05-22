import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Item.self, ProdutoHistorico.self, ListaDeCompras.self)
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
