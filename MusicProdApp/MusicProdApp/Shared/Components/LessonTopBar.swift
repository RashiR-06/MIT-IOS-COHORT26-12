import SwiftUI

/// The lesson top bar (Figma "iOS/TopBar"): back, title, progress, close.
struct LessonTopBar: View {
    let title: String
    let currentSegment: Int
    let segmentCount: Int
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            GlassIconButton(systemImage: "chevron.backward", label: "Back", action: onBack)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .padding(.leading, 12)
            Spacer(minLength: 16)
            SegmentedProgressBar(current: currentSegment, segmentCount: segmentCount)
                .padding(.trailing, 16)
            GlassIconButton(systemImage: "xmark", label: "Close", action: onClose)
        }
        .frame(height: 50)
    }
}

/// A round 50 pt Liquid Glass button showing an SF Symbol.
private struct GlassIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

#Preview(traits: .landscapeLeft) {
    LessonTopBar(title: "1.1  Tempo and Beats", currentSegment: 3, segmentCount: 8, onBack: {}, onClose: {})
        .padding(.horizontal)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColor.background)
}
