import Foundation
import RealityKit

/// Scene geometry and materials; the renderer owns lighting, camera, and interaction.
@MainActor
protocol ClockSceneContent: AnyObject {
    var root: Entity { get }
    func show(date: Date)
    func apply(theme: AppTheme) async throws
}
