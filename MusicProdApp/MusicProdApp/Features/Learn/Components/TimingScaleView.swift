import SwiftUI

/// The Early / Late scale under the tap pad's feedback (Figma "Timing
/// scale"): a line with the on-time window shaded around the beat tick in
/// the middle, and a dot for the last tap.
struct TimingScaleView: View {
    /// −1 (far left, early) to 1 (far right, late), 0 on the beat.
    let position: Double
    let isOnTime: Bool

    private let width: CGFloat = 240
    private let height: CGFloat = 16

    var body: some View {
        HStack(spacing: 10) {
            Text("Early")
            Canvas { context, size in
                let middle = size.width / 2
                // Line, then the ±100 ms window (96 pt of the 240), then the beat tick.
                context.fill(Path(CGRect(x: 0, y: 7, width: size.width, height: 2)), with: .color(AppColor.stroke))
                context.fill(Path(roundedRect: CGRect(x: middle - 48, y: 3, width: 96, height: 10), cornerRadius: 5),
                             with: .color(AppColor.accentCyan.opacity(0.2)))
                context.fill(Path(CGRect(x: middle - 1, y: 0, width: 2, height: size.height)),
                             with: .color(AppColor.textSecondary))
                let x = middle + position * middle
                context.fill(Path(ellipseIn: CGRect(x: x - 6, y: 2, width: 12, height: 12)),
                             with: .color(isOnTime ? AppColor.accentCyan : AppColor.accentPink))
            }
            .frame(width: width, height: height)
            .clipped()
            Text("Late")
        }
        .font(.system(size: 12))
        .foregroundStyle(AppColor.textSecondary)
        .accessibilityHidden(true)
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 20) {
        TimingScaleView(position: -0.56, isOnTime: false)
        TimingScaleView(position: -0.05, isOnTime: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
