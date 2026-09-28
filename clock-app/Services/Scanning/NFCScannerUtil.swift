// Adapted from Foqos. Copyright (c) 2024 Ali Waseem. See Licenses/Foqos-MIT.txt.
@preconcurrency import CoreNFC
import Foundation

struct NFCResult: Equatable {
    let id: String
    let dateScanned: Date
}

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
        let sessionID = ObjectIdentifier(session)
        session.connect(to: tag) { [weak self] error in
            DispatchQueue.main.async {
                guard let self, let session = self.nfcSession,
                      ObjectIdentifier(session) == sessionID else { return }
                if let error {
                    session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                    return
                }
                let result = NFCResult(
                    id: AlarmStopTarget.nfcIdentifier(from: identifier), dateScanned: Date()
                )
                self.nfcSession = nil
                session.alertMessage = "Tag scanned."
                session.invalidate()
                self.onTagScanned?(result)
            }
        }
    }
}
