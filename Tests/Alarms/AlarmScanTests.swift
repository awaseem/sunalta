import Foundation
import Testing
@testable import Sunalta

@MainActor
struct AlarmScanTests {
    @Test func nfcIdentifiersKeepUppercaseHexAndLeadingZeros() {
        #expect(AlarmStopTarget.nfcIdentifier(from: Data([0x00, 0x01, 0x0F, 0xA0, 0xFF])) == "00010FA0FF")
    }

    @Test func specificNFCMatchesNormalizedIdentifiers() throws {
        let target = try AlarmStopTarget(name: "Tag", kind: .nfc, codeValue: " 0abc\n")
        let alarm = try AlarmRecord(hour: 7, minute: 0, exitPoint: .nfc, stopTargets: [target])
        #expect(alarm.acceptsScan(codeValue: "0ABC", kind: .nfc))
        #expect(!alarm.acceptsScan(codeValue: "0ABD", kind: .nfc))
        #expect(!alarm.acceptsScan(codeValue: "0ABC", kind: .qrCode))
    }

    @Test func specificQRRequiresTheExactPayload() throws {
        let target = try AlarmStopTarget(name: "Code", kind: .qrCode, codeValue: "https://example.com/Wake\n")
        let alarm = try AlarmRecord(hour: 7, minute: 0, exitPoint: .qrCode, stopTargets: [target])
        #expect(alarm.acceptsScan(codeValue: "https://example.com/Wake\n", kind: .qrCode))
        #expect(!alarm.acceptsScan(codeValue: "https://example.com/wake\n", kind: .qrCode))
        #expect(!alarm.acceptsScan(codeValue: "https://example.com/Wake", kind: .qrCode))
    }

    @Test func anyQRRejectsEmptyPayloadsAndOtherScanKinds() throws {
        let alarm = try AlarmRecord(hour: 7, minute: 0, exitPoint: .qrCode)
        #expect(alarm.acceptsScan(codeValue: "any valid code", kind: .qrCode))
        #expect(!alarm.acceptsScan(codeValue: " \n", kind: .qrCode))
        #expect(!alarm.acceptsScan(codeValue: "0ABC", kind: .nfc))
    }

    @Test func switchingExitPointClearsThePreviouslyScannedCode() {
        var draft = AlarmExitPointDraft(selection: .nfc, scannedCode: .init(kind: .nfc, value: "0ABC"))
        draft.select(.qrCode)
        #expect(draft.selection == .qrCode)
        #expect(draft.scannedCode == nil)
    }

    @Test func mismatchedTargetIsRejected() throws {
        let target = try AlarmStopTarget(name: "Tag", kind: .nfc, codeValue: "0ABC")
        #expect(throws: AlarmValidationError.invalidScanTarget) {
            try AlarmRecord(hour: 7, minute: 0, exitPoint: .qrCode, stopTargets: [target])
        }
    }

    @Test func invalidTimeDoesNotReplaceTheExistingTime() throws {
        let alarm = try AlarmRecord(hour: 7, minute: 30)
        #expect(throws: AlarmValidationError.invalidTime) { try alarm.setTime(hour: 24, minute: 0) }
        #expect(alarm.hour == 7 && alarm.minute == 30)
    }
}
