import Foundation
import QuartzCore
import RealityKit

@MainActor
final class ClockFlybyController: NSObject {
    private static let birdsPerFlock = 4
    let root = Entity()
    var onFrame: (() -> Void)?
    private let birds: [ClockFlybyBird]
    private var nextFlightTask: Task<Void, Never>?
    private var displayLink: CADisplayLink?
    private var flights: [(path: ClockFlybyPath, delay: Double)] = []
    private var flightDuration = 0.0
    private var flightStart: CFTimeInterval?
    private var viewport = SIMD2<Float>.zero
    private var cameraDistance: Float = 0

    init(kind: ClockFlybyKind, appearance: ClockAppearance) throws {
        switch kind {
        case .bird:
            let meshes = try ClockBirdMesh.load()
            let material = appearance.numeralMaterial()
            birds = (0..<(Self.birdsPerFlock * 2)).map { _ in
                ClockFlybyBird(meshes: meshes, material: material)
            }
        case .none:
            birds = []
        }
        super.init()
        root.name = "Clock theme flock"
        for bird in birds { root.addChild(bird.root) }
        root.isEnabled = false
    }

    func apply(appearance: ClockAppearance) {
        let material = appearance.numeralMaterial()
        for bird in birds { bird.apply(material: material) }
    }

    func setViewport(_ viewport: SIMD2<Float>, cameraDistance: Float) {
        self.viewport = viewport
        self.cameraDistance = cameraDistance
    }

    func start() {
        guard !birds.isEmpty, nextFlightTask == nil, displayLink == nil,
              viewport.x > 0, cameraDistance > 1 else { return }
        scheduleFlight(after: 0.9)
    }

    private func scheduleFlight(after delay: Double) {
        nextFlightTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(delay))
                try Task.checkCancellation()
                self?.beginFlight()
            } catch {
                // Visibility, scrolling and Reduce Motion cancel pending visits.
            }
        }
    }

    private func beginFlight() {
        nextFlightTask = nil
        let travelsRight = Bool.random()
        let height = Float.random(in: 0.28...0.46)
        let origin = Float.random(in: -0.12...0.12)
        let arc = Float.random(in: 0.08...0.16)
        flights = birds.indices.map { index in
            let member = index % Self.birdsPerFlock
            let isUpperFlock = index < Self.birdsPerFlock
            let side: Float = isUpperFlock ? 1 : -1
            let spread = Float(member) - Float(Self.birdsPerFlock - 1) / 2
            // Pair an upper flock with a lower flock heading toward the opposite edge.
            let path = ClockFlybyPath(duration: .random(in: 3.8...4.4),
                                     travelsRight: isUpperFlock ? travelsRight : !travelsRight,
                                     height: (height + spread * 0.08) * side,
                                     arc: (arc + Float(member) * 0.015) * side,
                                     origin: (origin + spread * 0.04) * side)
            return (path, Double(member) * 0.18 + (isUpperFlock ? 0 : 0.12))
        }
        flightDuration = flights.map { $0.path.duration + $0.delay }.max() ?? 0
        flightStart = nil
        // Match screen refresh instead of waking a free-running animation timer.
        let link = CADisplayLink(target: self, selector: #selector(advanceFlight(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func advanceFlight(_ link: CADisplayLink) {
        guard !flights.isEmpty else { return }
        if flightStart == nil { flightStart = link.targetTimestamp }
        let elapsed = link.targetTimestamp - (flightStart ?? link.targetTimestamp)
        guard elapsed < flightDuration else {
            stopDisplayLink()
            root.isEnabled = false
            onFrame?()
            scheduleFlight(after: .random(in: 0.7...1.4))
            return
        }
        for (bird, flight) in zip(birds, flights) {
            bird.update(path: flight.path, elapsed: elapsed - flight.delay,
                        viewport: viewport, cameraDistance: cameraDistance)
        }
        root.isEnabled = true
        onFrame?()
    }

    func stop() {
        nextFlightTask?.cancel()
        nextFlightTask = nil
        stopDisplayLink()
        if root.isEnabled {
            root.isEnabled = false
            onFrame?()
        }
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        flightStart = nil
        flights.removeAll(keepingCapacity: true)
        flightDuration = 0
    }
}
