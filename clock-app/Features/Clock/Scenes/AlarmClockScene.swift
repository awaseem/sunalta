import Foundation
import RealityKit

@MainActor
final class AlarmClockScene: ClockSceneContent {
    let root = Entity()
    private let casing: Entity
    private let hands: [(entity: Entity, rest: simd_quatf)]
    private var appliedFinish: AlarmClockFinish?
    private var appliedAppearance: ClockAppearance?

    init(model: Entity) throws {
        guard let casing = model.findEntity(named: "Casing") else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.casing = casing
        let pivots = try ["HourHand", "MinuteHand"].map { name in
            guard let hand = model.findEntity(named: name) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return hand
        }
        hands = pivots.map { ($0, $0.orientation(relativeTo: nil)) }
        root.addChild(model)
        model.position.y -= model.visualBounds(relativeTo: root).center.y
    }

    func apply(theme: AppTheme) async throws {
        guard appliedFinish != theme.alarmClockFinish || appliedAppearance != theme.clock else { return }
        let material = try await theme.alarmClockFinish.material(matching: theme.clock)
        try Task.checkCancellation()
        setMaterial(material, on: casing)
        appliedFinish = theme.alarmClockFinish
        appliedAppearance = theme.clock
    }

    func show(date: Date) {
        show(date: date, calendar: .autoupdatingCurrent)
    }

    func show(date: Date, calendar: Calendar) {
        let time = AnalogClockTime(date: date, calendar: calendar)
        for (hand, angle) in zip(hands, [time.hourAngle, time.minuteAngle]) {
            hand.entity.setOrientation(simd_quatf(angle: -angle, axis: [0, 0, 1]) * hand.rest,
                                       relativeTo: root)
        }
    }

    private func setMaterial(_ material: PhysicallyBasedMaterial, on entity: Entity) {
        if var model = entity.components[ModelComponent.self] {
            model.materials = Array(repeating: material, count: max(1, model.materials.count))
            entity.components.set(model)
        }
        for child in entity.children { setMaterial(material, on: child) }
    }
}
