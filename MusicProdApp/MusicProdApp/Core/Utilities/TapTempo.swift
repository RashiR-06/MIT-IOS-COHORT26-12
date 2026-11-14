import Foundation

/// Tempo-from-taps sums. Pure maths: tap times go in as seconds on any one
/// clock, so these can be tested without any audio or screen.
enum TapTempo {
    /// The gaps between one tap and the next.
    static func intervals(between times: [TimeInterval]) -> [TimeInterval] {
        zip(times.dropFirst(), times).map { $0 - $1 }
    }

    /// The middle value once sorted (the average of the two middle values
    /// for an even count). Nil for an empty list. Unlike the mean, one stray
    /// tap barely moves it.
    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    /// Beats per minute from the median gap between taps, rounded to a
    /// whole BPM and kept within `limits`. Nil with fewer than 2 taps.
    static func bpm(fromTapTimes times: [TimeInterval], limits: ClosedRange<Int>) -> Int? {
        guard let gap = median(intervals(between: times)), gap > 0 else { return nil }
        let bpm = Int((60 / gap).rounded())
        return min(max(bpm, limits.lowerBound), limits.upperBound)
    }
}
