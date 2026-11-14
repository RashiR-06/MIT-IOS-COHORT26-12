import SwiftUI

/// A small, still picture of the tempo dial (Figma "Tempo control icon" on
/// the Lesson complete pop-up): the same 270° arc as TempoDial, filled up
/// to a tempo, with the number in the middle. Not interactive.
struct TempoGauge: View {
    let bpm: Int
    var range: ClosedRange<Int> = 40...160

    private static let size: CGFloat = 130
    private static let radius: CGFloat = 56.5
    private static let lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            arc(to: 1)
                .stroke(AppColor.surfaceRaised, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
            arc(to: TempoDial.fraction(for: bpm, in: range))
                .stroke(AppColor.accentCyan, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
            VStack(spacing: 0) {
                Text("\(bpm)")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(AppColor.textPrimary)
                Text("BPM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(width: Self.size, height: Self.size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bpm) BPM")
    }

    /// From the start of the arc (bottom-left) to a fraction of its 270°.
    private func arc(to fraction: Double) -> Path {
        Path { path in
            path.addArc(center: CGPoint(x: Self.size / 2, y: Self.size / 2), radius: Self.radius,
                        startAngle: .degrees(135), endAngle: .degrees(135 + 270 * fraction), clockwise: false)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    TempoGauge(bpm: 100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.surface)
}
