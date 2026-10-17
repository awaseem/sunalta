import SwiftUI
import UIKit

/// The paused Metal surface scrolls with the page while its scene stays ready for interaction.
final class ClockPageView: UIView {
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?
    var onContentRevealed: (() -> Void)?
    private let scene: ClockScene
    private let audioService: ClockAudioService?
    private var renderer: ClockRenderView?
    private var isScrolling = false
    private var isPageVisible = true
    private var isOrbiting = false
    private var isEditingAppearance = false
    private var allowsFlybys = true
    private var entrance: ClockEntranceAnimation?
    private var hasPreparedEntrance = false
    private var hasRevealedContent = false
    private var minute: Int?
    private var displayedDate = Date.now
    private var appearance: AppTheme
    private var insets: UIEdgeInsets = .zero
    private var weekdayFrame: CGRect = .zero
    private var renderedSize: CGSize = .zero

    init(theme: AppTheme, scene: ClockScene, audioService: ClockAudioService? = nil) {
        self.scene = scene
        self.audioService = audioService
        appearance = theme
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    private func makeRenderer() -> ClockRenderView {
        if scene == .numbers { audioService?.apply(configuration: appearance.audio) }
        let renderer = ClockRenderView(theme: appearance, scene: scene, audioService: audioService)
        accessibilityHint = renderer.accessibilityHint
        renderer.isAccessibilityElement = false
        if scene == .numbers && !hasPreparedEntrance && renderer.initializationError == nil {
            hasPreparedEntrance = true
            // Keep the surface drawable while waiting for its first completed frame.
            renderer.alpha = 0.001
            let animation = ClockEntranceAnimation(reduceMotion: !allowsFlybys) { [weak renderer] opacity, angles in
                renderer?.alpha = opacity
                renderer?.entranceAngles = angles
            } onCompletion: { [weak self] in
                self?.entrance = nil
                self?.updatePresentation()
            }
            renderer.entranceAngles = animation.initialAngles
            entrance = animation
        }
        renderer.onContentChanged = { [weak self] in self?.updatePresentation() }
        renderer.onFrameRendered = { [weak self] in self?.revealRenderedContent() }
        renderer.onWeekdayAnchorChange = { [weak self] anchor in
            self?.onWeekdayAnchorChange?(anchor)
        }
        renderer.onOrbitBegan = { [weak self] in
            guard let self else { return }
            isOrbiting = true
            if entrance?.isRunning == true { audioService?.stopEntrance() }
            entrance?.finish()
            updatePresentation()
        }
        renderer.onOrbitSettled = { [weak self] in
            self?.isOrbiting = false
            self?.updatePresentation()
        }
        renderer.contentSafeAreaInsets = insets
        renderer.weekdayFrame = weekdayFrame
        renderer.show(date: displayedDate)
        accessibilityLabel = renderer.accessibilityLabel
        return renderer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(theme:)") }

    func update(date: Date, theme: AppTheme, insets: UIEdgeInsets,
                isScrolling: Bool, isVisible: Bool, isEditingAppearance: Bool, weekdayFrame: CGRect,
                allowsFlybys: Bool) {
        let beganScrolling = isScrolling && !self.isScrolling
        self.isScrolling = isScrolling
        isPageVisible = isVisible
        displayedDate = date
        self.isEditingAppearance = isEditingAppearance
        self.allowsFlybys = allowsFlybys
        entrance?.reduceMotion = !allowsFlybys
        if beganScrolling {
            if scene == .numbers { audioService?.stopEntrance() }
            isOrbiting = false
            renderer?.settleInteraction()
            if entrance?.isRunning == true { entrance?.finish() }
        }
        let minute = Int(date.timeIntervalSince1970 / 60)
        if self.minute != minute || appearance != theme || self.insets != insets
            || self.weekdayFrame != weekdayFrame {
            self.minute = minute
            appearance = theme
            if scene == .numbers { audioService?.apply(configuration: theme.audio) }
            self.insets = insets
            self.weekdayFrame = weekdayFrame
            renderer?.contentSafeAreaInsets = insets
            renderer?.weekdayFrame = weekdayFrame
            renderer?.applyTheme(theme)
            renderer?.show(date: date)
            if let renderer { accessibilityLabel = renderer.accessibilityLabel }
        }
        updatePresentation()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard renderedSize != bounds.size else { return }
        renderedSize = bounds.size
        renderer?.frame = bounds
        updatePresentation()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePresentation()
    }

    func stop() {
        if scene == .numbers {
            audioService?.updateAmbience(isVisible: false)
        }
        entrance?.cancel()
        entrance = nil
        renderer?.stop()
        renderer?.removeFromSuperview()
        renderer = nil
    }

    private func updatePresentation() {
        let isActive = window != nil && isPageVisible
        if renderer == nil && isActive {
            guard bounds.width > 0, bounds.height > 0 else { return }
            renderer = makeRenderer()
            if let renderer {
                renderer.frame = bounds
                addSubview(renderer)
            }
        }
        guard let renderer else { return }
        let wasActive = renderer.isRenderingEnabled
        renderer.isRenderingEnabled = isActive
        renderer.allowsAmbientAnimation = isActive && allowsFlybys && !isScrolling && !isOrbiting
            && !isEditingAppearance && entrance == nil
        if !isActive && wasActive {
            isOrbiting = false
            renderer.settleInteraction()
            if entrance?.isRunning == true { entrance?.finish() }
        }
        // A first frame can finish during a swipe. Start its reveal when scrolling
        // ends even if the stationary scene has no reason to submit another frame.
        if isActive && renderer.renderedFrameCount > 0 { revealRenderedContent() }
        updateAmbientAudio()
    }

    private func revealRenderedContent() {
        guard isPageVisible, window != nil, renderer?.isReady == true else { return }
        if let entrance {
            guard !isScrolling, !entrance.isRunning else { return }
            entrance.start()
        }
        guard !hasRevealedContent else { return }
        hasRevealedContent = true
        updateAmbientAudio()
        if entrance?.isRunning == true { audioService?.playEntrance() }
        onContentRevealed?()
    }

    private func updateAmbientAudio() {
        guard scene == .numbers else { return }
        audioService?.updateAmbience(
            isVisible: window != nil && isPageVisible && hasRevealedContent && renderer?.isReady == true
        )
    }
}
