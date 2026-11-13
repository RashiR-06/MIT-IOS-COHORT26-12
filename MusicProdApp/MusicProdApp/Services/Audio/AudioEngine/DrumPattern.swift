import Foundation

/// One drum hit inside a step. Volume 1 is the sample as recorded.
struct DrumHit {
    let sound: DrumSound
    let volume: Float
}

/// A looping drum pattern. Each step is one eighth note, so 8 steps make
/// one bar of 4/4. Change the data to make a new groove; the player stays
/// the same.
struct DrumPattern {
    let steps: [[DrumHit]]

    /// Length of one step in seconds: an eighth note is half a beat.
    static func stepDuration(bpm: Double) -> TimeInterval {
        60 / bpm / 2
    }
}

extension DrumPattern {
    /// The Lesson 1.1 groove used in Learn and Do. Matches
    /// docs/lesson-1.1/audio/ref_groove_100bpm.wav: kick on 1 and 3,
    /// snare on 2 and 4, closed hat on every eighth with softer off-beats.
    static let lessonGroove: DrumPattern = {
        let kick = DrumHit(sound: .kick, volume: 1)
        let snare = DrumHit(sound: .snare, volume: 1)
        let hat = DrumHit(sound: .hatClosed, volume: 1)
        let softHat = DrumHit(sound: .hatClosed, volume: 0.43)
        return DrumPattern(steps: [
            [kick, hat],    // 1
            [softHat],      // 1 and
            [snare, hat],   // 2
            [softHat],      // 2 and
            [kick, hat],    // 3
            [softHat],      // 3 and
            [snare, hat],   // 4
            [softHat],      // 4 and
        ])
    }()
}
