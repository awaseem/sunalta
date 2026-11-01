import RealityKit
import Testing
@testable import Sunalta

@MainActor
struct ClockGlyphAssetTests {
    @Test func bundledSharpModelsIncludeEveryClockCharacter() throws {
        let glyphs = try ClockGlyphAssets.load()
        #expect(Set(glyphs.keys) == Set("0123456789:".map(String.init)))
        for character in "0123456789" {
            let glyph = try #require(glyphs[String(character)])
            #expect(glyph.model != nil)
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
