import RealityKit
import SwiftUI

/// Two spacious flocks cross left to right along the home screen's shallow curves.
@MainActor
final class AlarmFlybyController {
    let root = Entity()
    private let animals: [ClockFlybyAnimal]
    private var flights: [(path: ClockFlybyPath?, startsAt: TimeInterval)]
    private var elapsed: TimeInterval = 0
    private var nextBurstAt = ClockFlybyController.initialFlightDelay
    private var viewport = SIMD2<Float>.zero
    private static let cameraDistance: Float = 66
    private static let animalsPerFlock = 8
    private static let flockSides: [Float] = [1, -1]

    init(kind: ClockFlybyKind, appearance: ClockAppearance) throws {
        let meshes = switch kind {
        case .butterfly: try ClockButterflyMesh.load()
        case .bat: try ClockBatMesh.load()
        case .bird, .none: try ClockBirdMesh.load()
        }
        let count = kind == .none ? 0 : Self.flockSides.count * Self.animalsPerFlock
        let material = appearance.flybyMaterial()
        animals = (0..<count).map { _ in ClockFlybyAnimal(kind: kind, meshes: meshes, material: material) }
        flights = Array(repeating: (nil, 0), count: count)
        root.name = "Alarm crossing visitors"
        for animal in animals { root.addChild(animal.root) }
        root.isEnabled = false
    }

    func apply(appearance: ClockAppearance) {
        let material = appearance.flybyMaterial()
        animals.forEach { $0.apply(material: material) }
    }

    func setViewport(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        // Preserve the home screen's apparent creature size in this orthographic scene.
        let scale = Float(size.height) / (2 * Self.cameraDistance * tan(.pi / 30))
        viewport = [Float(size.width) / scale, Float(size.height) / scale]
        root.scale = SIMD3(repeating: scale)
        // Keep visitors behind both 3D models; SwiftUI text and controls already render above the scene.
        root.position.z = -300
    }

    func burst() {
        // All sixteen finish, followed by the home screen's quiet pause before another visit.
        guard viewport.x > 0, !animals.isEmpty, !root.isEnabled, elapsed >= nextBurstAt else { return }
        let height = Float.random(in: 0.28...0.46)
        let arc = Float.random(in: 0.08...0.16)
        let perspective = (Self.cameraDistance - ClockFlybyPath.depth) / Self.cameraDistance
        for (flockIndex, side) in Self.flockSides.enumerated() {
            for member in 0..<Self.animalsPerFlock {
                let spread = Float(member) - Float(Self.animalsPerFlock - 1) / 2
                let slot = flockIndex * Self.animalsPerFlock + member
                // A full-width pass takes roughly five seconds.
                let duration = Double.random(in: ClockFlybyController.flightDurationRange) * 1.2
                flights[slot] = (
                    ClockFlybyPath(duration: duration,
                                   travelsRight: true,
                                   height: (height + spread * 0.06) * side / perspective,
                                   arc: (arc + Float(member) * 0.015) * side / perspective,
                                   origin: (-0.92 + spread * 0.04) / perspective,
                                   horizontalReach: 0.92 / perspective),
                    elapsed + Double(member) * ClockFlybyController.memberStagger
                        + (side < 0 ? 0.12 : 0)
                )
            }
        }
        root.isEnabled = true
    }

    func advance(by deltaTime: TimeInterval) {
        elapsed += max(0, deltaTime)
        for index in flights.indices {
            guard let path = flights[index].path else { continue }
            let flightTime = elapsed - flights[index].startsAt
            animals[index].update(path: path, elapsed: flightTime,
                                  viewport: viewport, cameraDistance: Self.cameraDistance)
            // Perspective depth belongs to the clock camera; this scene uses one flat visitor layer.
            animals[index].root.position.z = 0
            if flightTime >= path.duration { flights[index].path = nil }
        }
        if root.isEnabled, flights.allSatisfy({ $0.path == nil }) {
            root.isEnabled = false
            nextBurstAt = elapsed + ClockFlybyController.pauseBetweenFlights
        }
    }

    func stop() {
        for index in flights.indices {
            flights[index].path = nil
            animals[index].root.isEnabled = false
        }
        root.isEnabled = false
        elapsed = 0
        nextBurstAt = ClockFlybyController.initialFlightDelay
    }
}
