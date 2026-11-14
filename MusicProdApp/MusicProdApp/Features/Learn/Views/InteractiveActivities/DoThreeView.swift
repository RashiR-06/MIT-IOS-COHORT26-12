import SwiftUI

/// Do 3 "Match the brief" under the top bar (Figma G · 3a–d): the brief on
/// the left, the tempo dial on the right, and along the bottom Play / Pause,
/// Hint, the feedback (or the hint strip) and Check / Next. It only draws
/// the view model's state and forwards actions.
struct DoThreeView: View {
    @Bindable var viewModel: DoThreeViewModel
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Layout facts for the result's glide into the feedback's place.
    @State private var feedbackCenter = CGPoint.zero
    @State private var screenSize = CGSize.zero
    /// True while the result glides into place.
    @State private var alertSettled = false

    private static let space = "doThree"
    /// The result shows in Title 1 (28 pt at the default text size); its
    /// place at the bottom is 15 pt, so it shrinks by 15/28 as it glides.
    private static let alertFontSize: CGFloat = 28
    private static let feedbackFontSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Match the brief.")
                        .font(.system(size: 26, weight: .semibold))
                        .tracking(-0.5)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(height: 30)
                        .padding(.top, 35)
                    Text("Set a tempo that fits this vibe.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(height: 20)
                        .padding(.top, 4)
                    BriefCard(brief: viewModel.brief)
                        .padding(.top, 16)
                }
                Spacer(minLength: 0)
                TempoDial(bpm: $viewModel.bpm, zone: viewModel.shownZone)
                    .disabled(viewModel.isComplete || viewModel.inputsLocked)
                    .padding(.top, 13)
                    .padding(.leading, 20)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                TransportButton(isPlaying: viewModel.isPlaying, action: viewModel.togglePlayPause)
                GlassTextButton(title: "Hint", systemImage: "lightbulb.fill", action: viewModel.toggleHint)
                    .disabled(viewModel.inputsLocked)
                bottomMessage
                    .frame(maxWidth: 420, alignment: .leading)
                Spacer(minLength: 0)
                PrimaryButton(title: viewModel.primaryTitle,
                              action: viewModel.isComplete ? onNext : viewModel.check)
                    .disabled(viewModel.inputsLocked)
            }
        }
        .coordinateSpace(.named(Self.space))
        .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
        .overlay { checkAlert }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hintOpen)
        .animation(.easeInOut(duration: 0.25), value: viewModel.zoneRevealed)
        .animation(.easeOut(duration: 0.35), value: viewModel.checkAlert)
        .sensoryFeedback(trigger: viewModel.checkAlert) { _, new in
            guard new == .showing else { return nil }
            return viewModel.alertMessage?.tone == .good ? .success : .warning
        }
        // Hold the result in the centre, then let it glide into place.
        .task(id: viewModel.checkAlert) {
            guard viewModel.checkAlert == .showing else { return }
            if let message = viewModel.alertMessage {
                AccessibilityNotification.Announcement("\(message.title). \(message.detail)").post()
            }
            try? await Task.sleep(for: DoThreeViewModel.alertHold)
            guard !Task.isCancelled else { return }
            viewModel.checkAlertHoldEnded()
        }
        .onChange(of: viewModel.checkAlert) { _, new in
            guard new == .settling else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.6)) {
                alertSettled = true
            } completion: {
                viewModel.checkAlertDidSettle()
                alertSettled = false
            }
        }
        .onAppear { viewModel.enter() }
        .onDisappear { viewModel.leave() }
    }

    /// While open, the hint covers the feedback (Figma 3d); closing it shows
    /// the feedback again.
    @ViewBuilder private var bottomMessage: some View {
        if viewModel.hintOpen {
            TempoHintStrip(feels: viewModel.tempoFeels)
                .transition(.opacity)
        } else if let message = viewModel.feedback {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: message.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(message.tone.iconColor)
                    Text(message.title)
                        .font(.system(size: Self.feedbackFontSize, weight: .semibold))
                        .foregroundStyle(message.tone.titleColor)
                }
                Text(message.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .onGeometryChange(for: CGPoint.self) { proxy in
                let frame = proxy.frame(in: .named(Self.space))
                return CGPoint(x: frame.midX, y: frame.midY)
            } action: { feedbackCenter = $0 }
            // Hidden while the result shows big instead.
            .opacity(isAlertCovering ? 0 : 1)
            .accessibilityElement(children: .combine)
            .transition(.opacity)
        }
    }

    /// The result is up and has not yet handed over to the feedback.
    private var isAlertCovering: Bool {
        viewModel.checkAlert != .hidden && !alertSettled
    }

    /// After Check: the screen dims and the result shows big in the centre,
    /// then shrinks and glides into the feedback's place (with Reduce Motion
    /// it only fades). The drums keep playing.
    private var checkAlert: some View {
        let glide = alertSettled && !reduceMotion
        return ZStack {
            AppColor.background
                .opacity(isAlertCovering ? 0.75 : 0)
                .allowsHitTesting(false)

            if viewModel.checkAlert != .hidden, let message = viewModel.alertMessage {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: message.symbol)
                            .foregroundStyle(message.tone.iconColor)
                        Text(message.title)
                            .foregroundStyle(message.tone.titleColor)
                    }
                    .font(.title.bold())
                    Text(message.detail)
                        .font(.title3)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
                .scaleEffect(glide ? Self.feedbackFontSize / Self.alertFontSize : 1)
                .offset(glide ? CGSize(width: feedbackCenter.x - screenSize.width / 2,
                                       height: feedbackCenter.y - screenSize.height / 2) : .zero)
                .opacity(alertSettled ? 0 : 1)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.92)))
                .accessibilityHidden(true)
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    DoThreeView(viewModel: DoThreeViewModel(beatPlayer: BeatPlayer()), onNext: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
