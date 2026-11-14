import Foundation
import Observation

/// Runs Do 2 "Find the 1": the learner presses Play, then taps only on
/// beat 1 of each bar. Round 1 lights the beats as a cue; round 2 is by
/// ear (FindTheOneRules). Taps are judged like Do 1: the touch's own
/// timestamp, turned into what the learner was hearing on the audio clock.
@Observable
final class DoTwoViewModel {
    private(set) var hits = 0
    /// The last judged tap, for the message and the mark under a tile.
    private(set) var lastTap: FindTheOneResult?
    /// True after a tap while the drums were not playing: the pad says
    /// "Press play first" and the Play button gets a ring.
    private(set) var needsPlay = false
    private(set) var isComplete = false
    /// The alert shown when round 2 starts (see RoundAlert).
    private(set) var roundAlert = RoundAlert.hidden

    @ObservationIgnored private let beatPlayer: any BeatPlaying
    /// The beats (from the loop's start) at which the alert shows and at
    /// which it starts settling.
    @ObservationIgnored private var roundAlertStartBeat = 0
    @ObservationIgnored private var roundAlertEndBeat = 0

    init(beatPlayer: any BeatPlaying) {
        self.beatPlayer = beatPlayer
    }

    var isPlaying: Bool { beatPlayer.isLooping && !beatPlayer.isPaused }
    var hitsToPass: Int { FindTheOneRules.hitsToPass }
    var round: Int { FindTheOneRules.round(afterHits: hits) }
    /// The round the screen shows: round 2's words and no lights only
    /// appear with the alert, not during the pause before it.
    private var shownRound: Int { roundAlert == .pending ? 1 : round }

    var guideText: String {
        shownRound == 1 ? "Count along with the lights and tap when 1 comes round."
                   : "Now without the lights. Count it in your head."
    }

    var roundText: String {
        shownRound == 1 ? "Round 1 of 2 · with lights" : "Round 2 of 2 · by ear"
    }

    /// The lit tile in round 1, following the audio clock's playhead. Nil
    /// when nothing should light (round 2, paused, stopped or finished).
    var light: (tile: Int, level: Double)? {
        guard shownRound == 1, isPlaying, !isComplete, let beats = beatPlayer.playheadBeats, beats >= 0 else { return nil }
        return FindTheOneRules.light(atBeats: beats)
    }

    /// The mark under a tile after the last tap: ✓ under 1 for a hit,
    /// otherwise × under the beat that was tapped.
    var tileMark: CountTileMark? {
        guard let tap = lastTap else { return nil }
        return CountTileMark(tile: tap.beatInBar, isHit: tap.isHit)
    }

    /// What the pad shows, from the Figma frames G · 2a–c and the mockup.
    var padMessage: PadMessage {
        if isComplete {
            return PadMessage(symbol: "checkmark", title: "You found the one",
                              detail: "By ear, too. Nice counting.", tone: .good)
        }
        if needsPlay { return .pressPlayFirst }
        guard let tap = lastTap else {
            return PadMessage(symbol: "hand.point.up.left", title: "Tap here", detail: "only on beat 1", tone: .plain)
        }
        if tap.isHit {
            return PadMessage(symbol: "checkmark", title: "Beat 1", detail: "Right on the one", tone: .good)
        }
        if tap.beatInBar == 0 {
            return tap.offset < 0
                ? PadMessage(symbol: "arrow.left", title: "Early for beat 1 by \(tap.milliseconds) ms",
                             detail: "Wait a little longer", tone: .bad)
                : PadMessage(symbol: "arrow.right", title: "Late for beat 1 by \(tap.milliseconds) ms",
                             detail: "Tap a little sooner", tone: .bad)
        }
        return PadMessage(symbol: "xmark", title: "That was beat \(tap.beatInBar + 1)",
                          detail: "Let it pass and wait for 1", tone: .bad)
    }

    /// The screen has appeared. Nothing autoplays: start fresh and get the
    /// audio ready so the first beat is on time.
    func enter() {
        reset()
        beatPlayer.stop()
        beatPlayer.onStep = { [weak self] _ in self?.stepPlayed() }
        beatPlayer.resetDrumEffects()
        beatPlayer.prepare()
    }

    /// Pause freezes the drums and Play carries on from the same spot. If
    /// the drums are stopped they start again from beat 1 of a new bar.
    func togglePlayPause() {
        needsPlay = false
        if beatPlayer.isPaused {
            beatPlayer.resume()
        } else if beatPlayer.isLooping {
            beatPlayer.pause()
        } else {
            // A fresh loop: an alert left over from an interruption goes.
            roundAlert = .hidden
            beatPlayer.startLoop(.lessonGroove, bpm: FindTheOneRules.bpm)
        }
    }

    /// A finger landed on the pad. `uptime` is the touch's timestamp.
    func tap(at uptime: TimeInterval) {
        // Taps are paused while the round alert is up.
        guard !isComplete, roundAlert == .hidden else { return }
        guard isPlaying else {
            needsPlay = true
            return
        }
        // Nil only in the instant before the first audio is rendered.
        guard let heard = beatPlayer.loopSeconds(heardAt: uptime) else { return }

        let result = FindTheOneRules.judge(loopSeconds: heard)
        lastTap = result
        guard result.isHit else { return }
        hits += 1
        if hits == FindTheOneRules.hitsPerRound {
            // Round 2 starts: after a beat, alert the learner until the next
            // beat 1. The drums go on.
            roundAlert = .pending
            roundAlertStartBeat = result.beat + FindTheOneRules.roundAlertDelayBeats
            roundAlertEndBeat = result.beat + FindTheOneRules.roundAlertEndBeats
        }
        if hits >= hitsToPass {
            isComplete = true
            beatPlayer.stop()
        }
    }

    /// The alert has finished gliding into place.
    func roundAlertDidSettle() {
        roundAlert = .hidden
    }

    /// Leaving Do 2: stop the drums.
    func leave() {
        beatPlayer.onStep = nil
        beatPlayer.stop()
        reset()
    }

    /// Called by the audio engine every time a step plays. The alert's
    /// timing follows the loop's own time on the audio clock.
    private func stepPlayed() {
        guard let seconds = beatPlayer.currentStepSeconds else { return }
        let beats = seconds / BeatTiming.beatDuration(bpm: FindTheOneRules.bpm) + 0.01
        if roundAlert == .pending, beats >= Double(roundAlertStartBeat) {
            roundAlert = .showing
        } else if roundAlert == .showing, beats >= Double(roundAlertEndBeat) {
            roundAlert = .settling
        }
    }

    private func reset() {
        hits = 0
        lastTap = nil
        needsPlay = false
        isComplete = false
        roundAlert = .hidden
    }
}

/// The round-2 alert: the guide line shows big in the centre, then glides
/// back into its place.
enum RoundAlert {
    case hidden
    /// Waiting a beat after the ✓ before showing; taps paused.
    case pending
    /// Big in the centre, screen dimmed, taps paused.
    case showing
    /// Gliding back into the guide line.
    case settling
}
