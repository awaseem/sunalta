import Foundation
import RealityKit
import Testing
@testable import clock_app

@MainActor
struct AlarmClockAssetTests {
    @Test func bundledClockRetainsMaterialGroupsAndMovableHands() async throws {
        let asset = try await AlarmClockAsset.load()
        let casing = try #require(asset.findEntity(named: "Casing"))
        #expect(!casing.children.isEmpty)
        let hour = try #require(asset.findEntity(named: "HourHand"))
        let minute = try #require(asset.findEntity(named: "MinuteHand"))
        #expect(hour !== minute)
        #expect(asset.findEntity(named: "SecondHand") == nil)
        // A Z-up or incorrectly scaled export would not have these proportions.
        let bounds = asset.visualBounds(relativeTo: nil)
        #expect(bounds.extents.x > 2 && bounds.extents.x < 3.5)
        #expect(bounds.extents.y > 3 && bounds.extents.y < 4)
        #expect(bounds.extents.z < 1.2)
        // Keep this decorative clock small while retaining separate movable hands.
        func meshCount(in entity: Entity) -> Int {
            (entity.components[ModelComponent.self] == nil ? 0 : 1)
                + entity.children.reduce(0) { $0 + meshCount(in: $1) }
        }
        #expect(meshCount(in: asset) <= 6)
    }

    @Test func defaultCasingMatchesTheNumeralFinish() async throws {
        let theme = AppTheme.white
        let casing = try await theme.alarmClockFinish.material(matching: theme.clock)
        let numerals = theme.clock.numeralMaterial()
        #expect(casing.baseColor.tint == numerals.baseColor.tint)
        #expect(casing.roughness.scale == numerals.roughness.scale)
        #expect(casing.metallic.scale == numerals.metallic.scale)
        #expect(casing.clearcoat.scale == numerals.clearcoat.scale)
    }

    @Test func handsTellTimeWithoutMovingTheCasing() async throws {
        let asset = try await AlarmClockAsset.load()
        let scene = try AlarmClockScene(model: asset)
        let minute = try #require(scene.root.findEntity(named: "MinuteHand"))
        let casing = try #require(scene.root.findEntity(named: "Casing"))
        let casingBounds = casing.visualBounds(relativeTo: scene.root)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        scene.show(date: Date(timeIntervalSince1970: 0), calendar: calendar)
        let twelve = minute.visualBounds(relativeTo: scene.root).extents
        scene.show(date: Date(timeIntervalSince1970: 15 * 60), calendar: calendar)
        let three = minute.visualBounds(relativeTo: scene.root).extents
        #expect(three.x > twelve.x)
        #expect(three.y < twelve.y)

        #expect(casing.visualBounds(relativeTo: scene.root) == casingBounds)
    }

    @Test func savedAdjustmentsPreserveAuthoredCasingTextures() {
        var theme = AppTheme.white
        theme.alarmClockFinish = AlarmClockFinish(
            roughness: 0.65, metallic: 0.8, clearcoat: 0,
            baseColorTexture: "BrushedMetal.png", normalTexture: "BrushedMetalNormal.png"
        )
        let adjusted = ThemeAdjustments(shimmer: 0.8).applying(to: theme)
        #expect(adjusted.alarmClockFinish == theme.alarmClockFinish)
    }
}
