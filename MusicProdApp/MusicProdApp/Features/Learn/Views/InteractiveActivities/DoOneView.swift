import SwiftUI

/// Do 1 "Tap the pulse" under the top bar (Figma G · 1a–c): instructions
/// and the hit count on the left, the drum lane and tap pad on the right,
/// Play / Pause bottom-left and Next once finished. It only draws the
/// view model's state and forwards touches.
struct DoOneView: View {
    let viewModel: DoOneViewModel
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 11) {
                instructions
                VStack(spacing: 19) {
                    lane
                    tapPad
                }
                .padding(.top, 23)
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
        .onAppear { viewModel.enter() }
        .onDisappear { viewModel.leave() }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tap on every beat.")
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(AppColor.textPrimary)
                .frame(height: 30)
                .padding(.top, 31)

            Text("Press play, then tap the pad in time with the drums.")
                .font(.system(size: 15))
                .lineSpacing(2)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 260, alignment: .leading)
                .padding(.top, 6)

            Text(viewModel.countText)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 58)

            ProgressPips(filled: viewModel.hits, total: viewModel.hitsToPass)
                .padding(.top, 20)
        }
        .frame(width: 280, alignment: .leading)
    }

    /// Redrawn every screen refresh while playing; the position comes from
    /// the audio clock.
    private var lane: some View {
        TimelineView(.animation(paused: !viewModel.isPlaying)) { _ in
            DrumLaneView(pattern: .lessonGroove,
                         position: viewModel.lanePosition,
                         style: .practice,
                         tapMarks: viewModel.tapMarks)
        }
        .frame(height: DrumLaneStyle.practice.height)
    }

    private var tapPad: some View {
        TapPadView(message: viewModel.padMessage, onTouchDown: viewModel.tap(at:)) {
            if let tap = viewModel.lastTap {
                TimingScaleView(position: tap.scalePosition, isOnTime: tap.isHit)
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    DoOneView(viewModel: DoOneViewModel(beatPlayer: BeatPlayer()), onNext: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
