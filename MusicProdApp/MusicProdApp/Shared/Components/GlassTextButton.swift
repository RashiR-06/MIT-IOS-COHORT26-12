import SwiftUI

/// A Liquid Glass button with a text label (Figma "D/Btn Glass", for
/// example "Replay"), optionally with a cyan SF Symbol before it ("Hint").
struct GlassTextButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(AppColor.accentCyan)
                }
                Text(title)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .font(.headline)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}
