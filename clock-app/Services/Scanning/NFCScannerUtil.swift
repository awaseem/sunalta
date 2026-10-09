// Adapted from Foqos. Copyright (c) 2024 Ali Waseem. See Licenses/Foqos-MIT.txt.
@preconcurrency import CoreNFC
import Foundation

@MainActor
final class NFCScannerUtil: NSObject {
    var onTagScanned: ((NFCResult) -> Void)?
    var onError: ((String) -> Void)?

    private var nfcSession: NFCTagReaderSession?

    func scan(alarmName: String) {
        guard nfcSession == nil else { return }
        guard NFCTagReaderSession.readingAvailable else {
            onError?("NFC scanning is not available on this device.")
            return
        }
        let session = NFCTagReaderSession(
            configuration: .init(pollingOption: [.iso14443, .iso15693]),
            delegate: self, queue: .main
        )
        nfcSession = session
        session.alertMessage = "Hold your iPhone near an NFC tag for " + alarmName
        session.begin()
    }

    func cancel() {
        nfcSession?.invalidate()
        nfcSession = nil
    }
}

extension NFCScannerUtil: @preconcurrency NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard nfcSession === session else { return }
        nfcSession = nil
        if let error = error as? NFCReaderError,
           error.code == .readerSessionInvalidationErrorUserCanceled {
            return
        }
        onError?(error.localizedDescription)
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard nfcSession === session else { return }
        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = "Hold only one NFC tag near your iPhone."
            session.restartPolling()
            return
        }
        let identifier: Data
        switch tag {
        case .iso15693(let tag): identifier = tag.identifier
        case .iso7816(let tag): identifier = tag.identifier
        case .miFare(let tag): identifier = tag.identifier
        default:
            session.invalidate(errorMessage: "Unsupported tag type.")
            return
        }
        guard !identifier.isEmpty else {
            session.invalidate(errorMessage: "This tag has no identifier.")
            return
        }
        Task { [weak self] in
            do {
                try await Self.connect(session, to: tag)
                guard let self, nfcSession === session, !Task.isCancelled else { return }
                let result = NFCResult(
                    id: AlarmStopTarget.nfcIdentifier(from: identifier), dateScanned: .now
                )
                nfcSession = nil
                session.alertMessage = "Tag scanned."
                session.invalidate()
                onTagScanned?(result)
            } catch {
                guard let self, nfcSession === session else { return }
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
            }
        }
    }

    private static func connect(_ session: NFCTagReaderSession, to tag: NFCTag) async throws {
        // The SDK's async overlay sends non-Sendable NFC objects off this actor.
        // Start the connection on the delegate's main queue; only the continuation crosses it.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.connect(to: tag) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}
