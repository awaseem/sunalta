import RealityKit
import Testing
@testable import Sunalta

@MainActor
struct GrassSurfaceTests {
    @Test func changingTheTimeReplacesTheGrassWithTheNewDigitsMesh() async throws {
        let scene = try NumeralClockScene()
        scene.show(time: "11:11")
        try await scene.apply(theme: .grass)
        let originalGrass = try #require(scene.firstDigit?.findEntity(named: GrassSurface.entityName))
        let original = try #require(originalGrass.components[ModelComponent.self]?.mesh)

        scene.show(time: "22:22")
        let replacementGrass = try #require(scene.firstDigit?.findEntity(named: GrassSurface.entityName))
        let replacement = try #require(replacementGrass.components[ModelComponent.self]?.mesh)
        #expect(original !== replacement)
        #expect(scene.root.children.allSatisfy { $0.children.count == 1 })

        try await scene.apply(theme: .midnight)
        #expect(scene.root.findEntity(named: GrassSurface.entityName) == nil)
        try await scene.apply(theme: .grass)
        #expect(scene.root.children.allSatisfy { $0.children.count == 1 })
    }

    @Test func bellRevealPreservesGrassMaterialsAndSwitchingThemesRemovesThem() async throws {
        let scene = try await AlarmBellScene()
        try scene.apply(theme: .grass)
        let grass = try #require(scene.root.findEntity(named: GrassSurface.entityName))
        scene.advanceReveal(by: ClockEntranceAnimation.fadeDuration)
        #expect(grass.components[ModelComponent.self]?.materials.first is CustomMaterial)

        try scene.apply(theme: .white)
        #expect(scene.root.findEntity(named: GrassSurface.entityName) == nil)
    }
}
