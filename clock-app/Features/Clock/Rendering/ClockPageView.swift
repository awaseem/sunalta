import RealityKit
import SwiftUI
import UIKit

/// Scroll a cached frame, keeping RealityKit's drawable out of the paging animation.
/// Offscreen pages retain only the cached frame; glyph assets are cached separately.
final class ClockPageView: UIView {
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?
    private let scene: ClockScene
    private var renderer: ClockRenderView?
    private let still = UIImageView()
    private var snapshotTask: Task<Void, Never>?
    private var revision = 0
    private var hasCurrentSnapshot = false
    private var isScrolling = false
    private var isPageVisible = true
    private var isOrbiting = false
    private var isEditingAppearance = false
    private var allowsFlybys = true
    private var minute: Int?
    private var displayedDate = Date.now
    private var appearance: AppTheme?
    private var insets: UIEdgeInsets = .zero
    private var weekdayFrame: CGRect = .zero
    private var renderedSize: CGSize = .zero

    init(theme: AppTheme, scene: ClockScene) {
        self.scene = scene
        appearance = theme
        super.init(frame: .zero)
        still.contentMode = .scaleToFill
        still.isUserInteractionEnabled = false
        addSubview(still)
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    private func makeRenderer(theme: AppTheme) -> ClockRenderView {
        let renderer = ClockRenderView(theme: theme, scene: scene)
        accessibilityHint = renderer.accessibilityHint
        renderer.isAccessibilityElement = false
        renderer.onContentChanged = { [weak self] in
            guard let self else { return }
            invalidateSnapshot()
            updatePresentation()
        }
        renderer.onWeekdayAnchorChange = { [weak self] anchor in
            self?.onWeekdayAnchorChange?(anchor)
        }
        renderer.onOrbitBegan = { [weak self] in
            guard let self else { return }
            isOrbiting = true
            self.renderer?.allowsAmbientAnimation = false
            invalidateSnapshot()
            // A front-facing cached image must never replace an ongoing orbit.
            still.image = nil
            still.isHidden = true
        }
        renderer.onOrbitSettled = { [weak self] in
            guard let self else { return }
            isOrbiting = false
            updatePresentation()
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
        self.isScrolling = isScrolling
        isPageVisible = isVisible
        displayedDate = date
        self.isEditingAppearance = isEditingAppearance
        self.allowsFlybys = allowsFlybys
        if isEditingAppearance {
            invalidateSnapshot()
            still.isHidden = true
        }
        let minute = Int(date.timeIntervalSince1970 / 60)
        if self.minute != minute || appearance != theme || self.insets != insets
            || self.weekdayFrame != weekdayFrame {
            self.minute = minute
            appearance = theme
            self.insets = insets
            self.weekdayFrame = weekdayFrame
            invalidateSnapshot()
            renderer?.contentSafeAreaInsets = insets
            renderer?.weekdayFrame = weekdayFrame
            renderer?.applyTheme(theme)
            still.image = nil
            still.isHidden = true
            renderer?.show(date: date)
            if let renderer { accessibilityLabel = renderer.accessibilityLabel }
        }
        updatePresentation()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        still.frame = bounds
        guard renderedSize != bounds.size else { return }
        renderedSize = bounds.size
        invalidateSnapshot()
        renderer?.frame = bounds
        updatePresentation()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePresentation()
    }

    func stop() {
        invalidateSnapshot()
        renderer?.removeFromSuperview()
        renderer?.stop()
        renderer = nil
    }

    private func invalidateSnapshot() {
        revision += 1
        hasCurrentSnapshot = false
        snapshotTask?.cancel()
        snapshotTask = nil
    }

    private func updatePresentation() {
        // Detaching an ARView leaves its RealityKit renderer alive. Release it when
        // offscreen so it cannot interfere with the alarm page's live renderer.
        if window == nil || !isPageVisible {
            stop()
            isOrbiting = false
            still.isHidden = still.image == nil
            return
        }
        if isScrolling && still.image != nil {
            stop()
            isOrbiting = false
            still.isHidden = still.image == nil
            return
        }
        if renderer == nil {
            guard let appearance, bounds.width > 0, bounds.height > 0 else { return }
            renderer = makeRenderer(theme: appearance)
        }
        guard let renderer else { return }
        if renderer.superview == nil {
            renderer.frame = bounds
            insertSubview(renderer, belowSubview: still)
            // Keep the cached image covering the drawable until its first fresh frame.
            invalidateSnapshot()
        }
        if still.image == nil { still.isHidden = true }
        renderer.allowsAmbientAnimation = allowsFlybys && !isScrolling && !isOrbiting
            && !isEditingAppearance && snapshotTask == nil
        scheduleSnapshot()
    }

    private func scheduleSnapshot() {
        guard let renderer, renderer.isReady, !hasCurrentSnapshot, snapshotTask == nil,
              !isOrbiting, !isEditingAppearance,
              !isScrolling, isPageVisible, window != nil,
              renderer.superview != nil, bounds.width > 0, bounds.height > 0 else { return }
        let requestedRevision = revision
        // Cache only the clock: a visitor must never freeze into the scrolling image.
        renderer.allowsAmbientAnimation = false
        snapshotTask = Task { @MainActor [weak self, weak renderer] in
            // Coalesce layout/content updates and let RealityKit present the scene.
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, let self, let renderer,
                  revision == requestedRevision else { return }
            guard !isScrolling else {
                snapshotTask = nil
                return
            }
            renderer.snapshot(saveToHDR: false) { [weak self] image in
                guard let self, revision == requestedRevision else { return }
                snapshotTask = nil
                guard let image else {
                    // A failed capture must leave the live clock usable.
                    still.isHidden = true
                    renderer.allowsAmbientAnimation = allowsFlybys && !isScrolling && !isOrbiting
                        && !isEditingAppearance && isPageVisible && window != nil
                    return
                }
                still.image = image
                hasCurrentSnapshot = true
                still.isHidden = !isScrolling && isPageVisible
                updatePresentation()
            }
        }
    }
}
