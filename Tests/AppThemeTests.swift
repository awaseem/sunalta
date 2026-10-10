import Foundation
import SwiftUI
import Testing
@testable import clock_app

@MainActor
struct AppThemeTests {
    @Test func whiteThemeUsesBlackContentAndControlsOnWhite() {
        let theme = AppTheme.white
        #expect(theme.palette.background == .white)
        #expect(theme.clock.numeralColor == .black)
        #expect(theme.palette.foreground == .black)
        #expect(theme.palette.control == .black)
        #expect(theme.palette.selection == .black)
        #expect(theme.palette.onControl == .white)
        #expect(theme.colorScheme == .light)
    }

    @Test func missingOrRemovedThemeFallsBackToTheDefault() {
        #expect(AppTheme.resolve(id: nil) == .defaultTheme)
        #expect(AppTheme.resolve(id: "removed-theme") == .defaultTheme)
    }

    @Test func themeCatalogHasUniquePersistentIdentifiers() {
        #expect(Set(AppTheme.available.map(\.id)).count == AppTheme.available.count)
        #expect(AppTheme.available.contains(.defaultTheme))
    }

    @Test func selectionSurvivesSettingsRecreation() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ThemeSettings(defaults: defaults)
        settings.select(.white)

        #expect(defaults.string(forKey: "selectedThemeID") == AppTheme.white.id)
        #expect(ThemeSettings(defaults: defaults).theme == .white)
    }

    @Test func invalidSavedSelectionStillLaunchesWithDefaultTheme() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("removed-theme", forKey: "selectedThemeID")

        #expect(ThemeSettings(defaults: defaults).theme == .defaultTheme)
    }

    @Test func lightingShimmerAndBackgroundSurviveSettingsRecreation() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ThemeSettings(defaults: defaults)
        settings.lighting.direction = -70
        settings.lighting.tilt = 35
        settings.lighting.strength = 4200
        settings.lighting.fill = 1.2
        settings.shimmer = 0.85
        let background = Color.Resolved(red: 0.8, green: 0.7, blue: 0.6)
        settings.setBackground(background)

        let restored = ThemeSettings(defaults: defaults)
        #expect(restored.lighting == settings.lighting)
        #expect(restored.shimmer == 0.85)
        #expect(restored.theme.palette.background == Color(background))
        #expect(abs(restored.theme.clock.roughness - 0.06) < 0.0001)
    }

    @Test func adjustmentsAndResetApplyOnlyToTheSelectedTheme() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ThemeSettings(defaults: defaults)
        let other = AppTheme(id: "other", name: "Other", colorScheme: .light,
                             palette: AppTheme.white.palette, clock: AppTheme.white.clock,
                             panelShadow: AppTheme.white.panelShadow)
        settings.lighting.direction = -90
        settings.shimmer = 0.2
        settings.select(other)
        #expect(settings.lighting == other.clock.lighting)
        settings.lighting.direction = 120
        settings.shimmer = 0.9

        settings.select(.white)
        #expect(settings.lighting.direction == -90)
        #expect(settings.shimmer == 0.2)
        settings.resetCurrentTheme()
        #expect(settings.theme == .white)
        #expect(ThemeSettings(defaults: defaults).theme == .white)

        settings.select(other)
        #expect(settings.lighting.direction == 120)
        #expect(settings.shimmer == 0.9)
    }

    @Test func lightingChangesPreserveTheAuthoredFinishUntilShimmerIsCustomized() {
        var clock = AppTheme.white.clock
        clock.roughness = 0.8
        let theme = AppTheme(id: "matte", name: "Matte", colorScheme: .light,
                             palette: AppTheme.white.palette, clock: clock,
                             panelShadow: AppTheme.white.panelShadow)
        let adjustments = ThemeAdjustments(lighting: ClockLightingSettings(direction: 90))

        #expect(adjustments.applying(to: theme).clock.roughness == 0.8)
    }

    @Test func malformedSavedAdjustmentsLeaveTheAuthoredThemeUsable() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid settings".utf8), forKey: "themeAdjustmentsV1")

        let settings = ThemeSettings(defaults: defaults)
        #expect(settings.theme == .defaultTheme)
        #expect(settings.errorMessage != nil)
        settings.resetCurrentTheme()
        #expect(settings.errorMessage == nil)
        #expect(ThemeSettings(defaults: defaults).theme == .defaultTheme)
    }
}
