import SwiftUI

/// Do 2 "Find the 1" under the top bar (Figma G · 2a–c): instructions and
/// the round on the left, the 1–2–3–4 tiles and tap pad on the right,
/// Play / Pause bottom-left and Next once finished. It only draws the
/// view model's state and forwards touches.
struct DoTwoView: View {
    let viewModel: DoTwoViewModel
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Layout facts for the round alert's glide back into the guide line.
    @State private var guideCenter = CGPoint.zero
    @State private var screenSize = CGSize.zero
    /// True while the alert glides into place.
    @State private var alertSettled = false

    private static let space = "doTwo"
    /// The alert uses Title 1 (28 pt at the default text size); the guide
    /// line is 15 pt, so the alert shrinks by 15/28 as it glides in.
    private static let alertFontSize: CGFloat = 28
    private static let guideFontSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 11) {
                instructions
                VStack(spacing: 16) {
                    // Redrawn every screen refresh while playing so the
                    // lights follow the audio clock.
                    TimelineView(.animation(paused: !viewModel.isPlaying)) { _ in
                        CountTilesView(light: viewModel.light, mark: viewModel.tileMark)
                    }
                    TapPadView(message: viewModel.padMessage, onTouchDown: viewModel.tap(at:))
                }
                .padding(.top, 10)
            }

            Spacer(minLength: 8)

            HStack {
                // "Rings the Play button" after a tap before Play.
                TransportButton(isPlaying: viewModel.isPlaying, showsRing: viewModel.needsPlay,
                                action: viewModel.togglePlayPause)
                Spacer()
                if viewModel.isComplete {
                    PrimaryButton(title: "Next", action: onNext)
                }
            }
        }
        .coordinateSpace(.named(Self.space))
        .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
        .overlay { roundAlert }
        .animation(.easeOut(duration: 0.35), value: viewModel.roundAlert)
        .sensoryFeedback(.success, trigger: viewModel.roundAlert) { _, new in new == .showing }
        .onChange(of: viewModel.roundAlert) { _, new in
            if new == .showing {
                AccessibilityNotification.Announcement(viewModel.guideText).post()
            } else if new == .settling {
                // Glide into the guide line, then hand over to it.
                withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.6)) {
                    alertSettled = true
                } completion: {
                    viewModel.roundAlertDidSettle()
                    alertSettled = false
                }
            }
        }
        .onAppear { viewModel.enter() }
        .onDisappear { viewModel.leave() }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tap only on beat 1.")
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(AppColor.textPrimary)
                .frame(height: 30)
                .padding(.top, 33)

            Text(viewModel.guideText)
                .font(.system(size: Self.guideFontSize))
                .lineSpacing(2)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 260, height: 40, alignment: .topLeading)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .named(Self.space))
                    return CGPoint(x: frame.midX, y: frame.midY)
                } action: { guideCenter = $0 }
                // Hidden while the round alert shows it big instead.
                .opacity(isAlertCovering ? 0 : 1)
                .padding(.top, 6)

            Text(viewModel.roundText)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 53)

            ProgressPips(filled: viewModel.hits, total: viewModel.hitsToPass)
                .padding(.top, 20)
        }
        .frame(width: 280, alignment: .leading)
    }

    /// The alert is up and has not yet handed over to the guide line.
    private var isAlertCovering: Bool {
        (viewModel.roundAlert == .showing || viewModel.roundAlert == .settling) && !alertSettled
    }

    /// Round 2's alert: the screen dims and the new guide line shows big in
    /// the centre for one bar, then shrinks and glides into its place
    /// (with Reduce Motion it only fades). The drums keep playing.
    private var roundAlert: some View {
        let glide = alertSettled && !reduceMotion
        return ZStack {
            AppColor.background
                .opacity(isAlertCovering ? 0.75 : 0)
                .allowsHitTesting(false)

            if viewModel.roundAlert == .showing || viewModel.roundAlert == .settling {
                Text(viewModel.guideText)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: 520)
                    .scaleEffect(glide ? Self.guideFontSize / Self.alertFontSize : 1)
                    .offset(glide ? CGSize(width: guideCenter.x - screenSize.width / 2,
                                           height: guideCenter.y - screenSize.height / 2) : .zero)
                    .opacity(alertSettled ? 0 : 1)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.92)))
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    DoTwoView(viewModel: DoTwoViewModel(beatPlayer: BeatPlayer()), onNext: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
