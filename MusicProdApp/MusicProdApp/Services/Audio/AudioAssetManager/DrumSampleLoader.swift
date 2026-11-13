import AVFoundation

/// Loads the drum WAVs from the app bundle into memory.
enum DrumSampleLoader {
    enum LoadError: Error {
        case missingFile(String)
        case unreadable(String)
    }

    /// File names in Resources/Audio/Learning/Drums/.
    static let fileNames: [DrumSound: String] = [
        .kick: "drum_kick",
        .snare: "drum_snare",
        .hatClosed: "drum_hat_closed",
    ]

    /// Reads one WAV into a buffer in its own format. The files do not all
    /// share a sample rate (the snare is 48 kHz), so nothing is assumed.
    static func load(_ sound: DrumSound) throws -> AVAudioPCMBuffer {
        let name = fileNames[sound] ?? ""
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            throw LoadError.missingFile(name)
        }
        let file = try AVAudioFile(forReading: url)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length)) else {
            throw LoadError.unreadable(name)
        }
        try file.read(into: buffer)
        return buffer
    }
}
