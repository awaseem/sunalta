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
        guard let kind, !Self.normalizedCodeValue(codeValue, kind: kind).isEmpty else {
            throw AlarmValidationError.invalidScanTarget
        }
    }

    func matches(codeValue: String, kind: Kind) -> Bool {
        guard self.kind == kind, (try? validate()) != nil else { return false }
        return self.codeValue == Self.normalizedCodeValue(codeValue, kind: kind)
    }

    static func isValidScan(codeValue: String, kind: Kind) -> Bool {
        !normalizedCodeValue(codeValue, kind: kind).isEmpty
    }

    static func nfcIdentifier(from data: Data) -> String {
        data.map { String(format: "%02hhX", $0) }.joined()
    }

    private static func normalizedCodeValue(_ value: String, kind: Kind) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard kind == .qrCode,
              var components = URLComponents(string: trimmed),
              components.scheme != nil, components.host != nil else {
            return trimmed
        }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        if components.path == "/" && components.query == nil && components.fragment == nil {
            components.path = ""
        }
        return components.string ?? trimmed
    }
}
