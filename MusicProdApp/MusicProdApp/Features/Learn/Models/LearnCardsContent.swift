import Foundation

/// Everything the three Learn cards say and play (Figma F · 1–3b, tempos
/// from the Learn mockup). The views only lay this out.
enum LearnCardsContent {
    /// Card 1: the pulse.
    enum Pulse {
        static let title = "Feel the pulse."
        static let guide = "Count along as each number lights up. Beat 1 hits hardest."
        static let barLabel = "4 beats = 1 bar"
        static let bpm = 100.0
    }

    /// Card 2: two speeds on a 4-second timeline.
    enum Speeds {
        static let title = "BPM: beats per minute."
        static let guide = "Same beat, two speeds. Play both and listen for how often it lands."
        /// Once both have been heard, the guide line resolves: this part in
        /// white, then `resolvedRest` in grey.
        static let resolvedLead = "120 lands twice as often as 60."
        static let resolvedRest = " More beats each minute means a faster tempo."
        /// Each speed plays this long, then stops by itself.
        static let playSeconds: TimeInterval = 4
        static let rows = [
            SpeedRow(bpm: 60, caption: "1 beat / sec"),
            SpeedRow(bpm: 120, caption: "2 beats / sec"),
        ]
    }

    /// Card 3: four tempos and their energy.
    enum Energy {
        static let title = "Tempo sets the energy."
        static let guide = "Same beat at four tempos. Play each and notice how the mood lifts."
        static let slowEnd = "Slower, calmer"
        static let fastEnd = "Faster, more energy"
        static let tempos = [
            EnergyTempo(name: "Laid-back", bpm: 75, genres: "lo-fi · R&B"),
            EnergyTempo(name: "Groove", bpm: 100, genres: "hip-hop · pop"),
            EnergyTempo(name: "Dance", bpm: 125, genres: "house · disco"),
            EnergyTempo(name: "High energy", bpm: 150, genres: "techno · trap"),
        ]
    }

    static let cardCount = 3
}

struct SpeedRow {
    let bpm: Int
    let caption: String
}

struct EnergyTempo {
    let name: String
    let bpm: Int
    let genres: String
}
