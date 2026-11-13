import SwiftUI

/// The Intro screen under the top bar (Figma "E · Intro — The track breaks"):
/// one continuous screen whose text and buttons change with the IntroPhase.
/// It only draws the view model's state and forwards taps.
struct IntroView: View {
    let viewModel: IntroViewModel
    let onFixTheDrums: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.phase == .steady ? "Listen to the drums." : "Uh-oh! Something’s wrong with the drums.")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.6)
                .foregroundStyle(AppColor.textPrimary)
                .frame(height: 33)
                .padding(.top, 15)

            HStack(spacing: 5) {
                Text("Hear it drag?")
                    .foregroundStyle(AppColor.textSecondary)
                Text("Let’s learn tempo and BPM to rescue it.")
                    .foregroundStyle(AppColor.textPrimary)
                    .opacity(viewModel.phase == .crawl ? 1 : 0)
            }
            .font(.system(size: 15))
            .frame(height: 18)
            .padding(.top, 3)
            .opacity(viewModel.phase == .steady ? 0 : 1)

            // The lane runs edge to edge (past the safe area) to feel full;
            // its playhead and label are moved in by the safe-area width so
            // they stay inside it. Redrawn every screen refresh; the
            // position comes from the audio clock.
            GeometryReader { geometry in
                TimelineView(.animation(paused: !viewModel.isPlaying)) { _ in
                    DrumLaneView(pattern: .introGroove,
                                 position: viewModel.playheadBeats ?? 0,
                                 style: .intro,
                                 tint: AppColor.accentCyan.mix(with: AppColor.accentPink, by: viewModel.slowdownProgress),
                                 leadingInset: geometry.safeAreaInsets.leading)
                }
            }
            .ignoresSafeArea(edges: .horizontal)
            .frame(height: DrumLaneStyle.intro.height)
            .padding(.top, 8)

            Spacer(minLength: 11)

            HStack(spacing: 10) {
                TransportButton(isPlaying: viewModel.isPlaying, action: viewModel.togglePlayPause)
                if viewModel.phase == .crawl {
                    GlassTextButton(title: "Replay", action: viewModel.replay)
                }
                Spacer()
                if viewModel.phase == .crawl {
                    PrimaryButton(title: "Fix the drums", action: onFixTheDrums)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Text and buttons fade in, as in the mockup.
        .animation(.easeInOut(duration: 0.6), value: viewModel.phase)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.leave() }
    }
}
