import SwiftUI

struct TutorialOverlayView: View {
    let tutorial: TutorialManager
    let anchors: [TutorialAnchorID: Anchor<CGRect>]
    let switchTab: (Int) -> Void

    private var step: TutorialStep { tutorial.step }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                spotlight(proxy: proxy)
                callout(proxy: proxy)
            }
        }
        .ignoresSafeArea()
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - Spotlight

    @ViewBuilder
    private func spotlight(proxy: GeometryProxy) -> some View {
        if let anchorID = step.anchorID, let anchor = anchors[anchorID] {
            let rect = proxy[anchor]
            ZStack {
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: rect.width + 20, height: rect.height + 20)
                    .position(x: rect.midX, y: rect.midY)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            // Pulsing border around highlighted element
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: rect.width + 20, height: rect.height + 20)
                .position(x: rect.midX, y: rect.midY)
                .shadow(color: .white.opacity(0.4), radius: 8)
        } else {
            Color.black.opacity(0.72).ignoresSafeArea()
        }
    }

    // MARK: - Callout

    @ViewBuilder
    private func callout(proxy: GeometryProxy) -> some View {
        let screenH = proxy.size.height
        let anchorMidY: CGFloat = {
            guard let id = step.anchorID, let anchor = anchors[id] else { return screenH / 2 }
            return proxy[anchor].midY
        }()
        let showAbove = anchorMidY > screenH * 0.55

        VStack(spacing: 0) {
            if showAbove { Spacer() }

            calloutCard

            if !showAbove { Spacer() }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, showAbove ? 40 : 0)
        .padding(.bottom, showAbove ? 0 : 100)
    }

    private var calloutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon + progress
            HStack {
                ZStack {
                    Circle().fill(AppTheme.accentSubtle).frame(width: 44, height: 44)
                    Image(systemName: step.icone)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<TutorialManager.steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == tutorial.currentStep ? AppTheme.accent : Color.secondary.opacity(0.3))
                            .frame(width: i == tutorial.currentStep ? 8 : 6, height: i == tutorial.currentStep ? 8 : 6)
                            .animation(.spring(duration: 0.2), value: tutorial.currentStep)
                    }
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 6) {
                Text(step.titulo)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text(step.descricao)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Buttons
            HStack(spacing: 12) {
                Button("Pular") {
                    tutorial.skip()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer()

                Button {
                    tutorial.next(switchTab: switchTab)
                } label: {
                    HStack(spacing: 6) {
                        Text(tutorial.isLast ? "Concluir" : "Próximo")
                        if !tutorial.isLast {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent, in: Capsule())
                    .rockGlow(radius: 6)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
    }
}
