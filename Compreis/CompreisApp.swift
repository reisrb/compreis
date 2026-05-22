import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer

    init() {
        container = ModelContainer(for: Item.self, ProdutoHistorico.self)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
