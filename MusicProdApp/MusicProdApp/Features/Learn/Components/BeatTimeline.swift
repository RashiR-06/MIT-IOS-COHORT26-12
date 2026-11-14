import SwiftUI

/// Card 2's 4-second timeline for one speed (Figma "Lane · 60 BPM (4 s)"):
/// a dot per beat (bigger at each bar start) and a line every second.
/// While playing, a white line sweeps across in real time, played dots turn
/// white and the one just played lights cyan.
struct BeatTimeline: View {
    let bpm: Int
    /// Seconds into the play, or nil when not playing.
    let elapsed: TimeInterval?
    /// Played all the way through before: dots turn grey.
    let heard: Bool

    static let seconds = 4
    static let width: CGFloat = 520
    static let pointsPerSecond: CGFloat = 125
    /// Where 0 s sits inside the track.
    static let startX: CGFloat = 10
    /// How long a dot stays lit after its beat.
    private static let litSeconds: TimeInterval = 0.18

    var body: some View {
        Canvas { context, size in
            for second in 1..<Self.seconds {
                let x = Self.x(at: Double(second))
                context.fill(Path(CGRect(x: x, y: 0, width: 1, height: size.height)),
                             with: .color(AppColor.surfaceRaised))
            }
            let beats = bpm * Self.seconds / 60
            for beat in 0..<beats {
                let time = Double(beat) * 60 / Double(bpm)
                let since = elapsed.map { $0 - time }
                let lit = since.map { $0 >= 0 && $0 < Self.litSeconds } ?? false
                let played = since.map { $0 >= 0 } ?? false
                var diameter: CGFloat = beat % 4 == 0 ? 16 : 12
                if lit { diameter *= 1.375 }
                let color = lit ? AppColor.accentCyan
                    : played ? AppColor.textPrimary
                    : heard && elapsed == nil ? AppColor.textSecondary : AppColor.stroke
                let center = CGPoint(x: Self.x(at: time), y: size.height / 2 - 1)
                context.fill(Path(ellipseIn: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                                                    width: diameter, height: diameter)),
                             with: .color(color))
            }
            if let elapsed {
                context.fill(Path(CGRect(x: Self.x(at: elapsed) - 1, y: 0, width: 2, height: size.height)),
                             with: .color(AppColor.textPrimary))
            }
        }
        .frame(width: Self.width, height: 48)
        .background(AppColor.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppColor.stroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true)
    }

    static func x(at seconds: TimeInterval) -> CGFloat {
        startX + CGFloat(seconds) * pointsPerSecond
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 16) {
        BeatTimeline(bpm: 60, elapsed: nil, heard: true)
        BeatTimeline(bpm: 120, elapsed: 2.05, heard: false)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.surface)
}
