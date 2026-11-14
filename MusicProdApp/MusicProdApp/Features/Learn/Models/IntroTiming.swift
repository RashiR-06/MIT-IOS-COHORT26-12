import Foundation

/// The three looks of the Intro screen (Figma E · 1, E · 2, E · 3).
enum IntroPhase {
    /// "Listen to the drums."
    case steady
    /// "Uh-oh! Something's wrong with the drums." + "Hear it drag?"
    case slowing
    /// Adds the rescue line, Replay and Fix the drums.
    case crawl
}

/// The Intro's numbers, from the Intro mockup. Plain functions of the
/// loop's time in seconds, so they are easy to unit test.
enum IntroTiming {
    static let startBPM = 100.0
    static let crawlBPM = 52.0
    /// Steady for 2 bars at 100 BPM before the slowdown starts.
    static let steadySeconds = 4.8
    /// How long the slowdown takes.
    static let slowdownSeconds = 8.0
    /// "Uh-oh!" appears once the slowdown is clearly audible.
    static let slowingTextProgress = 0.35
    /// The rescue line and buttons appear this long after the crawl settles.
    static let rescueDelay = 1.5
    static let openCutoff = 16_000.0
    static let closedCutoff = 2_500.0

    /// 0 before the slowdown, 1 after it, rising evenly in between.
    static func progress(at seconds: TimeInterval) -> Double {
        min(max((seconds - steadySeconds) / slowdownSeconds, 0), 1)
    }

    /// Tempo at a moment: 100, then a smooth S-curve down to 52.
    static func bpm(at seconds: TimeInterval) -> Double {
        let p = progress(at: seconds)
        let smooth = p * p * (3 - 2 * p)
        return startBPM - (startBPM - crawlBPM) * smooth
    }

    /// Lower tempo, lower pitch: (bpm / 100) to the power 0.6.
    static func pitchRatio(bpm: Double) -> Double {
        pow(bpm / startBPM, 0.6)
    }

    /// The low-pass filter closes from 16,000 Hz to 2,500 Hz across the slowdown.
    static func lowPassCutoff(at seconds: TimeInterval) -> Double {
        cutoff(closedness: progress(at: seconds))
    }

    /// The filter's cutoff for how closed it is: 0 is fully open, 1 is the
    /// crawl's dull sound. The Finale runs this backwards to open it again.
    static func cutoff(closedness: Double) -> Double {
        openCutoff - (openCutoff - closedCutoff) * closedness
    }

    static func phase(at seconds: TimeInterval) -> IntroPhase {
        if seconds > steadySeconds + slowdownSeconds + rescueDelay { return .crawl }
        if progress(at: seconds) > slowingTextProgress { return .slowing }
        return .steady
    }
}
