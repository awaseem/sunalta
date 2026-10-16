import Foundation
import RealityKit

@MainActor
final class NumeralClockScene: ClockSceneContent {
    let root = Entity()
    var firstDigit: ModelEntity? { timeSlots.first }
    private let glyphs: [String: ModelEntity]
    private let glyphBounds: [String: BoundingBox]
    private var timeSlots: [ModelEntity] = []
    private let digitHeightScale: Float = 1.15
    private let digitGap: Float = 0.14
    private let rowGap: Float = 0.28
    private var displayedTime: String?
    private var material: PhysicallyBasedMaterial?
    private var surface = ClockSurface.plastic
    private var grassGlyphs: [String: ModelEntity] = [:]
    private var grassTime: Float = 0

    init() throws {
        glyphs = try ClockGlyphAssets.load()
        glyphBounds = glyphs.mapValues { $0.visualBounds(relativeTo: $0) }
    }

    func apply(theme: AppTheme) async throws {
        if theme.clock.surface == .grass {
            for (key, glyph) in glyphs where grassGlyphs[key] == nil {
                try Task.checkCancellation()
                if let mesh = glyph.model?.mesh {
                    grassGlyphs[key] = try GrassSurface.make(on: mesh, cacheKey: "numeral-\(key)")
                }
            }
        }
        surface = theme.clock.surface
        let material = theme.clock.numeralMaterial()
        self.material = material
        for glyph in timeSlots {
            glyph.model?.materials = [material]
            applySurface(to: glyph)
        }
    }

    func show(date: Date) {
        let time = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: date)
        show(time: AlarmTimeText.text(hour: time.hour ?? 0, minute: time.minute ?? 0))
    }

    func show(time: String) {
        guard time != displayedTime, !glyphs.isEmpty else { return }
        let characters = Array(time.filter(\.isNumber))
        guard characters.count == 4 else { return }
        let previous = Array((displayedTime ?? "").filter(\.isNumber))
        displayedTime = time
        // Four persistent slots: hours above minutes, with aligned digit columns.
        while timeSlots.count < characters.count {
            let slot = ModelEntity()
            root.addChild(slot)
            timeSlots.append(slot)
        }
        let digitBounds = "0123456789".compactMap { glyphBounds[String($0)] }
        let columnWidth = digitBounds.map(\.extents.x).max() ?? 1.6
        let rowHeight = (digitBounds.map(\.extents.y).max() ?? 3.712) * digitHeightScale
        for (index, character) in characters.enumerated() {
            let key = String(character)
            guard let prototype = glyphs[key], let bounds = glyphBounds[key] else { continue }
            let glyph = timeSlots[index]
            if index >= previous.count || previous[index] != character {
                glyph.model = prototype.model
                glyph.name = key
                if let material { glyph.model?.materials = [material] }
                applySurface(to: glyph)
            }
            let columnCenter = (index.isMultiple(of: 2) ? -1 : Float(1)) * (columnWidth + digitGap) / 2
            let rowCenter = (index < 2 ? 1 : Float(-1)) * (rowHeight + rowGap) / 2
            glyph.scale = [1, digitHeightScale, 1]
            glyph.position = [columnCenter - bounds.center.x,
                              rowCenter - bounds.center.y * digitHeightScale, 0]
        }
        root.scale = SIMD3(repeating: min(1, 3.8 / (2 * columnWidth + digitGap)))
    }

    func advanceBreeze(by deltaTime: Float) {
        guard surface == .grass else { return }
        grassTime += deltaTime
        for glyph in timeSlots {
            if let grass = glyph.findEntity(named: GrassSurface.entityName) {
                GrassSurface.update(grass, time: grassTime)
            }
        }
    }

    private func applySurface(to glyph: ModelEntity) {
        glyph.findEntity(named: GrassSurface.entityName)?.removeFromParent()
        guard surface == .grass, let prototype = grassGlyphs[glyph.name] else { return }
        let grass = prototype.clone(recursive: false)
        GrassSurface.update(grass, time: grassTime)
        glyph.addChild(grass)
    }

}
