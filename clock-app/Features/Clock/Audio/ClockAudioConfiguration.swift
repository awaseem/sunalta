/// Theme-authored audio. Leave a layer nil to keep that part of the theme silent.
struct ClockAudioConfiguration: Equatable {
    /// Loops while the numeral clock is visible.
    var music: ClockSound?
    /// Silence after the track finishes, before its next play.
    var musicLoopDelay: Duration = .zero
    /// Plays once per flock visit and follows the animals' fade envelope.
    var flyby: ClockSound?
    /// Plays once with the numeral entrance animation.
    var entrance: ClockSound?
}
