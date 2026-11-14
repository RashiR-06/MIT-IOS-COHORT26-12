import Foundation

/// Where a tempo sits against a zone of tempos.
enum ZonePosition: Equatable {
    case below(by: Int)
    case inside
    case above(by: Int)
}

/// Small tempo-zone sums. Pure maths, so they can be tested without any
/// audio or screen.
enum TempoZone {
    /// Below, inside or above the zone, and by how many BPM. The bounds
    /// count as inside (60 and 90 both fit 60...90).
    static func position(of bpm: Int, in zone: ClosedRange<Int>) -> ZonePosition {
        if bpm < zone.lowerBound { return .below(by: zone.lowerBound - bpm) }
        if bpm > zone.upperBound { return .above(by: bpm - zone.upperBound) }
        return .inside
    }
}
