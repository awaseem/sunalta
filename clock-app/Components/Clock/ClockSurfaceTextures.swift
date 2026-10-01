import Foundation
import RealityKit

/// The seeded 128px color and normal maps embedded in the Three.js exports.
@MainActor
struct ClockSurfaceTextures {
    let color: TextureResource
    let normal: TextureResource
    private static var loading: Task<ClockSurfaceTextures, Error>?

    static func load() async throws -> ClockSurfaceTextures {
        if let loading { return try await loading.value }
        let task = Task {
            let color = try await loadMap("sandpaper-color", semantic: .color)
            let normal = try await loadMap("sandpaper-normal", semantic: .normal)
            return ClockSurfaceTextures(color: color, normal: normal)
        }
        loading = task
        return try await task.value
    }

    private static func loadMap(_ name: String, semantic: TextureResource.Semantic) async throws -> TextureResource {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try await TextureResource(contentsOf: url, options: .init(semantic: semantic))
    }
}
