import RealityKit
import Testing
@testable import clock_app

@MainActor
struct ClockGlyphAssetTests {
    @Test func bundledSharpModelsIncludeEveryClockCharacter() throws {
        let glyphs = try ClockGlyphAssets.load()
        #expect(Set(glyphs.keys) == Set("0123456789:".map(String.init)))
        for character in "0123456789" {
            let glyph = try #require(glyphs[String(character)])
            #expect(glyph.model != nil)
            let bounds = glyph.visualBounds(relativeTo: glyph)
            #expect(bounds.extents.x > 0 && bounds.extents.z > 0)
            #expect(abs(bounds.extents.y - 3.712) < 0.001)
        }
    }

    @Test func clockViewsReceiveIndependentClones() throws {
        let first = try ClockGlyphAssets.load()
        let second = try ClockGlyphAssets.load()
        let firstSeven = try #require(first["7"])
        let secondSeven = try #require(second["7"])
        #expect(firstSeven !== secondSeven)
        firstSeven.position.x = 10
        #expect(secondSeven.position.x == 0)
    }
}
