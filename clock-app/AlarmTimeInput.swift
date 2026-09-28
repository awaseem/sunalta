import Foundation

struct AlarmTimeInput {
    private(set) var digits = ""

    var isComplete: Bool { digits.count == 4 }
    var displayTime: String {
        let padded = digits.padding(toLength: 4, withPad: "0", startingAt: 0)
        return "\(padded.prefix(2)):\(padded.suffix(2))"
    }
    var hour: Int { Int(digits.prefix(2)) ?? 0 }
    var minute: Int { Int(digits.suffix(2)) ?? 0 }

    func canAppend(_ digit: Int) -> Bool {
        guard (0...9).contains(digit), digits.count < 4 else { return false }
        switch digits.count {
        case 0: return digit <= 2
        case 1: return digits.first != "2" || digit <= 3
        case 2: return digit <= 5
        default: return true
        }
    }

    mutating func append(_ digit: Int) {
        guard canAppend(digit) else { return }
        digits.append(String(digit))
    }

    mutating func deleteLast() {
        if !digits.isEmpty { digits.removeLast() }
    }
}
