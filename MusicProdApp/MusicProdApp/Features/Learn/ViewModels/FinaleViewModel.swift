import Foundation
import Observation

/// Runs the Lesson 1.1 Finale "Tap the tempo" (Figma H · 1–6): the learner
/// plays the original drums and taps along; Set tempo checks the tapped
/// tempo. Within ±5 BPM, your drums start at the Intro's dull crawl and
/// speed back up to 100 while the dull sound clears, then the "Lesson
/// complete" pop-up shows. Taps and the ramp both follow the audio clock.
@Observable
final class FinaleViewModel {
    enum Stage: Equatable {
        /// Tapping along to the original drums.
        case tapping
        /// Set tempo missed: shows the result and Redo.
        case missed(bpm: Int, result: FinaleResult)
        /// Your drums are back and speeding up.
        case passed(bpm: Int)
    }

    private(set) var stage = Stage.tapping
    /// Tap times on the loop's audio clock (seconds), most recent last.
    private(set) var tapTimes: [TimeInterval] = []
    /// The tempo from the taps, once there are enough of them.
    private(set) var reading: Int?
    /// True after a tap while the drums were not playing.
    private(set) var needsPlay = false
    /// Your drums' tempo: the crawl, then rising during the ramp.
    private(set) var yourBPM = FinaleRules.crawlBPM
    /// 0 → 1 across the ramp; the your-drums lane fades pink → cyan with it.
    private(set) var rampProgress = 0.0
    /// The ramp and the wait are over: time for the pop-up.
    private(set) var isFinished = false

    @ObservationIgnored private let beatPlayer: any BeatPlaying
    /// Where each lane rests while its drums are not playing.
    @ObservationIgnored private var originalRest = 0.0
    @ObservationIgnored private var yoursRest = 0.0
    /// Seconds added to your drums' loop time: set to the full ramp if your
    /// drums had to restart (after an interruption), so they don't ramp again.
    @ObservationIgnored private var rampOffset: TimeInterval = 0

    init(beatPlayer: any BeatPlaying) {
        self.beatPlayer = beatPlayer
    }

    var isPlaying: Bool { beatPlayer.isLooping && !beatPlayer.isPaused }
    var hasPassed: Bool { if case .passed = stage { true } else { false } }

    var title: String { hasPassed ? "Your drums are back." : "Tap the original tempo." }
    var guideText: String {
        hasPassed ? "Your tempo landed within 5 BPM of the original."
                  : "Play the original drums and tap along on every beat to rescue yours."
    }

    // MARK: Lanes

    /// The playing lane follows the audio clock; the other rests.
    var originalPosition: Double { hasPassed ? originalRest : beatPlayer.playheadBeats ?? originalRest }
    var yoursPosition: Double { hasPassed ? beatPlayer.playheadBeats ?? yoursRest : yoursRest }
    var yoursLabel: String {
        hasPassed ? "Your drums · \(Int(yourBPM.rounded())) BPM" : "Your drums · 52 BPM, broken"
    }

    // MARK: Pad

    /// What the pad shows (Figma H · 1–5 and the mockup).
    var pad: FinalePad {
        switch stage {
        case .passed(let bpm):
            return .message(PadMessage(symbol: "checkmark", title: "Back to the original tempo",
                                       detail: "You tapped \(bpm) BPM. Hear them come back to life.", tone: .good))
        case .missed(let bpm, let result):
            let fast: Bool
            let by: Int
            switch result {
            case .tooFast(let n): (fast, by) = (true, n)
            case .tooSlow(let n): (fast, by) = (false, n)
            case .pass: (fast, by) = (false, 0)
            }
            return .message(PadMessage(
                symbol: fast ? "arrow.down" : "arrow.up",
                title: "\(bpm) BPM · \(by) too \(fast ? "fast" : "slow")",
                detail: "You need to be within 5 BPM. Listen again and tap a little \(fast ? "slower." : "quicker.")",
                tone: .bad))
        case .tapping:
            if needsPlay {
                return .message(PadMessage(symbol: "play.fill", title: "Press play first",
                                           detail: "The original drums start when you press play", tone: .muted))
            }
            if let reading {
                let detail = tapTimes.count >= FinaleRules.tapsForSet
                    ? "Happy with it? Set the tempo on your drums."
                    : "Keep tapping · \(tapTimes.count) of \(FinaleRules.tapsForSet)"
                return .reading(bpm: reading, detail: detail)
            }
            if tapTimes.isEmpty {
                return .message(PadMessage(symbol: "hand.point.up.left", title: "Tap along here",
                                           detail: "on every beat of the original", tone: .plain))
            }
            return .message(PadMessage(symbol: nil, title: "Keep tapping…",
                                       detail: "\(tapTimes.count) taps · keep them steady", tone: .plain))
        }
    }

    /// The pad's border: pink after a miss, cyan once passed.
    var padBorder: PadMessage.Tone? {
        switch stage {
        case .tapping: nil
        case .missed: .bad
        case .passed: .good
        }
    }

    var showsSetTempo: Bool {
        stage == .tapping && reading != nil && tapTimes.count >= FinaleRules.tapsForSet
    }
    var showsRedo: Bool { if case .missed = stage { true } else { false } }

    // MARK: Actions

    /// The screen has appeared. Nothing autoplays: start fresh.
    func enter() {
        beatPlayer.onStep = nil
        beatPlayer.stop()
        beatPlayer.resetDrumEffects()
        beatPlayer.setTempo(TempoLimits.normal)
        reset()
        beatPlayer.prepare()
    }

    /// Pause freezes whichever drums are playing and Play carries on. If
    /// nothing is playing, Play starts the original drums, or your drums at
    /// 100 once passed (as in the mockup).
    func togglePlayPause() {
        needsPlay = false
        if beatPlayer.isPaused {
            beatPlayer.resume()
        } else if beatPlayer.isLooping {
            beatPlayer.pause()
        } else if hasPassed {
            // Restarted after the pass: no second ramp.
            rampOffset = FinaleRules.rampSeconds
            beatPlayer.resetDrumEffects()
            beatPlayer.onStep = { [weak self] _ in self?.yourStepPlayed() }
            beatPlayer.startLoop(.lessonGroove, bpm: Double(FinaleRules.targetBPM))
        } else {
            beatPlayer.onStep = nil
            beatPlayer.startLoop(.lessonGroove, bpm: Double(FinaleRules.targetBPM))
        }
    }

    /// A finger landed on the pad. `uptime` is the touch's timestamp.
    func tap(at uptime: TimeInterval) {
        guard stage == .tapping else { return }
        guard isPlaying else {
            needsPlay = true
            return
        }
        // On the audio clock, like the Do screens. Nil only in the instant
        // before the first audio is rendered.
        guard let heard = beatPlayer.loopSeconds(heardAt: uptime) else { return }
        if let last = tapTimes.last, heard - last > FinaleRules.resetGap {
            tapTimes = []
        }
        tapTimes.append(heard)
        if tapTimes.count > FinaleRules.maxTaps { tapTimes.removeFirst() }
        reading = tapTimes.count >= FinaleRules.tapsForReading
            ? TapTempo.bpm(fromTapTimes: tapTimes, limits: FinaleRules.readingLimits)
            : nil
    }

    /// Set tempo: pass brings your drums back; otherwise show the miss.
    func setTempo() {
        guard let reading else { return }
        let result = FinaleRules.judge(bpm: reading)
        guard result == .pass else {
            stage = .missed(bpm: reading, result: result)
            return
        }
        stage = .passed(bpm: reading)
        // The original stops where it is; your drums start at the crawl with
        // the Intro's dull sound and speed back up on the audio clock.
        originalRest = beatPlayer.playheadBeats ?? originalRest
        beatPlayer.stop()
        rampOffset = 0
        yourBPM = FinaleRules.crawlBPM
        rampProgress = 0
        beatPlayer.setDrumEffects(pitchRatio: IntroTiming.pitchRatio(bpm: FinaleRules.crawlBPM),
                                  lowPassCutoff: IntroTiming.cutoff(closedness: 1))
        beatPlayer.onStep = { [weak self] _ in self?.yourStepPlayed() }
        beatPlayer.startLoop(.lessonGroove, bpm: FinaleRules.crawlBPM)
    }

    /// Redo: start tapping again; the original keeps playing.
    func redo() {
        stage = .tapping
        tapTimes = []
        reading = nil
    }

    /// Leaving the Finale: stop and put tempo, pitch and filter back.
    func leave() {
        beatPlayer.onStep = nil
        beatPlayer.stop()
        beatPlayer.resetDrumEffects()
        beatPlayer.setTempo(TempoLimits.normal)
        reset()
    }

    /// Called by the audio engine every time a step of your drums plays:
    /// tempo, pitch and filter for that step's moment, then the pop-up.
    private func yourStepPlayed() {
        guard hasPassed, !isFinished, let loopSeconds = beatPlayer.currentStepSeconds else { return }
        let seconds = loopSeconds + rampOffset
        let progress = FinaleRules.rampProgress(at: seconds)
        if rampProgress < 1 {
            let bpm = FinaleRules.rampBPM(progress: progress)
            beatPlayer.setTempo(bpm)
            if progress < 1 {
                beatPlayer.setDrumEffects(pitchRatio: IntroTiming.pitchRatio(bpm: bpm),
                                          lowPassCutoff: IntroTiming.cutoff(closedness: 1 - progress))
            } else {
                beatPlayer.resetDrumEffects()
            }
            yourBPM = bpm
            rampProgress = progress
        }
        if seconds >= FinaleRules.popupDelay {
            yoursRest = beatPlayer.playheadBeats ?? yoursRest
            beatPlayer.onStep = nil
            beatPlayer.stop()
            isFinished = true
        }
    }

    private func reset() {
        stage = .tapping
        tapTimes = []
        reading = nil
        needsPlay = false
        yourBPM = FinaleRules.crawlBPM
        rampProgress = 0
        isFinished = false
        originalRest = 0
        yoursRest = 0
        rampOffset = 0
    }
}

/// What the Finale's pad shows: a message, or the tempo reading.
enum FinalePad: Equatable {
    case message(PadMessage)
    /// The big "97  BPM from your taps" and a line under it.
    case reading(bpm: Int, detail: String)
}
