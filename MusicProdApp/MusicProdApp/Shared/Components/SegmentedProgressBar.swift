import SwiftUI

/// The segmented lesson progress bar. Segments 1 to `current` are cyan,
/// the rest are grey. Values outside 1...segmentCount are clamped.
struct SegmentedProgressBar: View {
    let current: Int
    let segmentCount: Int

    private var filledCount: Int {
        min(max(current, 1), segmentCount)
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...segmentCount, id: \.self) { segment in
                Capsule()
                    .fill(segment <= filledCount ? AppColor.accentCyan : AppColor.stroke)
                    .frame(width: 26, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(filledCount) of \(segmentCount)")
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 16) {
        SegmentedProgressBar(current: 1, segmentCount: 8)
        SegmentedProgressBar(current: 4, segmentCount: 8)
        SegmentedProgressBar(current: 8, segmentCount: 8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
