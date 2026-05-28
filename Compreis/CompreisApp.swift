import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer
    let containerFailed: Bool
    @State private var selectedTab = 0
    @State private var showStoreError = false
    private let tutorial = TutorialManager.shared

    init() {
        let schema = Schema(SchemaV2.models)
        let config = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self,
                                       configurations: [config]) {
            container = c
            containerFailed = false
        } else {
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [memConfig])
            containerFailed = true
        }
        ProductBase.seed(context: container.mainContext)
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
                ListsView()
                    .tabItem { Label("Lists", systemImage: "cart.fill") }
                    .tag(0)
                CatalogueView()
                    .tabItem { Label("Catalogue", systemImage: "shippingbox.fill") }
                    .tag(1)
                ReportView()
                    .tabItem { Label("Report", systemImage: "chart.bar.fill") }
                    .tag(2)
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.fill") }
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
                if containerFailed { showStoreError = true }
                if !tutorial.completed {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        tutorial.start(resetTab: { selectedTab = $0 })
                    }
                }
            }
            .alert("Dados não puderam ser abertos", isPresented: $showStoreError) {
                Button("Tentar novamente") { exit(0) }
                Button("Redefinir dados", role: .destructive) {
                    CompreisApp.wipeStore()
                    exit(0)
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("O banco de dados não pôde ser aberto. Tente novamente ou redefina os dados para continuar.")
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
