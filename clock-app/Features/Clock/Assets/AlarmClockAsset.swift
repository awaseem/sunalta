import Foundation
import RealityKit

/// Each view owns its entities; the USDZ keeps Blender's UVs and material groups intact.
@MainActor
enum AlarmClockAsset {
    static func load() async throws -> Entity {
        guard let url = Bundle.main.url(forResource: "AlarmClock", withExtension: "usdz") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let model = try await Entity(contentsOf: url)
        for name in ["Casing", "HourHand", "MinuteHand"] {
            guard model.findEntity(named: name) != nil else {
                throw CocoaError(.fileReadCorruptFile)
            }
        }
        return model
    }
}
