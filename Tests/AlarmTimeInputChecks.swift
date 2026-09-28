import Foundation

@main
struct AlarmTimeInputChecks {
    static func main() {
        for value in 0..<10_000 {
            let digits = String(format: "%04d", value)
            var input = AlarmTimeInput()
            var accepted = true
            for digit in digits.compactMap({ $0.wholeNumberValue }) {
                if !input.canAppend(digit) { accepted = false; break }
                input.append(digit)
            }
            let valid = value / 100 < 24 && value % 100 < 60
            precondition(accepted == valid, "Unexpected validation for \(digits)")
            if valid {
                precondition(input.isComplete)
                precondition(input.hour == value / 100 && input.minute == value % 100)
                precondition(input.displayTime == "\(digits.prefix(2)):\(digits.suffix(2))")
                precondition(!input.canAppend(0))
            }
        }
        var input = AlarmTimeInput()
        input.deleteLast()
        precondition(input.digits.isEmpty && !input.isComplete)
        for digit in [2, 3, 5, 9] { input.append(digit) }
        input.deleteLast()
        precondition(input.digits == "235" && !input.isComplete)
        input.append(0)
        precondition(input.displayTime == "23:50")
        precondition(!input.canAppend(-1) && !input.canAppend(10))
        print("Alarm time input checks passed (all 10,000 four-digit combinations).")
    }
}
