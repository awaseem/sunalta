import QuartzCore

@MainActor
final class GrassBreeze: NSObject {
    var onFrame: ((Float) -> Void)?
    private var displayLink: CADisplayLink?
    private var previousTimestamp: CFTimeInterval?

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(advance(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        previousTimestamp = nil
    }

    @objc private func advance(_ link: CADisplayLink) {
        let previous = previousTimestamp ?? link.targetTimestamp
        previousTimestamp = link.targetTimestamp
        onFrame?(Float(min(link.targetTimestamp - previous, 1 / 15)))
    }
}
