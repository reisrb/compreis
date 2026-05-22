import SwiftUI
import SwiftData

@main
struct ListaDeComprasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
