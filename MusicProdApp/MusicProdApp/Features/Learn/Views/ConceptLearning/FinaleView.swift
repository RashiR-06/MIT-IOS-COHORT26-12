import SwiftUI

/// The Lesson 1.1 Finale "Tap the tempo" under the top bar (Figma H · 1–5):
/// the task on the left, the original and your drums' lanes and the tap pad
/// on the right, Play / Pause and Set tempo or Redo along the bottom. The
/// "Lesson complete" pop-up (H · 6) is shown by the lesson shell. It only
/// draws the view model's state and forwards actions.
struct FinaleView: View {
    let viewModel: FinaleViewModel
    /// Called once your drums are back at the original tempo.
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 21) {
                instructions
                VStack(spacing: 10) {
                    lanes
                    pad
                }
                .padding(.top, 7)
            }

            Spacer(minLength: 8)

            HStack {
                TransportButton(isPlaying: viewModel.isPlaying, showsRing: viewModel.needsPlay,
                                action: viewModel.togglePlayPause)
                Spacer()
                if viewModel.showsSetTempo {
                    PrimaryButton(title: "Set tempo", action: viewModel.setTempo)
                } else if viewModel.showsRedo {
                    GlassTextButton(title: "Redo", action: viewModel.redo)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.stage)
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { onFinished() }
        }
        .onAppear { viewModel.enter() }
        .onDisappear { viewModel.leave() }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LESSON FINALE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(AppColor.accentCyan)
                .padding(.top, 17)
            Text(viewModel.title)
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(height: 30)
                .padding(.top, 4)
            Text(viewModel.guideText)
                .font(.system(size: 15))
                .lineSpacing(2)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 262, height: 40, alignment: .topLeading)
                .padding(.top, 10)
            HStack(spacing: 8) {
                Image(systemName: "smallcircle.filled.circle")
                    .font(.system(size: 14))
                Text("Within ±5 BPM brings your drums back")
                    .font(.system(size: 13))
            }
            .foregroundStyle(AppColor.textSecondary)
            .padding(.top, 62)
        }
        .frame(width: 270, alignment: .leading)
    }

    /// Both lanes, redrawn every screen refresh while playing; the playing
    /// lane's position comes from the audio clock.
    private var lanes: some View {
        TimelineView(.animation(paused: !viewModel.isPlaying)) { _ in
            VStack(spacing: 4) {
                DrumLaneView(pattern: .lessonGroove, position: viewModel.originalPosition,
                             style: .finale, label: "Original drums")
                DrumLaneView(pattern: .lessonGroove, position: viewModel.yoursPosition, style: .finale,
                             tint: AppColor.accentPink.mix(with: AppColor.accentCyan, by: viewModel.rampProgress),
                             label: viewModel.yoursLabel)
            }
        }
        // One playhead line through both lanes, as in Figma.
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppColor.textPrimary)
                .frame(width: 2)
                .offset(x: DrumLaneStyle.finale.playheadX - 1)
        }
        .frame(height: 120)
    }

    @ViewBuilder private var pad: some View {
        let border = viewModel.padBorder?.titleColor
        switch viewModel.pad {
        case .message(let message):
            TapPadView(message: message, height: 104, border: border, spacing: 6,
                       onTouchDown: viewModel.tap(at:))
        case .reading(let bpm, let detail):
            TapPadView(height: 104, border: border,
                       accessibilityLabel: "\(bpm) BPM from your taps. \(detail)",
                       onTouchDown: viewModel.tap(at:)) {
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(bpm)")
                            .font(.system(size: 32, weight: .bold))
                            .tracking(-1)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("BPM from your taps")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    FinaleView(viewModel: FinaleViewModel(beatPlayer: BeatPlayer()), onFinished: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
