import RealityKit
import SwiftUI
import UIKit

/// Scroll a cached frame, keeping RealityKit's drawable out of the paging animation.
/// The renderer and its meshes stay alive, so returning doesn't reload the scene.
final class ClockPageView: UIView {
    private let renderer: ClockRenderView
    private let still = UIImageView()
    private var snapshotTask: Task<Void, Never>?
    private var revision = 0
    private var hasCurrentSnapshot = false
    private var isScrolling = false
    private var isPageVisible = true
    private var isOrbiting = false
    private var isEditingLighting = false
    private var lighting = ClockLightingSettings()
    private var minute: Int?
    private var appearance: ColorScheme?
    private var insets: UIEdgeInsets = .zero
    private var renderedSize: CGSize = .zero

    init(colorScheme: ColorScheme) {
        renderer = ClockRenderView(colorScheme: colorScheme)
        super.init(frame: .zero)
        still.contentMode = .scaleToFill
        still.isUserInteractionEnabled = false
        addSubview(still)
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityHint = renderer.accessibilityHint
        renderer.isAccessibilityElement = false
        renderer.onOrbitBegan = { [weak self] in
            guard let self else { return }
            isOrbiting = true
            invalidateSnapshot()
            // A front-facing cached image must never replace an ongoing orbit.
            still.image = nil
            still.isHidden = true
        }
        renderer.onOrbitSettled = { [weak self] in
            guard let self else { return }
            isOrbiting = false
            scheduleSnapshot()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(colorScheme:)") }

    func update(date: Date, colorScheme: ColorScheme, insets: UIEdgeInsets,
                isScrolling: Bool, isVisible: Bool,
                lighting: ClockLightingSettings, isEditingLighting: Bool) {
        self.isScrolling = isScrolling
        isPageVisible = isVisible
        self.isEditingLighting = isEditingLighting
        if self.lighting != lighting {
            self.lighting = lighting
            invalidateSnapshot()
            renderer.applyLighting(lighting)
            still.isHidden = true
        }
        if isEditingLighting {
            invalidateSnapshot()
            still.isHidden = true
        }
        let minute = Int(date.timeIntervalSince1970 / 60)
        if self.minute != minute || appearance != colorScheme || self.insets != insets {
            self.minute = minute
            appearance = colorScheme
            self.insets = insets
            invalidateSnapshot()
            renderer.contentSafeAreaInsets = insets
            renderer.applyAppearance(colorScheme)
            renderer.show(date: date)
            accessibilityLabel = renderer.accessibilityLabel
        }
        updatePresentation()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        still.frame = bounds
        guard renderedSize != bounds.size else { return }
        renderedSize = bounds.size
        invalidateSnapshot()
        renderer.frame = bounds
        updatePresentation()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePresentation()
    }

    func stop() {
        invalidateSnapshot()
        renderer.removeFromSuperview()
    }

    private func invalidateSnapshot() {
        revision += 1
        hasCurrentSnapshot = false
        snapshotTask?.cancel()
        snapshotTask = nil
    }

    private func updatePresentation() {
        // Offscreen views remain in the ScrollView's VStack. Explicitly detach the
        // ARView; pausing an ARSession would not stop this non-AR renderer.
        let shouldDetach = window == nil || !isPageVisible
            || (isScrolling && still.image != nil)
        if shouldDetach {
            snapshotTask?.cancel()
            snapshotTask = nil
            renderer.removeFromSuperview()
            isOrbiting = false
            still.isHidden = still.image == nil
            return
        }
        if renderer.superview == nil {
            renderer.frame = bounds
            insertSubview(renderer, belowSubview: still)
            // Keep the cached image covering the drawable until its first fresh frame.
            invalidateSnapshot()
        }
        if still.image == nil { still.isHidden = true }
        scheduleSnapshot()
    }

    private func scheduleSnapshot() {
        guard !hasCurrentSnapshot, snapshotTask == nil, !isOrbiting, !isEditingLighting,
              !isScrolling, isPageVisible, window != nil,
              renderer.superview != nil, bounds.width > 0, bounds.height > 0 else { return }
        let requestedRevision = revision
        snapshotTask = Task { @MainActor [weak self] in
            // Coalesce layout/content updates and let RealityKit present the scene.
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, let self, revision == requestedRevision else { return }
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
