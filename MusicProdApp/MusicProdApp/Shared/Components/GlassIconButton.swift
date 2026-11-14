import SwiftUI

/// A round 50 pt Liquid Glass button showing an SF Symbol. Used for the
/// top bar's back and close, the tempo dial's − and +, and the Learn
/// cards' arrows (the forward one is cyan).
struct GlassIconButton: View {
    let systemImage: String
    let label: String
    var tint = AppColor.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}
