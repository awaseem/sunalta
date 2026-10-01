import Foundation
import RealityKit

enum ClockSurface: String {
    case hangarConcrete = "hangar_concrete_floor"
    case plasteredWall = "plastered_wall"
}

/// Shared 1K maps; async loading and mipmaps keep texture work out of scrolling.
@MainActor
struct ClockSurfaceTextures {
    let color: TextureResource
    let normal: TextureResource
    let roughness: TextureResource
    let ambientOcclusion: TextureResource

    private static var loads: [ClockSurface: Task<ClockSurfaceTextures, Error>] = [:]

    static func load(_ surface: ClockSurface) async throws -> ClockSurfaceTextures {
        if let existing = loads[surface] { return try await existing.value }
        let task = Task {
            let color = try await loadMap("diff", for: surface, semantic: .color)
            let normal = try await loadMap("nor_gl", for: surface, semantic: .normal)
            let roughness = try await loadMap("rough", for: surface, semantic: .scalar)
            let ambientOcclusion = try await loadMap("ao", for: surface, semantic: .scalar)
            return ClockSurfaceTextures(color: color, normal: normal, roughness: roughness,
                                        ambientOcclusion: ambientOcclusion)
        }
        loads[surface] = task
        return try await task.value
    }

    private static func loadMap(_ map: String, for surface: ClockSurface,
                                semantic: TextureResource.Semantic) async throws -> TextureResource {
        guard let url = Bundle.main.url(forResource: "\(surface.rawValue)_\(map)_1k", withExtension: "jpg") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try await TextureResource(contentsOf: url, options: .init(semantic: semantic))
    }
}
