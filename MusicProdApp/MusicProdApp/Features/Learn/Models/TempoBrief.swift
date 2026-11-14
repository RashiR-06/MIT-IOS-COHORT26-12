import Foundation

/// A brief for Do 3 "Match the brief": a vibe the learner sets a tempo for,
/// the zone that fits it, and the words shown for each result (Figma
/// G · 3a–d and the Do mockup).
struct TempoBrief {
    let title: String
    let tags: String
    /// SF Symbol for the brief's icon.
    let symbol: String
    let zone: ClosedRange<Int>
    /// Where the dial starts.
    let startBPM: Int
    /// Used in "N BPM above the late-night zone".
    let zoneName: String
    let fitsTitle: String
    let fitsDetail: String
}

extension TempoBrief {
    /// Lesson 1.1 has one brief.
    static let lateNight = TempoBrief(
        title: "Late-night",
        tags: "Calm · slow · unhurried",
        symbol: "moon",
        zone: 60...90,
        startBPM: 120,
        zoneName: "late-night",
        fitsTitle: "Fits late-night",
        fitsDetail: "Calm and unhurried. Nice choice."
    )
}

/// One row of the hint's "tempo feels" strip (Figma "Hint popover").
struct TempoFeel: Identifiable {
    let name: String
    let range: String
    var id: String { name }

    static let all = [
        TempoFeel(name: "Laid-back", range: "60–90 BPM"),
        TempoFeel(name: "Groove", range: "90–110 BPM"),
        TempoFeel(name: "Dance", range: "120–130 BPM"),
        TempoFeel(name: "High energy", range: "140+ BPM"),
    ]
}
