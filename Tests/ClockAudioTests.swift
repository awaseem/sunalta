import AVFAudio
import Foundation
import Testing
@testable import Sunalta

@Suite(.serialized)
@MainActor
struct ClockAudioTests {
    @Test func returningToTheClockCanResumeAfterAnInterruptionEndsWithoutAutomaticResumption()
        throws
    {
        let suite = "ClockAudioTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let (audio, player) = try makeDelayedMusic(defaults: defaults, delay: .seconds(10))
        defer { audio.updateAmbience(isVisible: false) }
        audio.updateAmbience(isVisible: true)
        try #require(player.isPlaying)

        audio.audioSessionDidDeactivate(wasInterrupted: true)
        audio.audioSessionMayResume(.shouldNotResume)
        audio.updateAmbience(isVisible: true)
        #expect(
            !player.isPlaying,
            "An ended interruption must not resume against the system recommendation")

        audio.updateAmbience(isVisible: false)
        audio.updateAmbience(isVisible: true)

        #expect(
            player.isPlaying,
            "Returning to the clock is a new playback request, not a continuing interruption")
    }

    @Test func aDelayedNoninterruptionDeactivationCannotSilenceTheForegroundClock() throws {
        let suite = "ClockAudioTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let (audio, player) = try makeDelayedMusic(defaults: defaults, delay: .seconds(10))
        defer { audio.updateAmbience(isVisible: false) }
        audio.updateAmbience(isVisible: true)
        audio.updateAmbience(isVisible: false)
        audio.audioSessionDidDeactivate(wasInterrupted: false)
        #expect(!player.isPlaying, "The background clock must stay silent")
        audio.updateAmbience(isVisible: true)
        try #require(player.isPlaying)

        // A queued session notification can be delivered after the scene becomes active.
        audio.audioSessionDidDeactivate(wasInterrupted: false)

        #expect(player.isPlaying)
        audio.musicEnabled = false
        audio.audioSessionDidDeactivate(wasInterrupted: false)
        #expect(!player.isPlaying, "Recovery must respect the Music setting")
    }

    @Test func foregroundingDuringAnOngoingInterruptionWaitsForPermissionToResume() throws {
        let suite = "ClockAudioTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let (audio, player) = try makeDelayedMusic(defaults: defaults, delay: .seconds(10))
        defer { audio.updateAmbience(isVisible: false) }
        audio.updateAmbience(isVisible: true)
        try #require(player.isPlaying)

        audio.audioSessionDidDeactivate(wasInterrupted: true)
        audio.updateAmbience(isVisible: false)
        audio.updateAmbience(isVisible: true)
        audio.audioSessionDidDeactivate(wasInterrupted: false)
        #expect(!player.isPlaying)

        audio.audioSessionMayResume(.shouldResume)
        #expect(player.isPlaying)
    }

    @Test func musicWaitsAfterFinishingAndPageUpdatesCannotSkipTheGap() async throws {
        let suite = "ClockAudioTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let (audio, player) = try makeDelayedMusic(defaults: defaults, delay: .seconds(1))
        defer { audio.updateAmbience(isVisible: false) }
        audio.updateAmbience(isVisible: true)
        try #require(player.isPlaying, "The first play should start without the repeat delay")

        player.currentTime = player.duration - 0.1
        try await waitForPlayback(false, player: player)
        let finishedAt = ContinuousClock.now
        for _ in 0..<5 { audio.updateAmbience(isVisible: true) }
        audio.audioSessionDidDeactivate(wasInterrupted: false)
        #expect(!player.isPlaying)

        // Even a quick toggle must preserve the rest of the gap.
        audio.musicEnabled = false
        audio.musicEnabled = true
        #expect(!player.isPlaying)
        try await waitForPlayback(true, player: player)
        #expect(finishedAt.duration(to: .now) >= .milliseconds(900))
        #expect(player.currentTime < 1, "A repeat must start from the beginning")
    }

    @Test(arguments: ["hiddenClock", "disabledMusic", "differentTheme"])
    func pendingRepeatDoesNotPlayAfterCancellation(_ reason: String) async throws {
        let suite = "ClockAudioTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let (audio, player) = try makeDelayedMusic(defaults: defaults, delay: .milliseconds(200))
        defer { audio.updateAmbience(isVisible: false) }
        audio.updateAmbience(isVisible: true)
        try #require(player.isPlaying)
        player.currentTime = player.duration - 0.1
        try await waitForPlayback(false, player: player)

        switch reason {
        case "hiddenClock": audio.updateAmbience(isVisible: false)
        case "disabledMusic": audio.musicEnabled = false
        default: audio.apply(configuration: .init())
        }
        try await Task.sleep(for: .milliseconds(350))
        #expect(!player.isPlaying, "A canceled replay must stay silent")
    }

    @Test func themeChangesReplaceEffectsWithoutRestartingUnchangedMusicAndCanBecomeSilent() throws {
        let suite = "ClockAudioTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var players: [AVAudioPlayer] = []
        let audio = ClockAudioService(defaults: defaults) { sound in
            let url = try #require(Bundle.main.url(forResource: sound.fileName, withExtension: nil))
            let player = try AVAudioPlayer(contentsOf: url)
            players.append(player)
            return player
        }
        defer { audio.updateAmbience(isVisible: false) }
        // Use a muted effect as a short loop fixture.
        let music = ClockSound(fileName: "bat-sounds.wav", volume: 0)
        let flyby = ClockSound(fileName: "bird-sounds.wav", volume: 0)
        let entrance = ClockSound(fileName: "clock-entrance.wav", volume: 0)
        let original = ClockAudioConfiguration(music: music, flyby: flyby, entrance: entrance)
        audio.apply(configuration: original)
        audio.updateAmbience(isVisible: true)
        audio.prepareFlight()
        audio.beginFlight()
        audio.playEntrance()

        try #require(players.count == 3)
        let musicPlayer = try #require(players.first { $0.url?.lastPathComponent == music.fileName })
        let flybyPlayer = try #require(players.first { $0.url?.lastPathComponent == flyby.fileName })
        let entrancePlayer = try #require(players.first { $0.url?.lastPathComponent == entrance.fileName })
        #expect(players.allSatisfy { $0.isPlaying })
        musicPlayer.currentTime = 2

        // Repeated page updates must preserve both the player and playback position.
        audio.apply(configuration: original)
        audio.updateAmbience(isVisible: true)
        #expect(players.count == 3)
        #expect(musicPlayer.currentTime >= 1.9)

        // A theme can replace just its effects while sharing the existing music.
        audio.apply(configuration: .init(music: music, flyby: entrance, entrance: flyby))
        #expect(!flybyPlayer.isPlaying)
        #expect(!entrancePlayer.isPlaying)
        #expect(musicPlayer.isPlaying)
        audio.updateAmbience(isVisible: true)
        audio.prepareFlight()
        audio.beginFlight()
        audio.playEntrance()
        try #require(players.count == 5)
        #expect(players.suffix(2).allSatisfy { $0.isPlaying })
        #expect(Set(players.suffix(2).compactMap { $0.url?.lastPathComponent })
                == Set([flyby.fileName, entrance.fileName]))
        #expect(musicPlayer.currentTime >= 1.9)

        // Nil layers must stop existing clips and must not reload them on later events.
        audio.apply(configuration: .init())
        audio.updateAmbience(isVisible: true)
        audio.prepareFlight()
        audio.beginFlight()
        audio.playEntrance()
        #expect(players.allSatisfy { !$0.isPlaying })
        #expect(players.count == 5)
    }

    private func makeDelayedMusic(defaults: UserDefaults, delay: Duration) throws
        -> (ClockAudioService, AVAudioPlayer) {
        let url = try #require(Bundle.main.url(forResource: "white-dawn.mp3", withExtension: nil))
        let player = try AVAudioPlayer(contentsOf: url)
        let audio = ClockAudioService(defaults: defaults) { _ in player }
        audio.apply(configuration: .init(
            music: ClockSound(fileName: "white-dawn.mp3", volume: 0),
            musicLoopDelay: delay
        ))
        return (audio, player)
    }

    private func waitForPlayback(_ isPlaying: Bool, player: AVAudioPlayer) async throws {
        let timeout = ContinuousClock.now.advanced(by: .seconds(3))
        while player.isPlaying != isPlaying && ContinuousClock.now < timeout {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(player.isPlaying == isPlaying, "The music must reach the expected playback state")
    }
}
