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
