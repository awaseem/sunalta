import Foundation

struct AlarmRecoveryError: LocalizedError {
    let operationError: Error
    let recoveryError: Error

    var errorDescription: String? {
        "\(operationError.localizedDescription) Restoring the previous alarm also failed: \(recoveryError.localizedDescription)"
    }
}
