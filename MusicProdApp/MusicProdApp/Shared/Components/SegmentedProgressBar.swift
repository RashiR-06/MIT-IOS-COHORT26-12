import SwiftUI

/// The 10-segment lesson progress bar. Segments 1 to `current` are cyan,
/// the rest are grey. Values outside 1...10 are clamped.
struct SegmentedProgressBar: View {
    static let segmentCount = 10

    let current: Int

    private var filledCount: Int {
        min(max(current, 1), Self.segmentCount)
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...Self.segmentCount, id: \.self) { segment in
                Capsule()
                    .fill(segment <= filledCount ? AppColor.accentCyan : AppColor.stroke)
                    .frame(width: 26, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(filledCount) of \(Self.segmentCount)")
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 16) {
        SegmentedProgressBar(current: 1)
        SegmentedProgressBar(current: 5)
        SegmentedProgressBar(current: 10)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
