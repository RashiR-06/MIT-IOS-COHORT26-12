import Foundation

/// The rules of Do 2 "Find the 1", all in one place (from the Do mockup):
/// tap only on beat 1 of each 4-beat bar. Round 1 has lights, round 2 is
/// by ear; each round needs 2 taps on beat 1 within ±100 ms.
enum FindTheOneRules {
    /// A tap this close to beat 1 (either side) counts.
    static let hitWindow: TimeInterval = 0.100
    static let hitsPerRound = 2
    static let rounds = 2
    static var hitsToPass: Int { hitsPerRound * rounds }
    static let beatsPerBar = 4
    static let bpm = 100.0
    /// The "Now without the lights" alert waits this many beats after the
    /// round's last ✓, so the tick is seen first.
    static let roundAlertDelayBeats = 1
    /// The alert leaves this many beats after that ✓: one bar, so it goes
    /// as the next beat 1 comes round.
    static let roundAlertEndBeats = 4

    /// Judges a tap heard at this moment of the loop (seconds, beat 1 of
    /// bar 1 at 0).
    static func judge(loopSeconds: TimeInterval) -> FindTheOneResult {
        let beatDuration = BeatTiming.beatDuration(bpm: bpm)
        let beat = BeatTiming.nearestBeat(to: loopSeconds, beatDuration: beatDuration)
        let offset = BeatTiming.offsetFromNearestBeat(loopSeconds, beatDuration: beatDuration)
        let beatInBar = BeatTiming.beatInBar(beat, beatsPerBar: beatsPerBar)
        let direction = BeatTiming.direction(of: offset, window: hitWindow)
        return FindTheOneResult(beat: beat, beatInBar: beatInBar, offset: offset,
                                isHit: beatInBar == 0 && direction == .onTime)
    }

    /// The round (1 or 2) after this many hits.
    static func round(afterHits hits: Int) -> Int {
        min(hits / hitsPerRound + 1, rounds)
    }

    /// Round 1's cue: which tile is lit and how brightly (0–1), from the
    /// playhead in beats (see BeatLight).
    static func light(atBeats beats: Double) -> (tile: Int, level: Double) {
        let light = BeatLight.light(atBeats: beats, beatsPerBar: beatsPerBar)
        return (light.index, light.level)
    }
}

/// One judged tap in Find the 1.
struct FindTheOneResult: Equatable {
    /// The beat it was nearest to, counted from the loop's start.
    let beat: Int
    /// Which beat of the bar it was nearest to: 0 is beat 1.
    let beatInBar: Int
    /// Seconds from that beat: negative early, positive late.
    let offset: TimeInterval
    let isHit: Bool

    var milliseconds: Int { BeatTiming.milliseconds(offset) }
}
