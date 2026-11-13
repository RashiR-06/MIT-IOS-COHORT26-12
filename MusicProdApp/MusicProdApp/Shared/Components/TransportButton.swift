import SwiftUI

/// The round cyan Play / Pause button (Figma "E/Transport · Play / Pause").
struct TransportButton: View {
    let isPlaying: Bool
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
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }
}

#Preview(traits: .landscapeLeft) {
    HStack(spacing: 20) {
        TransportButton(isPlaying: true) {}
        TransportButton(isPlaying: false) {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
