import Foundation

/// Switches for temporary developer tools. Release builds always hide them.
enum DebugFlags {
    #if DEBUG
    /// Shows an "Audio test" button in the bottom-left corner of the lesson,
    /// which opens the audio test screen. Set to false before the demo.
    static let showAudioDebug = true
    #else
    static let showAudioDebug = false
    #endif
}
