import SwiftUI

/// A row of short pips under an activity's count (Figma "Progress pip"):
/// the first `filled` are cyan, the rest grey.
struct ProgressPips: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index < filled ? AppColor.accentCyan : AppColor.stroke)
                    .frame(width: 22, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: filled)
        .accessibilityHidden(true)
    }
}

#Preview(traits: .landscapeLeft) {
    ProgressPips(filled: 5, total: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
