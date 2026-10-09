import Foundation

struct AlarmRecoveryError: LocalizedError {
    let operationError: Error
    let persistenceError: Error

    var errorDescription: String? {
        "\(operationError.localizedDescription) Restoring the saved alarm also failed: \(persistenceError.localizedDescription)"
    }
}
