import SwiftUI

/// The three Learn cards under the top bar (Figma F · 1–3b). One card shows
/// at a time; swipe it or use the arrows to move between them, and Try it
/// on the last card goes on to Do. Each card is a lesson step, so Back,
/// Next and the progress bar keep working as before; this view stays on
/// screen across the three steps so the cards can slide between them.
struct LearnView: View {
    let viewModel: LearnViewModel
    /// The card to show, from the lesson step (0, 1 or 2).
    let card: Int
    let onNext: () -> Void
    let onBack: () -> Void

    /// The card on screen; it follows `card` with a slide.
    @State private var shownCard: Int
    @State private var movingForward = true
    @State private var dragX: CGFloat = 0

    /// A drag further than this changes card (from the mockup).
    private static let swipeDistance: CGFloat = 70

    init(viewModel: LearnViewModel, card: Int, onNext: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.viewModel = viewModel
        self.card = card
        self.onNext = onNext
        self.onBack = onBack
        _shownCard = State(initialValue: card)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                cardContent(shownCard)
                    .id(shownCard)
                    .transition(.asymmetric(
                        insertion: .move(edge: movingForward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: movingForward ? .leading : .trailing).combined(with: .opacity)))
            }
            .offset(x: dragX)
            .rotationEffect(.degrees(dragX / 40))
            .gesture(swipe)
            .padding(.top, 10)

            Spacer(minLength: 8)

            bottomRow
        }
        .onChange(of: card) { old, new in
            movingForward = new > old
            withAnimation(.smooth(duration: 0.35)) { shownCard = new }
            viewModel.show(card: new)
        }
        // A moment after appearing, so the previous screen has stopped its
        // own sound first.
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            viewModel.show(card: card)
        }
        .onDisappear { viewModel.leave() }
    }

    private func cardContent(_ index: Int) -> some View {
        Group {
            switch index {
            case 0: LearnPulseCard(viewModel: viewModel)
            case 1: LearnBPMCard(viewModel: viewModel)
            default: LearnEnergyCard(viewModel: viewModel)
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 19)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 243, alignment: .top)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    /// The card follows the finger and tilts a little; past 70 pt it moves
    /// on (left) or back (right). Card 1 has nothing before it and card 3
    /// moves on with Try it.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { dragX = $0.translation.width }
            .onEnded { drag in
                let distance = drag.translation.width
                withAnimation(.smooth(duration: 0.3)) { dragX = 0 }
                if distance < -Self.swipeDistance, card < LearnCardsContent.cardCount - 1 {
                    onNext()
                } else if distance > Self.swipeDistance, card > 0 {
                    onBack()
                }
            }
    }

    /// ← on cards 2–3, the page dots, and → or Try it.
    private var bottomRow: some View {
        ZStack {
            HStack(spacing: 8) {
                ForEach(0..<LearnCardsContent.cardCount, id: \.self) { index in
                    Circle()
                        .fill(index == shownCard ? AppColor.textPrimary : AppColor.textSecondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Card \(shownCard + 1) of \(LearnCardsContent.cardCount)")

            HStack {
                if shownCard > 0 {
                    GlassIconButton(systemImage: "chevron.left", label: "Previous card", action: onBack)
                }
                Spacer()
                if shownCard < LearnCardsContent.cardCount - 1 {
                    GlassIconButton(systemImage: "chevron.right", label: "Next card",
                                    tint: AppColor.accentCyan, action: onNext)
                } else {
                    PrimaryButton(title: "Try it", action: onNext)
                }
            }
        }
        .frame(height: 50)
    }
}

#Preview(traits: .landscapeLeft) {
    LearnView(viewModel: LearnViewModel(beatPlayer: BeatPlayer()), card: 1, onNext: {}, onBack: {})
        .padding(.horizontal, 59)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
