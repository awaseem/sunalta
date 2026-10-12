import Foundation
import QuartzCore
import simd

/// A one-shot reveal, driven by display timestamps so it cannot drift between frames.
@MainActor
final class ClockEntranceAnimation: NSObject {
    static let fadeDuration = 0.45
    var reduceMotion: Bool
    var initialAngles: SIMD2<Float> { reduceMotion ? .zero : [-0.3, 0.14] }
    var isRunning: Bool { displayLink != nil }
    private let onFrame: (CGFloat, SIMD2<Float>) -> Void
    private let onCompletion: () -> Void
    private var displayLink: CADisplayLink?
    private var startedAt: CFTimeInterval?

    init(reduceMotion: Bool, onFrame: @escaping (CGFloat, SIMD2<Float>) -> Void,
         onCompletion: @escaping () -> Void) {
        self.reduceMotion = reduceMotion
        self.onFrame = onFrame
        self.onCompletion = onCompletion
    }

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(advance(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func finish() {
        cancel()
        onFrame(1, .zero)
        onCompletion()
    }

    func cancel() {
        displayLink?.invalidate()
        displayLink = nil
        startedAt = nil
    }

    @objc private func advance(_ link: CADisplayLink) {
        if startedAt == nil { startedAt = link.targetTimestamp }
        let elapsed = link.targetTimestamp - (startedAt ?? link.targetTimestamp)
        let duration = reduceMotion ? Self.fadeDuration : 0.95
        guard elapsed < duration else {
            finish()
            return
        }
        let opacity = smoothstep(elapsed / Self.fadeDuration)
        // Let the fade lead the turn, with zero angular velocity at either end.
        let turn = smoothstep((elapsed - 0.1) / 0.85)
        onFrame(CGFloat(opacity), initialAngles * Float(1 - turn))
    }

    private func smoothstep(_ value: Double) -> Double {
        let value = min(max(value, 0), 1)
        return value * value * (3 - 2 * value)
    }
}
