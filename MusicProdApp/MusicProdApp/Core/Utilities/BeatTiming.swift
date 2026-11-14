import Foundation

/// Whether a tap came before, on or after a beat.
enum TimingDirection: Equatable {
    case early
    case onTime
    case late
}

/// Small timing sums for judging taps against a steady beat. Pure maths:
/// times go in as seconds on the loop's own clock (beat 1 at 0), so these
/// can be tested without any audio or screen.
enum BeatTiming {
    /// Length of one beat in seconds at a tempo.
    static func beatDuration(bpm: Double) -> TimeInterval {
        60 / bpm
    }

    /// The beat closest to a moment (0 is the first beat).
    static func nearestBeat(to seconds: TimeInterval, beatDuration: TimeInterval) -> Int {
        Int((seconds / beatDuration).rounded())
    }

    /// How far a moment is from its nearest beat, in seconds. Negative is
    /// before the beat (early), positive is after it (late).
    static func offsetFromNearestBeat(_ seconds: TimeInterval, beatDuration: TimeInterval) -> TimeInterval {
        seconds - Double(nearestBeat(to: seconds, beatDuration: beatDuration)) * beatDuration
    }

    /// Where a beat falls in its bar: 0 is beat 1, up to beatsPerBar − 1.
    /// Works for negative beats too (beat −1 is the last beat of the bar
    /// before), so a tap just before the loop starts still has a place.
    static func beatInBar(_ beat: Int, beatsPerBar: Int) -> Int {
        ((beat % beatsPerBar) + beatsPerBar) % beatsPerBar
    }

    /// An offset as whole milliseconds, without its sign (0.1404 → 140).
    static func milliseconds(_ offset: TimeInterval) -> Int {
        Int((abs(offset) * 1000).rounded())
    }

    /// On time when the offset is inside ±window (the edge counts as on
    /// time); otherwise early or late.
    static func direction(of offset: TimeInterval, window: TimeInterval) -> TimingDirection {
        // A nanosecond of slack so float rounding can't push the edge out.
        if abs(offset) <= window + 1e-9 { return .onTime }
        return offset < 0 ? .early : .late
    }
}
