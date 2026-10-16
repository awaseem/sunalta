import Combine
import RealityKit
import SwiftUI

struct AlarmBellView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var isRinging = true
    var onSwing: () -> Void = {}
    @State private var scene: AlarmBellScene?
    @State private var sceneUpdates: (any Cancellable)?
    @State private var failedToLoad = false
    @State private var viewportSize = CGSize.zero
    @GestureState private var isDragging = false

    var body: some View {
        RealityView { content in
            content.camera = .virtual
            content.renderingEffects.cameraGrain = .disabled
            content.renderingEffects.motionBlur = .disabled
            content.renderingEffects.antialiasing = .multisample4X
            do {
                let scene = try await AlarmBellScene()
                try Task.checkCancellation()
                try scene.apply(theme: theme)
                scene.setViewport(viewportSize)
                content.add(scene.root)
                self.scene = scene
                let subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                    updateAnimationFrame(deltaTime: event.deltaTime)
                }
                sceneUpdates = AnyCancellable { subscription.cancel() }
            } catch is CancellationError {
                // A dismissed screen doesn't need to finish loading its decoration.
            } catch {
                failedToLoad = true
            }
        } update: { _ in
            do {
                try scene?.apply(theme: theme)
            } catch {
                failedToLoad = true
            }
            scene?.setViewport(viewportSize)
        } placeholder: {
            Color.clear
        }
        .realityViewCameraControls(.none)
        .contentShape(.rect)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        .highPriorityGesture(
            DragGesture()
                .updating($isDragging) { _, dragging, _ in dragging = true }
                .onChanged { value in
                    scene?.drag(translation: value.translation, width: viewportSize.width)
                }
                .onEnded { value in
                    scene?.endDrag(velocity: value.velocity, width: viewportSize.width, reduceMotion: reduceMotion)
                }
        )
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                // Gesture cancellation also returns the camera to its resting pose.
                scene?.endDrag(velocity: .zero, width: viewportSize.width, reduceMotion: reduceMotion)
            }
        }
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
        .onChange(of: scene != nil) { _, _ in
            scene?.setRinging(isRinging && !reduceMotion && scenePhase == .active)
        }
        .onChange(of: isRinging && !reduceMotion && scenePhase == .active) { _, ringing in
            scene?.setRinging(ringing)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { scene?.resetOrbit() }
        }
        .onAppear {
            scene?.setRinging(isRinging && !reduceMotion && scenePhase == .active)
            if sceneUpdates == nil, let realityScene = scene?.root.scene {
                sceneUpdates = realityScene.subscribe(to: SceneEvents.Update.self) { event in
                    updateAnimationFrame(deltaTime: event.deltaTime)
                }
            }
        }
        .onDisappear {
            sceneUpdates?.cancel()
            sceneUpdates = nil
            scene?.setRinging(false)
            scene?.resetOrbit()
        }
    }

    private func updateAnimationFrame(deltaTime: TimeInterval) {
        scene?.advanceReveal(by: deltaTime)
        if scene?.reachedSwingEnd() == true { onSwing() }
    }
}
