import Foundation

/// The rules of the Lesson 1.1 Finale "Tap the tempo", all in one place
/// (docs/lesson-1.1/decisions.md and the Finale mockup): tap along to the
/// original drums; within ±5 BPM of 100 brings your drums back.
enum FinaleRules {
    /// The original drums' tempo, which the learner's taps must match.
    static let targetBPM = 100
    /// How far off the tapped tempo may be and still pass.
    static let tolerance = 5
    /// Taps needed before a reading shows.
    static let tapsForReading = 4
    /// Taps needed before "Set tempo" appears.
    static let tapsForSet = 6
    /// Only the most recent taps count.
    static let maxTaps = 9
    /// A longer pause than this starts the tapping over.
    static let resetGap: TimeInterval = 1.5
    /// Readings are kept within this range.
    static let readingLimits = 40...200

    /// Your drums start at the Intro's crawl and speed back up over this long.
    static let crawlBPM = IntroTiming.crawlBPM
    static let rampSeconds: TimeInterval = 2.4
    /// The "Lesson complete" pop-up shows this long after your drums start.
    static let popupDelay: TimeInterval = 5.2

    /// Set tempo's verdict on a reading.
    static func judge(bpm: Int) -> FinaleResult {
        let difference = bpm - targetBPM
        if abs(difference) <= tolerance { return .pass }
        return difference > 0 ? .tooFast(by: difference) : .tooSlow(by: -difference)
    }

    /// 0 → 1 across the ramp, on an S-curve (slow start, slow finish), from
    /// the seconds since your drums started.
    static func rampProgress(at seconds: TimeInterval) -> Double {
        let p = min(max(seconds / rampSeconds, 0), 1)
        return p * p * (3 - 2 * p)
    }

    /// Your drums' tempo during the ramp.
    static func rampBPM(progress: Double) -> Double {
        crawlBPM + (Double(targetBPM) - crawlBPM) * progress
    }
}

enum FinaleResult: Equatable {
    case pass
    case tooFast(by: Int)
    case tooSlow(by: Int)
}
