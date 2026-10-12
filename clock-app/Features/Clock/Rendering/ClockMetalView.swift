import MetalKit
import OSLog
import RealityKit

/// Keeps the last drawable on screen and submits work only when the scene changes.
/// The scene stays loaded between gestures; there is no idle display link.
class ClockMetalView: MTKView {
    private(set) var realityRenderer: RealityRenderer?
    private(set) var initializationError: Error?
    var onFrameRendered: (() -> Void)?
    var isSceneReady: Bool { true }
    var isRenderingEnabled = true {
        didSet {
            guard oldValue != isRenderingEnabled else { return }
            lastFrameTime = nil
            if isRenderingEnabled { requestFrame() }
        }
    }
    private var needsFrame = true
    private var framesInFlight = 0
    private var lastFrameTime: CFTimeInterval?
    private var presentationQueue: (any MTLCommandQueue)?
    private var renderFinished: (any MTLEvent)?
    private var frameNumber: UInt64 = 0
    private(set) var renderedFrameCount = 0

    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        isPaused = true
        enableSetNeedsDisplay = true
        framebufferOnly = false
        colorPixelFormat = .bgra8Unorm_srgb
        // RealityRenderer owns its depth and multisample attachments.
        depthStencilPixelFormat = .invalid
        presentationQueue = device?.makeCommandQueue()
        renderFinished = device?.makeEvent()
        guard presentationQueue != nil, renderFinished != nil else {
            initializationError = CocoaError(.featureUnsupported)
            return
        }
        do {
            let renderer = try RealityRenderer()
            renderer.cameraSettings.antialiasing = .multisample4X
            realityRenderer = renderer
        } catch {
            initializationError = error
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("Use init()") }

    func requestFrame() {
        needsFrame = true
        scheduleFrameIfNeeded()
    }

    private func scheduleFrameIfNeeded() {
        guard needsFrame, isRenderingEnabled, window != nil, framesInFlight < 2 else { return }
        setNeedsDisplay()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        lastFrameTime = nil
        if window != nil { requestFrame() }
    }

    override func draw(_ rect: CGRect) {
        guard needsFrame, isRenderingEnabled, isSceneReady, window != nil,
              bounds.width > 0, bounds.height > 0, framesInFlight < 2,
              let realityRenderer, let renderFinished,
              let presentation = presentationQueue?.makeCommandBuffer(),
              let drawable = currentDrawable else { return }
        let now = CACurrentMediaTime()
        // Resuming after minutes at rest must not advance a simulation by minutes.
        let deltaTime = min(now - (lastFrameTime ?? (now - 1 / 60)), 1 / 30)
        lastFrameTime = now
        needsFrame = false
        framesInFlight += 1
        frameNumber += 1
        do {
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: drawable.texture))
            try realityRenderer.updateAndRender(
                deltaTime: deltaTime, cameraOutput: output,
                actionsAfterRender: [.signal(renderFinished, value: frameNumber)]
            )
            // Synchronize on the GPU. Never wait for RealityKit from the UI thread.
            presentation.encodeWaitForEvent(renderFinished, value: frameNumber)
            presentation.present(drawable)
            presentation.addCompletedHandler { [weak self] buffer in
                let succeeded = buffer.status == .completed
                if let error = buffer.error {
                    Logger(subsystem: "dev.ambitionsoftware.clock-app", category: "ClockRenderer")
                        .error("Clock GPU work failed: \(error.localizedDescription)")
                }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    framesInFlight -= 1
                    if succeeded {
                        renderedFrameCount += 1
                        onFrameRendered?()
                    }
                    // Coalesce changes while the GPU is busy instead of blocking touch handling.
                    scheduleFrameIfNeeded()
                }
            }
            presentation.commit()
        } catch {
            framesInFlight -= 1
            Logger(subsystem: "dev.ambitionsoftware.clock-app", category: "ClockRenderer")
                .error("Could not render clock: \(error.localizedDescription)")
        }
    }
}
