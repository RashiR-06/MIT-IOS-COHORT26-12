import Foundation

/// Switches for temporary developer screens. Release builds always hide them.
enum DebugFlags {
    #if DEBUG
    /// Opens the audio test screen instead of the lesson.
    /// Set to false before the demo.
    static let showAudioDebug = true
    #else
    static let showAudioDebug = false
    #endif
}
