import Foundation

/// One drum hit inside a step. Volume 1 is the sample as recorded.
struct DrumHit {
    let sound: DrumSound
    let volume: Float
}

/// A looping drum pattern. By default each step is one eighth note, so 8
/// steps make one bar of 4/4. Change the data to make a new groove; the
/// player stays the same.
struct DrumPattern {
    let steps: [[DrumHit]]
    /// How many steps make one beat: 2 for eighth notes, 4 for sixteenths.
    var stepsPerBeat = 2

    /// Length of one step in seconds at a given tempo.
    func stepDuration(bpm: Double) -> TimeInterval {
        60 / bpm / Double(stepsPerBeat)
    }
}

extension DrumPattern {
    /// The Lesson 1.1 groove, used in Learn and Do. Matched to
    /// docs/lesson-1.1/audio/ref_groove_100bpm.wav: kick on 1 and 3, snare
    /// on 2 and 4, closed hat on the off-beats (the "and" between beats) at
    /// full volume. Compared against the reference by mixing our three
    /// samples and measuring each eighth note.
    static let lessonGroove: DrumPattern = {
        let kick = DrumHit(sound: .kick, volume: 1)
        let snare = DrumHit(sound: .snare, volume: 1)
        let hat = DrumHit(sound: .hatClosed, volume: 1)
        return DrumPattern(steps: [
            [kick],     // 1
            [hat],      // 1 and
            [snare],    // 2
            [hat],      // 2 and
            [kick],     // 3
            [hat],      // 3 and
            [snare],    // 4
            [hat],      // 4 and
        ])
    }()

    /// The Intro plays the same groove as the rest of the lesson; it then
    /// slows it down (see IntroTiming).
    static let introGroove = lessonGroove
}
