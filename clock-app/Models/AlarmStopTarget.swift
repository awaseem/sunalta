import Foundation
import SwiftData

@Model
final class AlarmStopTarget {
    @Attribute(.unique) private(set) var id: UUID
    var name: String
    private var kindValue: String
    private(set) var codeValue: String
    var alarms: [AlarmRecord] = []

    enum Kind: String {
        case nfc, qrCode
    }

    var kind: Kind? { Kind(rawValue: kindValue) }

    init(name: String, kind: Kind, codeValue: String) throws {
        self.id = UUID()
        self.name = name
        self.kindValue = kind.rawValue
        self.codeValue = Self.normalizedCodeValue(codeValue, kind: kind)
        try validate()
    }

    func validate() throws {
        guard let kind, Self.isValidScan(codeValue: codeValue, kind: kind) else {
            throw AlarmValidationError.invalidScanTarget
        }
    }

    func matches(codeValue: String, kind: Kind) -> Bool {
        guard self.kind == kind, (try? validate()) != nil else { return false }
        return self.codeValue == Self.normalizedCodeValue(codeValue, kind: kind)
    }

    static func isValidScan(codeValue: String, kind: Kind) -> Bool {
        !normalizedCodeValue(codeValue, kind: kind).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func nfcIdentifier(from data: Data) -> String {
        data.map { String(format: "%02hhX", $0) }.joined()
    }

    private static func normalizedCodeValue(_ value: String, kind: Kind) -> String {
        // Specific QR codes match their exact payload, including URL spelling.
        if kind == .qrCode { return value }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
