import SwiftUI
import SwiftData

@main
struct CompreisApp: App {
    let container: ModelContainer
    @State private var selectedTab = 0
    private let tutorial = TutorialManager.shared

    init() {
        container = Self.makeContainer()
        ProductBase.seed(context: container.mainContext)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema(SchemaV2.models)
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self,
                                      configurations: [config])
        } catch {
            fatalError("SwiftData store could not be opened: \(error)")
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
