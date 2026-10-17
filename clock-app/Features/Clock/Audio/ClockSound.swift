/// A bundled audio file and its mix level, from 0 (silent) to 1 (full volume).
struct ClockSound: Equatable {
    let fileName: String
    let volume: Float
}
