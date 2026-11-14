import SwiftUI

/// The round cyan Play / Pause button (Figma "E/Transport · Play / Pause").
struct TransportButton: View {
    let isPlaying: Bool
    /// A faint cyan ring that draws the eye to Play, for example after the
    /// pad was tapped before the drums started.
    var showsRing = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.background)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(AppColor.accentCyan)
        .overlay {
            if showsRing {
                Circle()
                    .stroke(AppColor.accentCyan.opacity(0.35), lineWidth: 4)
                    .frame(width: 54, height: 54)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }
}

#Preview(traits: .landscapeLeft) {
    HStack(spacing: 20) {
        TransportButton(isPlaying: true) {}
        TransportButton(isPlaying: false) {}
        TransportButton(isPlaying: false, showsRing: true) {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
