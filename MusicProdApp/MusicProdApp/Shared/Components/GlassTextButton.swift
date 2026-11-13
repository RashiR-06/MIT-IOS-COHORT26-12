import SwiftUI

/// A Liquid Glass button with a text label (Figma "D/Btn Glass", for
/// example "Replay").
struct GlassTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}
