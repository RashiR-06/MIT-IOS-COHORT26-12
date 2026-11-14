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
    /// The lesson's normal tempo. Screens that change the tempo put it back
    /// to this when they are left.
    static let normal = 100.0
}

/// What views and view models use to play drums. Only Services/Audio
/// knows about AVFoundation; everything else talks to this protocol.
protocol BeatPlaying: AnyObject {
    /// True while a pattern is looping (also while paused).
    var isLooping: Bool { get }
    /// True while the loop is paused and can be resumed.
    var isPaused: Bool { get }
    /// The pattern step (0-based) that was just played, or nil when stopped.
    var currentStep: Int? { get }
    /// When that step played, in seconds since the loop started, on the
    /// audio clock. Read it inside onStep to follow the loop's own time.
    var currentStepSeconds: TimeInterval? { get }
    /// The loop's tempo in beats per minute.
    var bpm: Double { get }
    /// Where the loop is right now, in beats since it started (2.5 means
    /// halfway through the third beat). Read from the audio clock and
    /// matched to what you hear. Nil when stopped. Read it every frame to
    /// move visuals smoothly.
    var playheadBeats: Double? { get }
    /// What part of the loop you were hearing at a given moment, in seconds
    /// since the loop started (beat 1 is at 0). The moment is in seconds
    /// since the phone started, the same clock as a touch's timestamp, so
    /// a tap can be judged against the music it was played to. Allows for
    /// the output latency. Nil when stopped or paused.
    func loopSeconds(heardAt uptime: TimeInterval) -> TimeInterval?
    /// Called on the main thread each time a step is played.
    var onStep: ((Int) -> Void)? { get set }
    /// Called on the main thread when a loop with a play length ends by itself.
    var onFinish: (() -> Void)? { get set }
    /// Changes every time a loop starts or stops. A screen can remember it
    /// when it starts a loop, and later stop only if that loop is still the
    /// one playing (not one a newer screen has started).
    var loopID: Int { get }
    /// Seconds between the app producing sound and it reaching the speaker
    /// or headphones. Bluetooth makes this much larger.
    var outputLatency: TimeInterval { get }

    /// Loads the drums and starts audio so the first hit is not delayed.
    /// Optional: play and startLoop do this themselves if needed.
    func prepare()
    /// Plays one drum straight away.
    func play(_ sound: DrumSound)
    /// Loops a pattern at the given tempo, timed by the audio clock. The
    /// first step plays startDelay seconds from now. With a duration, it
    /// plays only the steps that start before that many seconds, then stops
    /// by itself and calls onFinish.
    func startLoop(_ pattern: DrumPattern, bpm: Double, startDelay: TimeInterval, duration: TimeInterval?)
    /// Changes the tempo while the loop keeps playing. It takes effect at
    /// the next step boundary. Clamped to TempoLimits.range.
    func setTempo(_ bpm: Double)
    /// Freezes the loop where it is; resume carries on from the same spot.
    func pause()
    func resume()
    /// Stops the loop and any drums still ringing.
    func stop()
    /// Lowers the drums' pitch (1 = unchanged, 0.5 = an octave down) and
    /// closes a low-pass filter (in Hz) to make them duller.
    func setDrumEffects(pitchRatio: Double, lowPassCutoff: Double)
    /// Turns the pitch and filter off again.
    func resetDrumEffects()
}

extension BeatPlaying {
    /// Loops a pattern starting a tenth of a second from now.
    func startLoop(_ pattern: DrumPattern, bpm: Double) {
        startLoop(pattern, bpm: bpm, startDelay: 0.1, duration: nil)
    }

    /// Loops a pattern until stopped.
    func startLoop(_ pattern: DrumPattern, bpm: Double, startDelay: TimeInterval) {
        startLoop(pattern, bpm: bpm, startDelay: startDelay, duration: nil)
    }
}
