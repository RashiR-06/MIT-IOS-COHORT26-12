import SwiftUI

/// Temporary screen for testing the drum sounds, the loop and live tempo
/// changes on a phone. Opened from the "Audio test" button when
/// DebugFlags.showAudioDebug is true.
struct AudioDebugView: View {
    let beatPlayer: any BeatPlaying
    @Environment(\.dismiss) private var dismiss
    @State private var bpm = 120
    @State private var showsZone = false

    var body: some View {
        HStack(spacing: 48) {
            TempoDial(bpm: $bpm, zone: showsZone ? 60...90 : nil)

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
                    Button {
                        showsZone.toggle()
                    } label: {
                        Text(showsZone ? "Hide zone" : "Show zone")
                            .font(.headline)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button {
                beatPlayer.stop()
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .padding(.top, 11)
        }
        .background(AppColor.background)
        // Moving the dial changes the loop's tempo live.
        .onChange(of: bpm) { _, newValue in
            beatPlayer.setTempo(Double(newValue))
        }
        // Audio starts here, not at app launch.
        .onAppear { beatPlayer.prepare() }
    }
}

#Preview(traits: .landscapeLeft) {
    AudioDebugView(beatPlayer: BeatPlayer())
}
