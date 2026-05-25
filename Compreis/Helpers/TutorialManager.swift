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
            titulo: "Bem-vindo ao Compreis!",
            descricao: "Gerencie suas listas de compras com histórico de preços e modo mercado. Veja como funciona em poucos passos.",
            icone: "cart.fill",
            anchorID: nil,
            tab: 0
        ),
        TutorialStep(
            titulo: "Criar uma lista",
            descricao: "Toque no botão + para criar uma lista. Você pode dar um nome, definir data e localização do mercado.",
            icone: "plus.circle.fill",
            anchorID: .novaListaFAB,
            tab: 0
        ),
        TutorialStep(
            titulo: "Adicionar itens",
            descricao: "Dentro da lista, use o + para adicionar produtos. O app busca preços do seu histórico automaticamente ao digitar o nome.",
            icone: "text.badge.plus",
            anchorID: .addItemFAB,
            tab: 0
        ),
        TutorialStep(
            titulo: "Modo mercado",
            descricao: "Ative o modo mercado quando estiver no supermercado. Ao clicar no ✓ de um item, você confirma o preço pago e ele vai para o carrinho.",
            icone: "cart.fill.badge.checkmark",
            anchorID: .modoMercadoBanner,
            tab: 0
        ),
        TutorialStep(
            titulo: "Catálogo de produtos",
            descricao: "O catálogo guarda todos os produtos que você já usou com os preços de referência. Cadastre, edite ou remova produtos aqui.",
            icone: "shippingbox.fill",
            anchorID: .catalogoFAB,
            tab: 1
        ),
        TutorialStep(
            titulo: "Tudo pronto! 🎉",
            descricao: "Você já conhece o essencial do Compreis. Explore os templates, relatórios e configurações no Perfil.",
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
