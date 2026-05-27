import SwiftUI

// MARK: - Anchor IDs

enum TutorialAnchorID: String, Hashable {
    case novaListaFAB
    case addItemFAB
    case modoMercadoBanner
    case catalogoFAB
}

struct TutorialAnchorKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [TutorialAnchorID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TutorialAnchorID: Anchor<CGRect>],
                       nextValue: () -> [TutorialAnchorID: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func tutorialAnchor(_ id: TutorialAnchorID) -> some View {
        anchorPreference(key: TutorialAnchorKey.self, value: .bounds) { [id: $0] }
    }
}

// MARK: - Steps

struct TutorialStep {
    let titulo: String
    let descricao: String
    let icone: String
    let anchorID: TutorialAnchorID?
    let tab: Int
}

// MARK: - Manager

@Observable final class TutorialManager {
    nonisolated(unsafe) static let shared = TutorialManager()

    static let steps: [TutorialStep] = [
        TutorialStep(
            titulo: "Welcome to Compreis!",
            descricao: "Manage your shopping lists with price history and market mode. See how it works in a few steps.",
            icone: "cart.fill",
            anchorID: nil,
            tab: 0
        ),
        TutorialStep(
            titulo: "Create a list",
            descricao: "Tap the + button to create a list. You can set a name, date and market location.",
            icone: "plus.circle.fill",
            anchorID: .novaListaFAB,
            tab: 0
        ),
        TutorialStep(
            titulo: "Add items",
            descricao: "Inside the list, use + to add products. The app searches your price history automatically as you type.",
            icone: "text.badge.plus",
            anchorID: .addItemFAB,
            tab: 0
        ),
        TutorialStep(
            titulo: "Market mode",
            descricao: "Enable market mode when you are at the supermarket. Tapping ✓ on an item confirms the price paid and moves it to the cart.",
            icone: "cart.fill.badge.checkmark",
            anchorID: .modoMercadoBanner,
            tab: 0
        ),
        TutorialStep(
            titulo: "Product catalogue",
            descricao: "The catalogue stores all products you have used with reference prices. Add, edit or remove products here.",
            icone: "shippingbox.fill",
            anchorID: .catalogoFAB,
            tab: 1
        ),
        TutorialStep(
            titulo: "All done! 🎉",
            descricao: "You now know the essentials of Compreis. Explore templates, reports and settings in Profile.",
            icone: "checkmark.seal.fill",
            anchorID: nil,
            tab: 0
        ),
    ]

    var isActive = false
    var currentStep = 0

    private var _completed: Bool = UserDefaults.standard.bool(forKey: "tutorial_done") {
        didSet { UserDefaults.standard.set(_completed, forKey: "tutorial_done") }
    }
    var completed: Bool {
        get { _completed }
        set { _completed = newValue }
    }

    var step: TutorialStep { TutorialManager.steps[currentStep] }
    var isLast: Bool { currentStep == TutorialManager.steps.count - 1 }
    var progress: Double { Double(currentStep + 1) / Double(TutorialManager.steps.count) }
    var requestedTab: Int { step.tab }

    func start(resetTab: (Int) -> Void = { _ in }) {
        currentStep = 0
        withAnimation(.spring(duration: 0.4)) { isActive = true }
        resetTab(step.tab)
    }

    func next(switchTab: (Int) -> Void = { _ in }) {
        if isLast { finish(); return }
        withAnimation(.spring(duration: 0.25)) { currentStep += 1 }
        switchTab(step.tab)
    }

    func skip() { finish() }

    private func finish() {
        withAnimation(.spring(duration: 0.3)) { isActive = false }
        completed = true
    }
}
