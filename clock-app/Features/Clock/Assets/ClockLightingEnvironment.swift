import RealityKit

/// Shared studio reflections, loaded once rather than rebuilt when a preview opens.
@MainActor
enum ClockLightingEnvironment {
    private static var resourceTask: Task<EnvironmentResource, Error>?

    static func load() async throws -> EnvironmentResource {
        if let resourceTask { return try await resourceTask.value }
        let task = Task {
            try await EnvironmentResource(named: "ClockStudio", skyboxMode: .discard)
        }
        resourceTask = task
        do {
            return try await task.value
        } catch {
            resourceTask = nil
            throw error
        }
    }
}
