import RealityKit

enum ClockScene {
    case numbers
    case alarm

    // View from above, with the face pointing lower-right and equal foreshortening on all axes.
    var restingAngles: SIMD2<Float> { self == .alarm ? [-.pi / 4, -atan(1 / sqrt(2))] : .zero }
    var backdropDepth: Float { self == .alarm ? -5 : -0.04 }

    @MainActor
    func load() async throws -> any ClockSceneContent {
        switch self {
        case .numbers:
            try NumeralClockScene()
        case .alarm:
            try await AlarmClockScene(model: AlarmClockAsset.load())
        }
    }
}
