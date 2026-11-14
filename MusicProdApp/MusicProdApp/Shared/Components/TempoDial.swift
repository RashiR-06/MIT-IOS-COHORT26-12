import SwiftUI

/// The tempo dial from Figma ("Tempo dial (drag)", Match the brief frames).
/// A 270° arc from bottom-left, over the top, to bottom-right. Drag anywhere
/// on it, or use − and +, to change the BPM. It only edits the binding;
/// whoever owns the binding decides what the tempo does.
struct TempoDial: View {
    @Binding var bpm: Int
    /// Optional highlighted zone, drawn outside the arc (for example 60...90).
    var zone: ClosedRange<Int>? = nil
    var range: ClosedRange<Int> = 40...160

    @Environment(\.isEnabled) private var isEnabled

    // Sizes from Figma, in points.
    private static let size: CGFloat = 240
    private static let arcRadius: CGFloat = 96
    private static let arcWidth: CGFloat = 12
    private static let zoneRadius: CGFloat = 112
    private static let zoneWidth: CGFloat = 5.4
    private static let knobSize: CGFloat = 26
    /// The arc starts at 135° (bottom-left) and covers 270°.
    private static let startAngle: Double = 135
    private static let sweep: Double = 270

    var body: some View {
        let center = Self.size / 2
        let valueFraction = Self.fraction(for: bpm, in: range)
        let knobAngle = Angle(degrees: Self.startAngle + valueFraction * Self.sweep)

        ZStack {
            // Grey track.
            arc(from: 0, to: 1, radius: Self.arcRadius)
                .stroke(AppColor.surfaceRaised, style: StrokeStyle(lineWidth: Self.arcWidth, lineCap: .round))

            // Zone, a dashed arc just outside the track (Figma: 5.4 pt, 4 on 4 off).
            if let zone {
                arc(from: Self.fraction(for: zone.lowerBound, in: range),
                    to: Self.fraction(for: zone.upperBound, in: range),
                    radius: Self.zoneRadius)
                    .stroke(AppColor.textPrimary, style: StrokeStyle(lineWidth: Self.zoneWidth, lineCap: .butt, dash: [4, 4]))
            }

            // Cyan arc from the lowest tempo up to the current one.
            arc(from: 0, to: valueFraction, radius: Self.arcRadius)
                .stroke(AppColor.accentCyan, style: StrokeStyle(lineWidth: Self.arcWidth, lineCap: .round))

            // White knob on the arc.
            Circle()
                .fill(AppColor.textPrimary)
                .frame(width: Self.knobSize, height: Self.knobSize)
                .position(x: center + Self.arcRadius * cos(knobAngle.radians),
                          y: center + Self.arcRadius * sin(knobAngle.radians))

            Text("\(bpm)")
                .font(.system(size: 58, weight: .bold))
                .tracking(-2)
                .foregroundStyle(AppColor.textPrimary)
                .position(x: center, y: 102.5)
            Text("BPM")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .position(x: center, y: 152.5)
        }
        .frame(width: Self.size, height: Self.size)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
            guard isEnabled else { return }
            setBPM(Self.bpm(at: drag.location, center: CGPoint(x: center, y: center), in: range))
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tempo")
        .accessibilityValue("\(bpm) BPM")
        .accessibilityAdjustableAction { direction in
            setBPM(direction == .increment ? bpm + 1 : bpm - 1)
        }
        // − and + sit in the gap at the bottom of the arc, as in Figma.
        .overlay {
            GlassIconButton(systemImage: "minus", label: "Slower") { setBPM(bpm - 1) }
                .position(x: 86, y: 216)
            GlassIconButton(systemImage: "plus", label: "Faster") { setBPM(bpm + 1) }
                .position(x: 154, y: 216)
        }
        .frame(width: Self.size, height: Self.size)
    }

    private func setBPM(_ value: Int) {
        bpm = min(max(value, range.lowerBound), range.upperBound)
    }

    /// Part of the dial's circle, from one fraction of the 270° sweep to another.
    private func arc(from start: Double, to end: Double, radius: CGFloat) -> Path {
        Path { path in
            path.addArc(center: CGPoint(x: Self.size / 2, y: Self.size / 2),
                        radius: radius,
                        startAngle: .degrees(Self.startAngle + start * Self.sweep),
                        endAngle: .degrees(Self.startAngle + end * Self.sweep),
                        clockwise: false)
        }
    }

    // MARK: - Maths (plain functions, easy to unit test)

    /// How far along the arc a BPM sits: 0 at the lowest, 1 at the highest.
    static func fraction(for bpm: Int, in range: ClosedRange<Int>) -> Double {
        let span = Double(range.upperBound - range.lowerBound)
        return min(max(Double(bpm - range.lowerBound) / span, 0), 1)
    }

    /// The BPM for a touch point. Touches in the gap at the bottom snap to
    /// whichever end is nearer, as in the mockup.
    static func bpm(at point: CGPoint, center: CGPoint, in range: ClosedRange<Int>) -> Int {
        var degrees = atan2(point.y - center.y, point.x - center.x) * 180 / .pi
        degrees = (degrees + 360).truncatingRemainder(dividingBy: 360)
        var along = (degrees - startAngle + 360).truncatingRemainder(dividingBy: 360)
        if along > sweep {
            along = along > (sweep + 360) / 2 ? 0 : sweep
        }
        let span = Double(range.upperBound - range.lowerBound)
        return range.lowerBound + Int((along / sweep * span).rounded())
    }
}

#Preview(traits: .landscapeLeft) {
    @Previewable @State var bpm = 120
    HStack(spacing: 40) {
        TempoDial(bpm: $bpm)
        TempoDial(bpm: .constant(104), zone: 60...90)
        TempoDial(bpm: .constant(76), zone: 60...90)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
