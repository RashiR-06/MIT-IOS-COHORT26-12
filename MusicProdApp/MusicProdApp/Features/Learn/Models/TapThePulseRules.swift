import Foundation

/// The rules of Do 1 "Tap the pulse", all in one place. Pass rule from
/// docs/lesson-1.1/decisions.md (the mockup's default): 8 taps within
/// ±100 ms of a beat. Misses don't reset the count.
enum TapThePulseRules {
    /// A tap this close to a beat (either side) counts as on the beat.
    static let hitWindow: TimeInterval = 0.100
    /// On-beat taps needed to finish.
    static let hitsToPass = 8
    static let bpm = 100.0
    /// The Early / Late scale reaches this far each side of the beat.
    static let scaleRange: TimeInterval = 0.250

    /// Judges a tap heard at this moment of the loop (seconds, beat 1 at 0).
    static func judge(loopSeconds: TimeInterval) -> TapResult {
        let offset = BeatTiming.offsetFromNearestBeat(loopSeconds, beatDuration: BeatTiming.beatDuration(bpm: bpm))
        return TapResult(offset: offset, direction: BeatTiming.direction(of: offset, window: hitWindow))
    }
}

/// One judged tap.
struct TapResult: Equatable {
    /// Seconds from the nearest beat: negative early, positive late.
    let offset: TimeInterval
    let direction: TimingDirection

    var isHit: Bool { direction == .onTime }
    var milliseconds: Int { BeatTiming.milliseconds(offset) }

    /// Where the tap sits on the Early / Late scale: −1 (far left, early)
    /// to 1 (far right, late), 0 on the beat.
    var scalePosition: Double {
        min(max(offset / TapThePulseRules.scaleRange, -1), 1)
    }
}
