import AVFAudio
import Observation
import OSLog

/// Owns decorative clock audio independently of the system's AlarmKit alerts.
@MainActor
@Observable
final class ClockAudioService: NSObject, AVAudioPlayerDelegate {
    var musicEnabled: Bool {
        didSet {
            defaults.set(musicEnabled, forKey: Self.musicKey)
            updateAmbientPlayback()
        }
    }

    var soundEffectsEnabled: Bool {
        didSet {
            defaults.set(soundEffectsEnabled, forKey: Self.effectsKey)
            if soundEffectsEnabled {
                prepareEntrance()
            } else {
                stopFlight()
                stopEntrance()
            }
        }
    }

    private static let effectsKey = "clockSoundEffectsEnabled"
    private static let musicKey = "clockMusicEnabled"
    private let defaults: UserDefaults
    private let makePlayer: @MainActor (ClockSound) throws -> AVAudioPlayer
    private let logger = Logger(subsystem: "dev.ambitionsoftware.sunalta", category: "ClockAudio")
    @ObservationIgnored private var configuration = ClockAudioConfiguration()
    @ObservationIgnored private var flybyPlayer: AVAudioPlayer?
    @ObservationIgnored private var ambientPlayer: AVAudioPlayer?
    @ObservationIgnored private var isAmbientPlaybackStarted = false
    @ObservationIgnored private var ambientReplayDeadline: ContinuousClock.Instant?
    @ObservationIgnored private var ambientReplayTask: Task<Void, Never>?
    @ObservationIgnored private var entrancePlayer: AVAudioPlayer?
    @ObservationIgnored private var isClockVisible = false
    @ObservationIgnored private var isInterrupted = false
    @ObservationIgnored private var observationTasks: [Task<Void, Never>] = []

    init(defaults: UserDefaults = .standard,
         makePlayer: @escaping @MainActor (ClockSound) throws -> AVAudioPlayer = ClockAudioService.loadPlayer) {
        self.defaults = defaults
        self.makePlayer = makePlayer
        soundEffectsEnabled = defaults.object(forKey: Self.effectsKey) as? Bool ?? true
        musicEnabled = defaults.object(forKey: Self.musicKey) as? Bool ?? true
        super.init()
        observeAudioSession()
    }

    deinit {
        ambientReplayTask?.cancel()
        for task in observationTasks { task.cancel() }
    }

    /// Apply before updating the renderer so its next animation uses the new theme's sounds.
    func apply(configuration: ClockAudioConfiguration) {
        guard self.configuration != configuration else { return }
        if self.configuration.music != configuration.music
            || self.configuration.musicLoopDelay != configuration.musicLoopDelay {
            cancelAmbientReplay()
            ambientReplayDeadline = nil
            isAmbientPlaybackStarted = false
            ambientPlayer?.delegate = nil
            ambientPlayer?.stop()
            ambientPlayer = nil
        }
        if self.configuration.flyby != configuration.flyby {
            stopFlight()
            flybyPlayer = nil
        }
        if self.configuration.entrance != configuration.entrance {
            stopEntrance()
            entrancePlayer = nil
        }
        self.configuration = configuration
    }

    /// Music follows the visible numeral scene, independently of flight and orbit animation.
    func updateAmbience(isVisible: Bool) {
        let becameVisible = isVisible && !isClockVisible
        isClockVisible = isVisible
        if becameVisible || entrancePlayer == nil { prepareEntrance() }
        if !isVisible {
            stopEntrance()
            stopFlight()
        }
        updateAmbientPlayback()
    }

    private func prepareEntrance() {
        guard let sound = configuration.entrance, isClockVisible, soundEffectsEnabled, !isInterrupted,
              ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        do {
            try configureAudioSession()
            if entrancePlayer == nil {
                entrancePlayer = try makePlayer(sound)
            }
            if entrancePlayer?.prepareToPlay() == false {
                logger.error("Could not prepare the clock entrance sound.")
            }
        } catch {
            logger.error("Could not prepare the clock entrance sound: \(error.localizedDescription)")
        }
    }

    /// Called once when the numeral entrance begins, never by interactive rotation.
    func playEntrance() {
        guard let sound = configuration.entrance, isClockVisible, soundEffectsEnabled, !isInterrupted,
              ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1",
              entrancePlayer?.isPlaying != true else { return }
        if entrancePlayer == nil { prepareEntrance() }
        guard let entrancePlayer else { return }
        entrancePlayer.currentTime = 0
        entrancePlayer.volume = sound.volume
        if !entrancePlayer.play() {
            logger.error("Could not play the clock entrance sound.")
        }
    }

    func stopEntrance() {
        entrancePlayer?.stop()
        entrancePlayer?.currentTime = 0
    }

    private func updateAmbientPlayback() {
        guard let sound = configuration.music, isClockVisible, musicEnabled, !isInterrupted,
              ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            pauseAmbientPlayback()
            return
        }
        if let deadline = ambientReplayDeadline {
            guard deadline <= .now else {
                scheduleAmbientReplay(at: deadline)
                return
            }
            cancelAmbientReplay()
            ambientReplayDeadline = nil
        }
        // Page updates and repeated visits must not restart the music or its fade.
        // Keep the play request active until the completion callback has scheduled its gap.
        guard !isAmbientPlaybackStarted else { return }
        do {
            try configureAudioSession()
            if ambientPlayer == nil {
                let player = try makePlayer(sound)
                player.numberOfLoops = configuration.musicLoopDelay > .zero ? 0 : -1
                player.delegate = self
                ambientPlayer = player
            }
            guard let ambientPlayer else { return }
            ambientPlayer.volume = 0
            guard ambientPlayer.play() else {
                logger.error("Could not play the theme music.")
                return
            }
            isAmbientPlaybackStarted = true
            ambientPlayer.setVolume(sound.volume, fadeDuration: 0.6)
        } catch {
            logger.error("Could not prepare theme music: \(error.localizedDescription)")
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === ambientPlayer else { return }
        isAmbientPlaybackStarted = false
        guard flag else {
            logger.error("The theme music did not finish successfully.")
            return
        }
        player.currentTime = 0
        ambientReplayDeadline = .now.advanced(by: max(.zero, configuration.musicLoopDelay))
        updateAmbientPlayback()
    }

    private func scheduleAmbientReplay(at deadline: ContinuousClock.Instant) {
        guard ambientReplayTask == nil else { return }
        ambientReplayTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(until: deadline, clock: .continuous)
                try Task.checkCancellation()
                guard let self, ambientReplayDeadline == deadline else { return }
                ambientReplayTask = nil
                updateAmbientPlayback()
            } catch {
                // Hidden clocks, disabled music and theme changes cancel pending replays.
            }
        }
    }

    private func pauseAmbientPlayback() {
        cancelAmbientReplay()
        ambientPlayer?.pause()
        isAmbientPlaybackStarted = false
        // Keep the deadline so returning during the gap cannot skip its remaining silence.
    }

    private func cancelAmbientReplay() {
        ambientReplayTask?.cancel()
        ambientReplayTask = nil
    }

    private static func loadPlayer(for sound: ClockSound) throws -> AVAudioPlayer {
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: nil) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: sound.fileName])
        }
        return try AVAudioPlayer(contentsOf: url)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        // Play through Silent mode without interrupting or lowering other apps' music.
        if session.category != .playback || session.mode != .default || session.categoryOptions != .mixWithOthers {
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
        }
        if !session.prefersInterruptionOnRouteDisconnect {
            try session.setPrefersInterruptionOnRouteDisconnect(true)
        }
    }

    /// Prepare during the wait before a visit, away from the animation's first frame.
    func prepareFlight() {
        guard let sound = configuration.flyby, soundEffectsEnabled, !isInterrupted,
              ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        do {
            try configureAudioSession()
            if flybyPlayer == nil {
                flybyPlayer = try makePlayer(sound)
            }
            flybyPlayer?.volume = 0
            flybyPlayer?.currentTime = 0
            if flybyPlayer?.prepareToPlay() == false {
                logger.error("Could not prepare the flyby sound.")
            }
        } catch {
            logger.error("Could not prepare clock audio: \(error.localizedDescription)")
        }
    }

    func beginFlight() {
        guard configuration.flyby != nil, isClockVisible, soundEffectsEnabled, !isInterrupted else { return }
        if flybyPlayer == nil { prepareFlight() }
        guard let flybyPlayer else { return }
        flybyPlayer.currentTime = 0
        flybyPlayer.volume = 0
        if !flybyPlayer.play() {
            logger.error("Could not play the flyby sound.")
        }
    }

    /// Follow the animals' existing fade envelope; frame updates never restart playback.
    func updateFlight(visibility: Float) {
        guard let sound = configuration.flyby, soundEffectsEnabled, !isInterrupted else { return }
        flybyPlayer?.volume = min(max(visibility, 0), 1) * sound.volume
    }

    func stopFlight() {
        flybyPlayer?.stop()
        flybyPlayer?.currentTime = 0
        flybyPlayer?.volume = 0
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        let deactivations = center.notifications(named: AVAudioSession.didBecomeInactiveNotification, object: session)
            .compactMap { $0.userInfo?[AVAudioSession.deactivationContextKey] as? AVAudioSession.DeactivationContext }
        let resumptions = center.notifications(named: AVAudioSession.resumptionRecommendationNotification, object: session)
            .compactMap { $0.userInfo?[AVAudioSession.resumptionContextKey] as? AVAudioSession.ResumptionContext }
        observationTasks = [
            Task { @MainActor [weak self] in
                for await context in deactivations {
                    guard !Task.isCancelled else { return }
                    if context.interruptionContext != nil { self?.isInterrupted = true }
                    self?.stopFlight()
                    self?.stopEntrance()
                    self?.pauseAmbientPlayback()
                }
            },
            Task { @MainActor [weak self] in
                for await context in resumptions {
                    guard !Task.isCancelled else { return }
                    self?.isInterrupted = context.recommendation != .shouldResume
                    self?.updateAmbientPlayback()
                    // Resume only on the next visit, never replay an interrupted flight.
                }
            }
        ]
    }
}
