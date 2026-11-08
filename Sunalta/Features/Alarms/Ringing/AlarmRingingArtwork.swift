import Combine
import OSLog
import RealityKit
import SwiftUI

struct AlarmRingingArtwork: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let alarm: AlarmRecord
    let isRinging: Bool
    let isWorking: Bool
    let scanError: String?
    @State private var scene: AlarmRingingScene?
    @State private var sceneUpdates: (any Cancellable)?
    @State private var failedToLoad = false
    @State private var viewportSize = CGSize.zero
    @State private var timeFrame = CGRect.zero
    @State private var bellFrame = CGRect.zero
    @GestureState private var isDragging = false
    private static let logger = Logger(subsystem: "dev.ambitionsoftware.sunalta", category: "AlarmArtwork")

    var body: some View {
        let display = ClockTimeDisplay(hour: alarm.hour, minute: alarm.minute,
                                       format: settings.format, locale: locale)
        ScrollView {
            VStack(spacing: 24) {
                AlarmRingingHeader(alarm: alarm, display: display, showsFallback: failedToLoad,
                                   timeFrame: $timeFrame)
                Color.clear
                    .frame(height: 260)
                    .onGeometryChange(for: CGRect.self) { geometry in
                        geometry.frame(in: .named("alarmArtwork"))
                    } action: { bellFrame = $0 }
                    .contentShape(.rect)
                    .highPriorityGesture(
                        DragGesture()
                            .updating($isDragging) { _, dragging, _ in dragging = true }
                            .onChanged { value in
                                scene?.bell.drag(translation: value.translation, width: bellFrame.width)
                            }
                            .onEnded { value in
                                scene?.bell.endDrag(velocity: value.velocity, width: bellFrame.width,
                                                    reduceMotion: reduceMotion)
                            }
                    )
                    .overlay {
                        if failedToLoad {
                            Image(systemName: "bell.fill")
                                .font(.largeTitle)
                                .foregroundStyle(theme.palette.foreground)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("3D alarm bell")
                    .accessibilityHint("Drag to look around the bell. Release to return to its starting angle.")
                    .accessibilityIdentifier("alarm-bell")
                VStack(spacing: 12) {
                    if isWorking { ProgressView() }
                    if let scanError {
                        Text(scanError)
                            .font(.subheadline)
                            .foregroundStyle(theme.palette.error)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        .background {
            // Separate RealityViews can leave the animated surface frozen on iOS.
            // Both models share this renderer; SwiftUI still lays out the text and hit targets.
            if scenePhase == .active, let scene {
                RealityView { [scene] content in
                    content.camera = .virtual
                    content.renderingEffects.cameraGrain = .disabled
                    content.renderingEffects.motionBlur = .disabled
                    content.renderingEffects.antialiasing = .multisample4X
                    scene.setLayout(viewport: viewportSize, timeFrame: timeFrame, bellFrame: bellFrame)
                    content.add(scene.root)
                    let subscription = content.subscribe(to: SceneEvents.Update.self) { [weak scene] event in
                        scene?.advance(by: event.deltaTime)
                    }
                    sceneUpdates = AnyCancellable { subscription.cancel() }
                    scene.bell.setRinging(isRinging && !reduceMotion)
                    scene.setAmbienceActive(!reduceMotion)
                } update: { _ in
                    scene.show(display: display)
                    scene.setLayout(viewport: viewportSize, timeFrame: timeFrame, bellFrame: bellFrame)
                } placeholder: {
                    Color.clear
                }
                .realityViewCameraControls(.none)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onDisappear {
                    sceneUpdates?.cancel()
                    sceneUpdates = nil
                    scene.bell.setRinging(false)
                    scene.bell.resetOrbit()
                    scene.setAmbienceActive(false)
                }
            }
        }
        .coordinateSpace(name: "alarmArtwork")
        // AlarmKit can present this screen while the phone is still locked. GPU-backed
        // loading must wait for activation, and restart if the handoff interrupts it.
        .task(id: scenePhase == .active ? theme : nil) { await loadScene(display: display) }
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                scene?.bell.endDrag(velocity: .zero, width: bellFrame.width, reduceMotion: reduceMotion)
            }
        }
        .onChange(of: isRinging && !reduceMotion && scenePhase == .active) { _, ringing in
            scene?.bell.setRinging(ringing)
        }
        .onChange(of: !reduceMotion && scenePhase == .active) { _, active in
            scene?.setAmbienceActive(active)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { scene?.bell.resetOrbit() }
        }
    }

    private func loadScene(display: ClockTimeDisplay) async {
        guard scenePhase == .active else { return }
        do {
            try Task.checkCancellation()
            let loadedScene: AlarmRingingScene
            if let scene { loadedScene = scene }
            else { loadedScene = try await AlarmRingingScene() }
            try Task.checkCancellation()
            loadedScene.show(display: display)
            try await loadedScene.apply(theme: theme)
            try Task.checkCancellation()
            loadedScene.setLayout(viewport: viewportSize, timeFrame: timeFrame, bellFrame: bellFrame)
            scene = loadedScene
            failedToLoad = false
        } catch is CancellationError {
            // The next activation can retry interrupted loading.
        } catch {
            // RealityKit may report its own loading error when cancellation interrupts
            // GPU work. Let the next activation retry without retaining a stale failure.
            guard !Task.isCancelled else { return }
            Self.logger.error("Could not load alarm artwork: \(String(reflecting: error), privacy: .public)")
            failedToLoad = true
        }
    }
}
