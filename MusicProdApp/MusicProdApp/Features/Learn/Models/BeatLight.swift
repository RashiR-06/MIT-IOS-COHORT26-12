import Foundation

/// The beat lights used on 1–2–3–4 tiles and light bars (Do 2, Learn cards
/// 1 and 3, from the mockups): the current beat's light is full at the
/// start of the beat, then fades.
enum BeatLight {
    /// How fast a light fades during its beat: gone after 1/1.6 of the beat.
    static let fadeSpeed = 1.6

    /// Which light is on and how brightly (0–1), from the playhead in beats.
    static func light(atBeats beats: Double, beatsPerBar: Int = 4) -> (index: Int, level: Double) {
        let beat = beats.rounded(.down)
        let index = BeatTiming.beatInBar(Int(beat), beatsPerBar: beatsPerBar)
        return (index, max(0, 1 - (beats - beat) * fadeSpeed))
    }
}
