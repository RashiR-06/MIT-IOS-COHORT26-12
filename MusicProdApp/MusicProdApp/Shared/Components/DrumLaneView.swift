import SwiftUI

/// Sizes for one look of the drum lane. The three looks come from the
/// Lesson 1.1 Figma frames: Intro "Stage · Drums", Do "Drums (scrolls under
/// fixed playhead)" and the Finale "Lanes". All numbers are in points.
struct DrumLaneStyle {
    let height: CGFloat
    let pointsPerBeat: CGFloat
    let playheadX: CGFloat
    let playheadTop: CGFloat
    let showsPlayheadKnob: Bool

    // The clip (rounded box). One clip is 8 beats long.
    let clipTop: CGFloat
    let clipHeight: CGFloat
    let clipCornerRadius: CGFloat
    let clipGap: CGFloat

    // The sticky label inside the clip.
    let labelFont: Font
    let labelInset: CGFloat
    let labelCenterY: CGFloat
    /// Room kept at the clip's right end so the label never overflows it.
    let labelRoom: CGFloat

    // Markers. Y values are from the top of the lane.
    let markerOffset: CGFloat
    let hatCenterY: CGFloat
    let hatSize: CGFloat
    let crossingHatSize: CGFloat
    let snareTop: CGFloat
    let snareHeight: CGFloat
    let crossingSnareTop: CGFloat
    let crossingSnareHeight: CGFloat
    let kickTop: CGFloat
    let kickHeight: CGFloat
    let crossingKickTop: CGFloat
    let crossingKickHeight: CGFloat
    let beatLineTop: CGFloat
    let beatLineHeight: CGFloat
    let barLineHeight: CGFloat
    let pastBeatLineOpacity: Double
    let upcomingBeatLineOpacity: Double
    /// How far past the playhead a note still counts as "just crossed"
    /// (drawn bigger and fully bright). 0 turns this off.
    let crossingWindow: CGFloat

    /// Intro: the big full-width stage (Figma E · 1–3).
    static let intro = DrumLaneStyle(
        height: 174, pointsPerBeat: 120, playheadX: 120, playheadTop: 8, showsPlayheadKnob: true,
        clipTop: 22, clipHeight: 150, clipCornerRadius: 12, clipGap: 8,
        labelFont: .system(size: 16, weight: .medium), labelInset: 16, labelCenterY: 42.5, labelRoom: 90,
        markerOffset: 4, hatCenterY: 76, hatSize: 3.4, crossingHatSize: 4.8,
        snareTop: 109, snareHeight: 10, crossingSnareTop: 106, crossingSnareHeight: 16,
        kickTop: 141, kickHeight: 14, crossingKickTop: 138, crossingKickHeight: 20,
        beatLineTop: 68, beatLineHeight: 26, barLineHeight: 40,
        pastBeatLineOpacity: 0.35, upcomingBeatLineOpacity: 0.7, crossingWindow: 22
    )

    /// Do: the compact lane in the right column (Figma G · 1a–c).
    static let practice = DrumLaneStyle(
        height: 84, pointsPerBeat: 90, playheadX: 70, playheadTop: 0, showsPlayheadKnob: false,
        clipTop: 4, clipHeight: 74, clipCornerRadius: 10, clipGap: 6,
        labelFont: .system(size: 13, weight: .semibold), labelInset: 12, labelCenterY: 17, labelRoom: 70,
        markerOffset: 3, hatCenterY: 35.1, hatSize: 3, crossingHatSize: 4.4,
        snareTop: 47.8, snareHeight: 10, crossingSnareTop: 47.8, crossingSnareHeight: 10,
        kickTop: 60.6, kickHeight: 14, crossingKickTop: 60.6, crossingKickHeight: 14,
        beatLineTop: 27.1, beatLineHeight: 22.2, barLineHeight: 37,
        pastBeatLineOpacity: 0.3, upcomingBeatLineOpacity: 0.6, crossingWindow: 16
    )

    /// Finale: one of the two thin stacked lanes (Figma H · 1–6).
    static let finale = DrumLaneStyle(
        height: 58, pointsPerBeat: 90, playheadX: 70, playheadTop: 0, showsPlayheadKnob: false,
        clipTop: 0, clipHeight: 58, clipCornerRadius: 10, clipGap: 6,
        labelFont: .system(size: 12, weight: .semibold), labelInset: 10, labelCenterY: 11, labelRoom: 170,
        markerOffset: 3, hatCenterY: 26.1, hatSize: 2.8, crossingHatSize: 2.8,
        snareTop: 35.4, snareHeight: 8, crossingSnareTop: 35.4, crossingSnareHeight: 8,
        kickTop: 44.9, kickHeight: 10, crossingKickTop: 44.9, crossingKickHeight: 10,
        beatLineTop: 20.1, beatLineHeight: 17.4, barLineHeight: 29,
        pastBeatLineOpacity: 0.3, upcomingBeatLineOpacity: 0.6, crossingWindow: 0
    )
}

/// A drum pattern scrolling right-to-left under a fixed playhead.
/// Hi-hats are dots, snares and kicks are bars, with a line on every beat
/// and a taller line at each bar. It only draws what it is given: the
/// pattern, where the playhead is (in beats) and how it should look.
struct DrumLaneView: View {
    let pattern: DrumPattern
    /// Playhead position in beats, for example BeatPlaying.playheadBeats.
    let position: Double
    var style: DrumLaneStyle = .practice
    var tint: Color = AppColor.accentCyan
    var label: String = "Drums"

    /// Each clip (rounded box) is 2 bars of 4 beats.
    private static let beatsPerClip = 8

    var body: some View {
        Canvas { context, size in
            drawClips(in: &context, size: size)
            drawPlayhead(in: &context, size: size)
        }
        .frame(height: style.height)
        // Clips scroll in and out at the lane's edges.
        .clipped()
        .accessibilityElement()
        .accessibilityLabel("\(label) lane")
    }

    // MARK: - Drawing

    private func drawClips(in context: inout GraphicsContext, size: CGSize) {
        let beatWidth = style.pointsPerBeat
        let clipBeats = Double(Self.beatsPerClip)
        // Only the clips that can be on screen.
        let first = Int(floor((position - style.playheadX / beatWidth) / clipBeats)) - 1
        let last = Int(ceil((position + (size.width - style.playheadX) / beatWidth) / clipBeats)) + 1

        for clip in max(first, 0)...max(last, 0) {
            let clipX = style.playheadX + (Double(clip) * clipBeats - position) * beatWidth
            let clipWidth = clipBeats * beatWidth - style.clipGap
            guard clipX < size.width, clipX + clipWidth > 0 else { continue }

            let box = Path(roundedRect: CGRect(x: clipX, y: style.clipTop, width: clipWidth, height: style.clipHeight),
                           cornerRadius: style.clipCornerRadius)
            context.fill(box, with: .color(tint.opacity(0.13)))
            context.stroke(box, with: .color(tint), lineWidth: 1.5)

            // Everything inside the clip is cut off at its rounded edge.
            context.drawLayer { inside in
                inside.clip(to: box)
                drawLabel(in: &inside, clipX: clipX, clipWidth: clipWidth)
                drawBeatLines(in: &inside, clipX: clipX)
                drawNotes(in: &inside, clipX: clipX)
            }
        }
    }

    /// The label sticks to the left edge while its clip scrolls past.
    private func drawLabel(in context: inout GraphicsContext, clipX: CGFloat, clipWidth: CGFloat) {
        let x = min(max(clipX + style.labelInset, style.labelInset), clipX + clipWidth - style.labelRoom)
        let text = Text(label).font(style.labelFont).foregroundStyle(tint)
        context.draw(text, at: CGPoint(x: x, y: style.labelCenterY), anchor: .leading)
    }

    private func drawBeatLines(in context: inout GraphicsContext, clipX: CGFloat) {
        for beat in 1..<Self.beatsPerClip {
            let x = clipX + style.markerOffset + CGFloat(beat) * style.pointsPerBeat
            let isBar = beat % 4 == 0
            let height = isBar ? style.barLineHeight : style.beatLineHeight
            let opacity = x < style.playheadX ? style.pastBeatLineOpacity : style.upcomingBeatLineOpacity
            context.fill(Path(CGRect(x: x - 0.75, y: style.beatLineTop, width: 1.5, height: height)),
                         with: .color(AppColor.textPrimary.opacity(opacity)))
        }
    }

    private func drawNotes(in context: inout GraphicsContext, clipX: CGFloat) {
        let stepWidth = style.pointsPerBeat / CGFloat(pattern.stepsPerBeat)
        let stepsPerClip = Self.beatsPerClip * pattern.stepsPerBeat

        for step in 0..<stepsPerClip {
            let x = clipX + style.markerOffset + CGFloat(step) * stepWidth
            let played = x < style.playheadX
            let crossing = played && style.playheadX - x < style.crossingWindow
            let opacity = crossing ? 1 : (played ? 0.4 : 0.9)
            let color = GraphicsContext.Shading.color(AppColor.textPrimary.opacity(opacity))
            let sounds = pattern.steps[step % pattern.steps.count].map(\.sound)

            if sounds.contains(.hatClosed) {
                let size = crossing ? style.crossingHatSize : style.hatSize
                context.fill(Path(ellipseIn: CGRect(x: x - size / 2, y: style.hatCenterY - size / 2, width: size, height: size)),
                             with: color)
            }
            if sounds.contains(.snare) {
                let top = crossing ? style.crossingSnareTop : style.snareTop
                let height = crossing ? style.crossingSnareHeight : style.snareHeight
                context.fill(Path(CGRect(x: x - 1.5, y: top, width: 3, height: height)), with: color)
            }
            if sounds.contains(.kick) {
                let top = crossing ? style.crossingKickTop : style.kickTop
                let height = crossing ? style.crossingKickHeight : style.kickHeight
                context.fill(Path(CGRect(x: x - 2, y: top, width: 4, height: height)), with: color)
            }
        }
    }

    /// The fixed white playhead (with a knob on top in the Intro style).
    private func drawPlayhead(in context: inout GraphicsContext, size: CGSize) {
        let white = GraphicsContext.Shading.color(AppColor.textPrimary)
        context.fill(Path(CGRect(x: style.playheadX - 1, y: style.playheadTop,
                                 width: 2, height: size.height - style.playheadTop)), with: white)
        if style.showsPlayheadKnob {
            context.fill(Path(ellipseIn: CGRect(x: style.playheadX - 6, y: 2, width: 12, height: 12)), with: white)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 16) {
        DrumLaneView(pattern: .lessonGroove, position: 1.2, style: .intro, tint: AppColor.accentPink)
        DrumLaneView(pattern: .lessonGroove, position: 0.6, style: .practice)
        DrumLaneView(pattern: .lessonGroove, position: 0.6, style: .finale, label: "Original drums")
    }
    .padding(.horizontal, 59)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
