import Foundation

/// Follows the bell while it swings and keeps the same passive cadence when it rests.
nonisolated struct AlarmBurstTiming {
    let swingDuration: TimeInterval
    private(set) var elapsed: TimeInterval = 0

    mutating func advance(by deltaTime: TimeInterval, bellTime: TimeInterval?) -> Bool {
        let previous = elapsed
        elapsed = bellTime ?? (elapsed + max(0, deltaTime))
        // Reopening or restarting the bell begins a new cycle, without replaying old bursts.
        guard elapsed >= previous else { return false }
        let firstPeak = swingDuration / 4
        let interval = swingDuration / 2
        return floor((elapsed - firstPeak) / interval) > floor((previous - firstPeak) / interval)
    }
}
