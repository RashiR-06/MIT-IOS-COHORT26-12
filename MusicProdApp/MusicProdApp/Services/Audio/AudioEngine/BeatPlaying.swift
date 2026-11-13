import Foundation

/// The drum sounds the app can play.
enum DrumSound: CaseIterable {
    case kick
    case snare
    case hatClosed
}

/// The tempos the player accepts. Anything outside is clamped.
enum TempoLimits {
    static let range: ClosedRange<Double> = 40...160
}

/// What views and view models use to play drums. Only Services/Audio
/// knows about AVFoundation; everything else talks to this protocol.
protocol BeatPlaying: AnyObject {
    /// True while a pattern is looping.
    var isLooping: Bool { get }
    /// The pattern step (0-based) that was just played, or nil when stopped.
    var currentStep: Int? { get }
    /// The loop's tempo in beats per minute.
    var bpm: Double { get }
    /// Called on the main thread each time a step is heard.
    var onStep: ((Int) -> Void)? { get set }
    /// Seconds between the app producing sound and it reaching the speaker
    /// or headphones. Bluetooth makes this much larger.
    var outputLatency: TimeInterval { get }

    /// Loads the drums and starts audio so the first hit is not delayed.
    /// Optional: play and startLoop do this themselves if needed.
    func prepare()
    /// Plays one drum straight away.
    func play(_ sound: DrumSound)
    /// Loops a pattern at the given tempo, timed by the audio clock.
    func startLoop(_ pattern: DrumPattern, bpm: Double)
    /// Changes the tempo while the loop keeps playing. It takes effect at
    /// the next step boundary. Clamped to TempoLimits.range.
    func setTempo(_ bpm: Double)
    /// Stops the loop and any drums still ringing.
    func stop()
}
