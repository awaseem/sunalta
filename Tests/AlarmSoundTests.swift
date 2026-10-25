import ActivityKit
import AVFAudio
import Foundation
import SwiftData
import Testing
@testable import clock_app

@Suite(.serialized)
@MainActor
struct AlarmSoundTests {
    @Test(arguments: ["white", "midnight", "grass"])
    func themeDefaultSurvivesSavingAndEditingUnderAnotherTheme(themeID: String) async throws {
        let theme = try #require(AppTheme.available.first { $0.id == themeID })
        let container = try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let service = AlarmEditorService(context: container.mainContext)
        let created = try service.create(AlarmEditorDraft(theme: theme))
        let context = ModelContext(container)
        let saved = try #require(context.fetch(FetchDescriptor<AlarmRecord>()).first)
        let otherTheme = themeID == "grass" ? AppTheme.midnight : .grass
        var reopened = AlarmEditorDraft(alarm: saved, theme: otherTheme)
        #expect(reopened.soundSelection == .theme(themeID))
        #expect(AlarmSoundResolver().alertSound(for: reopened.soundSelection)
                == .named(try #require(theme.audio.alarm).rawValue))
        reopened.name = "Renamed under another theme"
        try await AlarmEditorService(context: context).update(reopened, alarm: saved)
        let fetched = try #require(ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(fetched.id == created.id && fetched.soundSelection == .theme(themeID))
    }

    @Test(arguments: [nil, "birdsong.caf", AlarmSound.quietOrbit.rawValue] as [String?])
    func editingPreservesLegacyDefaultsAndFixedSoundsAcrossThemes(storedValue: String?) async throws {
        let container = try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let alarm = try AlarmRecord(hour: 7, minute: 0, isEnabled: false, soundName: storedValue)
        container.mainContext.insert(alarm)
        try container.mainContext.save()
        var draft = AlarmEditorDraft(alarm: alarm, theme: .grass)
        draft.name = "Renamed"
        try await AlarmEditorService(context: container.mainContext).update(draft, alarm: alarm)
        let saved = try #require(ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(saved.soundName == storedValue)
        if storedValue == AlarmSound.quietOrbit.rawValue {
            #expect(AlarmSoundResolver().alertSound(for: saved.soundSelection) == .named(AlarmSound.quietOrbit.rawValue))
        }
    }

    @Test func missingResourcesAndUnknownThemesFallBackWithoutChangingTheSavedChoice() throws {
        let resolver = AlarmSoundResolver(resourceURL: { _ in nil })
        let alarm = try AlarmRecord(hour: 7, minute: 0, soundName: "theme:grass")
        #expect(resolver.alertSound(for: alarm.soundSelection) == .default)
        #expect(alarm.soundName == "theme:grass")
        #expect(resolver.url(for: alarm.soundSelection) == nil)
        #expect(AlarmSoundResolver().alertSound(for: .theme("removed-theme")) == .default)
        #expect(AlarmSoundResolver().alertSound(for: .named("missing.wav")) == .default)
        #expect(AlarmSoundResolver().alertSound(for: .systemDefault) == .default)
    }

    @Test(arguments: AlarmSound.allCases)
    func everyShippedSoundIsBundledAndDecodableForPreviewAndAlarm(sound: AlarmSound) throws {
        let resolver = AlarmSoundResolver()
        let url = try #require(resolver.url(for: .named(sound.rawValue)))
        let player = try AVAudioPlayer(contentsOf: url)
        #expect(player.duration > 29 && player.duration < 30)
        #expect(player.format.commonFormat == .pcmFormatFloat32 || player.format.commonFormat == .pcmFormatInt16)
        #expect(resolver.alertSound(for: .named(sound.rawValue)) == .named(url.lastPathComponent))
    }

    @Test func replacingStoppingAndMissingPreviewsNeverLeaveThePreviousSoundPlaying() throws {
        var players: [AVAudioPlayer] = []
        let preview = AlarmSoundPreview { url in
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0
            players.append(player)
            return player
        }
        defer { preview.stop() }
        let white = AlarmSoundSelection.theme(AppTheme.white.id)
        let grass = AlarmSoundSelection.named(AlarmSound.meadowMorning.rawValue)
        preview.toggle(white)
        let first = try #require(players.first)
        try #require(first.isPlaying)
        preview.toggle(grass)
        let second = try #require(players.last)
        #expect(!first.isPlaying && second.isPlaying)
        preview.audioPlayerDidFinishPlaying(first, successfully: true)
        #expect(preview.playingSelection == grass && second.isPlaying)
        preview.toggle(grass)
        #expect(!second.isPlaying && preview.playingSelection == nil)
        preview.toggle(white)
        preview.stop()
        #expect(players.allSatisfy { !$0.isPlaying })
        preview.toggle(white)
        preview.toggle(.named("missing.wav"))
        #expect(players.allSatisfy { !$0.isPlaying })
        #expect(preview.playingSelection == nil && preview.errorMessage != nil)
    }
}
