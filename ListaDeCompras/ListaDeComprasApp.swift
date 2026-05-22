import SwiftUI
import SwiftData

@main
struct ListaDeComprasApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Item.self)
        } catch {
            // store corrompido — apaga e recria do zero
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            container = try! ModelContainer(for: Item.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
