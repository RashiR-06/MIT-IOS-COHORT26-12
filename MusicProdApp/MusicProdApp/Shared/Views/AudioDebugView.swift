import SwiftUI

/// Temporary screen for testing the drum sounds, the loop, live tempo
/// changes and the drum lane on a phone. Opened from the "Audio test"
/// button when DebugFlags.showAudioDebug is true.
struct AudioDebugView: View {
    let beatPlayer: any BeatPlaying
    @Environment(\.dismiss) private var dismiss
    @State private var bpm = 120
    @State private var showsZone = false
    @State private var laneStyleIndex = 0

    /// The three lane looks from Figma, in the order the Style button cycles.
    private let laneStyles: [(name: String, style: DrumLaneStyle)] = [
        ("Do", .practice), ("Finale", .finale), ("Intro", .intro),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    GlassTextButton(title: "Style: \(laneStyles[laneStyleIndex].name)") {
                        laneStyleIndex = (laneStyleIndex + 1) % laneStyles.count
                    }
                    Spacer()
                    GlassTextButton(title: "Close") {
                        beatPlayer.stop()
                        dismiss()
                    }
                }

                // Redrawn every screen refresh; where it is comes from the
                // audio clock (playheadBeats), not from the refresh.
                TimelineView(.animation(paused: !beatPlayer.isLooping)) { _ in
                    DrumLaneView(pattern: .lessonGroove,
                                 position: beatPlayer.playheadBeats ?? 0,
                                 style: laneStyles[laneStyleIndex].style)
                }

                HStack(spacing: 48) {
                    TempoDial(bpm: $bpm, zone: showsZone ? 60...90 : nil)
                    controls
                }
            }
            .padding(.top, 11)
        }
        .background(AppColor.background)
        // Moving the dial changes the loop's tempo live.
        .onChange(of: bpm) { _, newValue in
            beatPlayer.setTempo(Double(newValue))
        }
        // Audio starts here, not at app launch. Anything another screen left
        // running (the Intro's loop and effects) is stopped and reset first.
        .onAppear {
            beatPlayer.onStep = nil
            beatPlayer.stop()
            beatPlayer.resetDrumEffects()
            beatPlayer.prepare()
        }
    }

    private var controls: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                PrimaryButton(title: "Kick") { beatPlayer.play(.kick) }
                PrimaryButton(title: "Snare") { beatPlayer.play(.snare) }
                PrimaryButton(title: "Hat") { beatPlayer.play(.hatClosed) }
            }
            HStack(spacing: 16) {
                PrimaryButton(title: beatPlayer.isLooping ? "Stop loop" : "Play loop") {
                    if beatPlayer.isLooping {
                        beatPlayer.stop()
                    } else {
                        beatPlayer.startLoop(.lessonGroove, bpm: Double(bpm))
                    }
                }
                GlassTextButton(title: showsZone ? "Hide zone" : "Show zone") {
                    showsZone.toggle()
                }
            }

            // One dot per step; the lit dot is the step being played.
            HStack(spacing: 12) {
                ForEach(0..<DrumPattern.lessonGroove.steps.count, id: \.self) { step in
                    Circle()
                        .fill(step == beatPlayer.currentStep ? AppColor.accentCyan : AppColor.stroke)
                        .frame(width: 20, height: 20)
                }
            }

            Text("Loop \(Int(beatPlayer.bpm)) BPM · Output latency \(Int(beatPlayer.outputLatency * 1000)) ms")
                .font(.headline)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    AudioDebugView(beatPlayer: BeatPlayer())
}
