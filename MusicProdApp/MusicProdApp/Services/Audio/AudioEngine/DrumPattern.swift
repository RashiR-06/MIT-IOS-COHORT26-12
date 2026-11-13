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

    /// The Intro groove from the Intro mockup: 16 sixteenth-note steps.
    /// Kick on steps 0, 8 and 10, snare on 4 and 12, closed hat on every
    /// step with the odd (in-between) steps softer.
    static let introGroove: DrumPattern = {
        let kick = DrumHit(sound: .kick, volume: 1)
        let snare = DrumHit(sound: .snare, volume: 1)
        let hat = DrumHit(sound: .hatClosed, volume: 1)
        let softHat = DrumHit(sound: .hatClosed, volume: 0.375)
        let steps = (0..<16).map { step -> [DrumHit] in
            var hits = [step % 2 == 0 ? hat : softHat]
            if [0, 8, 10].contains(step) { hits.append(kick) }
            if [4, 12].contains(step) { hits.append(snare) }
            return hits
        }
        return DrumPattern(steps: steps, stepsPerBeat: 4)
    }()
}
