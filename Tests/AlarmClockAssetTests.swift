import Foundation
import RealityKit
import Testing
@testable import clock_app

@MainActor
struct AlarmClockAssetTests {
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
