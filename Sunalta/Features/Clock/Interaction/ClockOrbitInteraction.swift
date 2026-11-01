import simd
import UIKit

/// Shared gesture handling and a display-synchronized return to each scene's resting angle.
@MainActor
final class ClockOrbitInteraction: NSObject, UIGestureRecognizerDelegate {
    var onBegan: (() -> Void)?
    var onSettled: (() -> Void)?
    private(set) var motion: ClockOrbitMotion
    private weak var view: UIView?
    private let allowsVerticalDrag: Bool
    private let onChange: (simd_quatf) -> Void
    private var returnLink: CADisplayLink?
    private var lastFrame: CFTimeInterval = 0

    init(view: UIView, restingAngles: SIMD2<Float> = .zero, allowsVerticalDrag: Bool = false,
         onChange: @escaping (simd_quatf) -> Void) {
        self.view = view
        motion = ClockOrbitMotion(restingAngles: restingAngles)
        self.allowsVerticalDrag = allowsVerticalDrag
        self.onChange = onChange
        super.init()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !allowsVerticalDrag, let view,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: view)
        return abs(velocity.x) > abs(velocity.y)
    }

    func reset() {
        stopReturn()
        motion.reset()
        onChange(motion.orientation)
    }

    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        guard let view else { return }
        switch gesture.state {
        case .began:
            stopReturn()
            motion.beginDrag()
            onBegan?()
        case .changed:
            let translation = gesture.translation(in: view)
            motion.drag(translation: SIMD2(Float(translation.x), Float(translation.y)),
                        width: Float(view.bounds.width))
            onChange(motion.orientation)
        case .ended, .cancelled, .failed:
            let speed = gesture.velocity(in: view)
            motion.release(velocity: SIMD2(Float(speed.x), Float(speed.y)), width: Float(view.bounds.width))
            if UIAccessibility.isReduceMotionEnabled {
                reset()
                onSettled?()
            } else {
                stopReturn()
                let link = CADisplayLink(target: self, selector: #selector(returnToRest(_:)))
                link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
                link.add(to: .main, forMode: .common)
                returnLink = link
            }
        default:
            break
        }
    }

    @objc private func returnToRest(_ link: CADisplayLink) {
        guard view?.window != nil else {
            reset()
            return
        }
        let elapsed = lastFrame == 0 ? link.duration : link.timestamp - lastFrame
        lastFrame = link.timestamp
        let settled = motion.advance(by: Float(elapsed))
        onChange(motion.orientation)
        if settled {
            stopReturn()
            onSettled?()
        }
    }

    private func stopReturn() {
        returnLink?.invalidate()
        returnLink = nil
        lastFrame = 0
    }
}
