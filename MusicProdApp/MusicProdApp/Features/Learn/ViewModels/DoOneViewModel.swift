import Foundation
import Observation

/// Runs Do 1 "Tap the pulse": the learner presses Play, then taps the pad
/// on every beat until 8 taps land on the beat (TapThePulseRules). Each tap
/// is judged on the audio clock, using the touch's own timestamp, against
/// what the learner was hearing at that moment.
@Observable
final class DoOneViewModel {
    private(set) var hits = 0
    /// The last judged tap, for the message and the Early / Late scale.
    private(set) var lastTap: TapResult?
    /// True after a tap while the drums were not playing: the pad says
    /// "Press play first" and the Play button gets a ring.
    private(set) var needsPlay = false
    private(set) var isComplete = false
    /// Every tap, drawn on the lane where it landed.
    private(set) var tapMarks: [LaneTapMark] = []

    @ObservationIgnored private let beatPlayer: any BeatPlaying
    /// Where the lane rests while the drums are stopped.
    @ObservationIgnored private var restingPosition = 0.0
    private static let maxTapMarks = 30

    init(beatPlayer: any BeatPlaying) {
        self.beatPlayer = beatPlayer
    }

    var isPlaying: Bool { beatPlayer.isLooping && !beatPlayer.isPaused }
    var lanePosition: Double { beatPlayer.playheadBeats ?? restingPosition }
    var hitsToPass: Int { TapThePulseRules.hitsToPass }
    var countText: String { "\(hits) of \(hitsToPass) on the beat" }

    /// What the pad shows, from the Figma frames G · 1a–c and the mockup.
    var padMessage: PadMessage {
        if isComplete {
            return PadMessage(symbol: "checkmark", title: "\(hitsToPass) on the beat",
                              detail: "Nice timing. You found the pulse.", tone: .good)
        }
        if needsPlay {
            return PadMessage(symbol: "play.fill", title: "Press play first",
                              detail: "The drums start when you press play", tone: .muted)
        }
        guard let tap = lastTap else {
            return PadMessage(symbol: "hand.point.up.left", title: "Tap here", detail: "on every beat", tone: .plain)
        }
        switch tap.direction {
        case .onTime:
            let sign = tap.offset < 0 ? "−" : "+"
            return PadMessage(symbol: "checkmark", title: "On the beat",
                              detail: "\(sign)\(tap.milliseconds) ms", tone: .good)
        case .early:
            return PadMessage(symbol: "arrow.left", title: "Early by \(tap.milliseconds) ms",
                              detail: "Wait a little longer before tapping", tone: .bad)
        case .late:
            return PadMessage(symbol: "arrow.right", title: "Late by \(tap.milliseconds) ms",
                              detail: "Tap a little sooner", tone: .bad)
        }
    }

    /// The screen has appeared. Nothing autoplays (Figma G section note):
    /// start fresh and get the audio ready so the first beat is on time.
    func enter() {
        reset()
        beatPlayer.onStep = nil
        beatPlayer.stop()
        beatPlayer.resetDrumEffects()
        beatPlayer.prepare()
    }

    /// Pause freezes the drums and Play carries on from the same spot. If
    /// the drums are stopped (first press, after finishing, or after an
    /// interruption) they start again from beat 1.
    func togglePlayPause() {
        needsPlay = false
        if beatPlayer.isPaused {
            beatPlayer.resume()
        } else if beatPlayer.isLooping {
            beatPlayer.pause()
        } else {
            // A new loop starts at beat 0, so old marks would be misplaced.
            tapMarks = []
            restingPosition = 0
            beatPlayer.startLoop(.lessonGroove, bpm: TapThePulseRules.bpm)
        }
    }

    /// A finger landed on the pad. `uptime` is the touch's timestamp.
    func tap(at uptime: TimeInterval) {
        guard !isComplete else { return }
        guard isPlaying else {
            needsPlay = true
            return
        }
        // Nil only in the instant before the first audio is rendered.
        guard let heard = beatPlayer.loopSeconds(heardAt: uptime) else { return }

        let result = TapThePulseRules.judge(loopSeconds: heard)
        lastTap = result
        tapMarks.append(LaneTapMark(beats: heard / BeatTiming.beatDuration(bpm: TapThePulseRules.bpm),
                                    isOnTime: result.isHit))
        if tapMarks.count > Self.maxTapMarks { tapMarks.removeFirst() }

        guard result.isHit else { return }
        hits += 1
        if hits >= hitsToPass {
            isComplete = true
            // Stop the drums but keep the lane where it was, as in Figma 1c.
            restingPosition = beatPlayer.playheadBeats ?? restingPosition
            beatPlayer.stop()
        }
    }

    /// Leaving Do 1: stop the drums.
    func leave() {
        beatPlayer.stop()
        reset()
    }

    private func reset() {
        hits = 0
        lastTap = nil
        needsPlay = false
        isComplete = false
        tapMarks = []
        restingPosition = 0
    }
}

/// The pad's feedback: an icon and words, coloured by tone.
struct PadMessage: Equatable {
    enum Tone {
        /// White words, as before the first tap.
        case plain
        /// Cyan: on the beat or finished.
        case good
        /// Pink: early or late.
        case bad
        /// White words with a grey icon: "Press play first".
        case muted
    }

    let symbol: String
    let title: String
    let detail: String
    let tone: Tone
}
