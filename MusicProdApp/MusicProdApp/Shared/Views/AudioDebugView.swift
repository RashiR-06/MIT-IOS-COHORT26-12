import SwiftUI

/// Temporary screen for testing the drum sounds and the loop on a phone.
/// Opened from the "Audio test" button when DebugFlags.showAudioDebug is true.
struct AudioDebugView: View {
    let beatPlayer: any BeatPlaying
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 16) {
                PrimaryButton(title: "Kick") { beatPlayer.play(.kick) }
                PrimaryButton(title: "Snare") { beatPlayer.play(.snare) }
                PrimaryButton(title: "Hat") { beatPlayer.play(.hatClosed) }
                PrimaryButton(title: beatPlayer.isLooping ? "Stop loop" : "Play loop") {
                    if beatPlayer.isLooping {
                        beatPlayer.stop()
                    } else {
                        beatPlayer.startLoop(.lessonGroove, bpm: 100)
                    }
                }
            }

            // One dot per step; the lit dot is the step being heard.
            HStack(spacing: 12) {
                ForEach(0..<DrumPattern.lessonGroove.steps.count, id: \.self) { step in
                    Circle()
                        .fill(step == beatPlayer.currentStep ? AppColor.accentCyan : AppColor.stroke)
                        .frame(width: 20, height: 20)
                }
            }

            Text("Output latency: \(Int(beatPlayer.outputLatency * 1000)) ms")
                .font(.headline)
                .foregroundStyle(AppColor.textSecondary)
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
        // Audio starts here, not at app launch.
        .onAppear { beatPlayer.prepare() }
    }
}

#Preview(traits: .landscapeLeft) {
    AudioDebugView(beatPlayer: BeatPlayer())
}
