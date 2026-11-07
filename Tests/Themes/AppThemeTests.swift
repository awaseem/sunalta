import Foundation
import SwiftUI
import Testing
@testable import Sunalta

@MainActor
struct AppThemeTests {
    @Test func browsingThemePreviewsPreservesSelectionAndSavedAdjustments() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ThemeSettings(defaults: defaults)
        settings.select(.grass)
        settings.lighting.direction = -70
        settings.shimmer = 0.2
        settings.select(.midnight)

        let preview = settings.appearance(for: .grass)

        #expect(preview.clock.lighting.direction == -70)
        #expect(preview == ThemeSettings(defaults: defaults).appearance(for: .grass))
        #expect(settings.theme.id == AppTheme.midnight.id)
        #expect(ThemeSettings(defaults: defaults).theme.id == AppTheme.midnight.id)
        settings.select(.grass)
        #expect(settings.theme == preview)
        #expect(settings.shimmer == 0.2)
    }

    @Test func appearanceEditsAndReloadPreserveTheSelectedThemesAnimalsAndAudio() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ThemeSettings(defaults: defaults)

        for theme in AppTheme.available {
            settings.select(theme)
            settings.lighting.direction = -70
            settings.shimmer = 0.85
            settings.weekday.size = 36

            #expect(settings.theme.clockFlyby == theme.clockFlyby)
            #expect(settings.theme.audio == theme.audio)
            let restored = ThemeSettings(defaults: defaults)
            #expect(restored.theme.id == theme.id)
            #expect(restored.theme.clockFlyby == theme.clockFlyby)
            #expect(restored.theme.audio == theme.audio)
        }
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
        settings.weekday.size = 36
        settings.weekday.weight = .bold
        settings.weekday.glow.color = Color.Resolved(red: 0.2, green: 0.8, blue: 1)
        settings.weekday.glow.halo = 0.4
        settings.weekday.glow.brightness = 4800
        settings.weekday.glow.spread = 45
        settings.weekday.glow.direction = -25
        settings.weekday.glow.reach = 7
        let background = Color.Resolved(red: 0.8, green: 0.7, blue: 0.6)
        settings.setBackground(background)

        let restored = ThemeSettings(defaults: defaults)
        #expect(restored.lighting == settings.lighting)
        #expect(restored.shimmer == 0.85)
        #expect(restored.weekday == settings.weekday)
        #expect(restored.theme.palette.background == Color(background))
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
        settings.weekday.size = 28
        settings.weekday.weight = .thin
        settings.weekday.glow.direction = -30
        settings.select(other)
        #expect(settings.lighting == other.clock.lighting)
        settings.lighting.direction = 120
        settings.shimmer = 0.9
        settings.weekday.size = 44
        settings.weekday.weight = .heavy
        settings.weekday.glow.direction = 40

        settings.select(.white)
        #expect(settings.lighting.direction == -90)
        #expect(settings.shimmer == 0.2)
        #expect(settings.weekday.size == 28)
        #expect(settings.weekday.weight == .thin)
        #expect(settings.weekday.glow.direction == -30)
        settings.resetCurrentTheme()
        #expect(settings.theme == .white)
        #expect(ThemeSettings(defaults: defaults).theme == .white)

        settings.select(other)
        #expect(settings.lighting.direction == 120)
        #expect(settings.shimmer == 0.9)
        #expect(settings.weekday.size == 44)
        #expect(settings.weekday.weight == .heavy)
        #expect(settings.weekday.glow.direction == 40)
    }

    @Test func savedWeekdayTypographyAdoptsTheThemesNewGlowDefaults() throws {
        let data = Data(#"{"weekday":{"size":46,"weight":"Semibold"}}"#.utf8)
        let adjustment = try JSONDecoder().decode(ThemeAdjustments.self, from: data)
        var theme = AppTheme.white
        theme.weekday.glow.color = Color.Resolved(red: 0.1, green: 0.7, blue: 1)
        theme.weekday.glow.brightness = 1800

        let restored = adjustment.applying(to: theme)
        #expect(restored.weekday.size == 46)
        #expect(restored.weekday.weight == .semibold)
        #expect(restored.weekday.glow == theme.weekday.glow)
    }

    @Test func typographyEditsKeepUnchangedGlowFollowingTheAuthoredTheme() throws {
        let suite = "ThemeSettingsTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ThemeSettings(defaults: defaults)
        settings.weekday.size = 40

        var updatedTheme = AppTheme.white
        updatedTheme.weekday.glow.brightness = 1800
        settings.select(updatedTheme)

        #expect(settings.weekday.size == 40)
        #expect(settings.weekday.glow.brightness == 1800)
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
