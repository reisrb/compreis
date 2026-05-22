import SwiftUI
import SwiftData

@main
struct ListaDeComprasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Item.self)
    }
}
