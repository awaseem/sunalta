import AVFAudio
import Observation

@MainActor
@Observable
final class AlarmSoundPreview: NSObject, AVAudioPlayerDelegate {
    private(set) var playingSelection: AlarmSoundSelection?
    private(set) var errorMessage: String?
    @ObservationIgnored private var player: AVAudioPlayer?
    private let resolver: AlarmSoundResolver
    private let makePlayer: (URL) throws -> AVAudioPlayer

    init(resolver: AlarmSoundResolver = .init(),
         makePlayer: @escaping (URL) throws -> AVAudioPlayer = { try AVAudioPlayer(contentsOf: $0) }) {
        self.resolver = resolver
        self.makePlayer = makePlayer
        super.init()
    }

    func toggle(_ selection: AlarmSoundSelection) {
        let wasPlaying = playingSelection == selection
        stop()
        guard !wasPlaying else { return }
        guard let url = resolver.url(for: selection) else {
            errorMessage = "This sound can't be previewed. The alarm will use the system sound."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
            let player = try makePlayer(url)
            player.delegate = self
            player.numberOfLoops = 0
            guard player.play() else { throw CocoaError(.fileReadUnknown) }
            self.player = player
            playingSelection = selection
        } catch {
            errorMessage = "Couldn't preview this sound. \(error.localizedDescription)"
        }
    }

    func stop() {
        player?.delegate = nil
        player?.stop()
        player = nil
        playingSelection = nil
        errorMessage = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === self.player else { return }
        stop()
        if !flag { errorMessage = "The sound preview was interrupted. Please try again." }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        guard player === self.player else { return }
        stop()
        errorMessage = "Couldn't play this sound. Please try again."
    }

    /// Stop on audio interruptions and route disconnections; resuming requires an explicit tap.
    func observeInterruptions() async {
        let notifications = NotificationCenter.default.notifications(
            named: AVAudioSession.didBecomeInactiveNotification, object: AVAudioSession.sharedInstance()
        ).map { _ in true }
        for await _ in notifications {
            guard !Task.isCancelled else { return }
            stop()
        }
    }
}
