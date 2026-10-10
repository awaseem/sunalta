import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ThemeSettings {
    private var baseTheme: AppTheme
    private var adjustments: [String: ThemeAdjustments] = [:]
    private(set) var errorMessage: String?
    private let defaults: UserDefaults
    private static let selectionKey = "selectedThemeID"
    private static let adjustmentsKey = "themeAdjustmentsV1"

    var theme: AppTheme {
        adjustments[baseTheme.id]?.applying(to: baseTheme) ?? baseTheme
    }

    var lighting: ClockLightingSettings {
        get { theme.clock.lighting }
        set { update { $0.lighting = newValue } }
    }

    var shimmer: Double {
        get {
            adjustments[baseTheme.id]?.shimmer
                ?? min(max(Double((0.4 - baseTheme.clock.roughness) / 0.4), 0), 1)
        }
        set { update { $0.shimmer = min(max(newValue, 0), 1) } }
    }

    var weekday: ClockWeekdayAppearance {
        get { theme.weekday }
        set {
            var appearance = newValue
            let range = ClockWeekdayAppearance.sizeRange
            appearance.size = min(max(appearance.size, range.lowerBound), range.upperBound)
            appearance.glow.halo = min(max(appearance.glow.halo, 0), 1)
            appearance.glow.brightness = min(max(appearance.glow.brightness, 0), 12000)
            appearance.glow.spread = min(max(appearance.glow.spread, 15), 85)
            appearance.glow.direction = min(max(appearance.glow.direction, -90), 90)
            appearance.glow.reach = min(max(appearance.glow.reach, 1), 10)
            let current = weekday
            update {
                var adjustment = $0.weekday ?? ClockWeekdayAdjustments()
                if appearance.size != current.size { adjustment.size = appearance.size }
                if appearance.weight != current.weight { adjustment.weight = appearance.weight }
                if appearance.glow != current.glow { adjustment.glow = appearance.glow }
                $0.weekday = adjustment
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        baseTheme = AppTheme.resolve(id: defaults.string(forKey: Self.selectionKey))
        if let data = defaults.data(forKey: Self.adjustmentsKey) {
            do {
                adjustments = try JSONDecoder().decode([String: ThemeAdjustments].self, from: data)
            } catch {
                errorMessage = "Couldn't read saved appearance settings. Reset this theme to restore its defaults."
            }
        }
    }

    func select(_ theme: AppTheme) {
        baseTheme = theme
        defaults.set(theme.id, forKey: Self.selectionKey)
    }

    func setBackground(_ color: Color.Resolved) {
        update { $0.background = color }
    }

    func exportText(in environment: EnvironmentValues) throws -> String {
        let current = theme
        let export = ThemeSettingsExport(
            themeID: current.id, themeName: current.name,
            background: current.palette.background.resolve(in: environment),
            lighting: current.clock.lighting, shimmer: shimmer, weekday: current.weekday
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(export), as: UTF8.self)
    }

    func resetCurrentTheme() {
        var updated = adjustments
        updated.removeValue(forKey: baseTheme.id)
        save(updated)
    }

    private func update(_ change: (inout ThemeAdjustments) -> Void) {
        var adjustment = adjustments[baseTheme.id] ?? ThemeAdjustments()
        change(&adjustment)
        var updated = adjustments
        updated[baseTheme.id] = adjustment
        save(updated)
    }

    private func save(_ updated: [String: ThemeAdjustments]) {
        do {
            let data = try JSONEncoder().encode(updated)
            defaults.set(data, forKey: Self.adjustmentsKey)
            adjustments = updated
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't save appearance settings. Please try again."
        }
    }
}
