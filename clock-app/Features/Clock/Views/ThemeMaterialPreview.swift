import SwiftUI

/// Reuses the clock's event-driven renderer, meshes, and materials without animation or audio.
struct ThemeMaterialPreview: UIViewRepresentable {
    @Environment(\.scenePhase) private var scenePhase
    let theme: AppTheme

    func makeUIView(context: Context) -> ClockRenderView {
        let view = ClockRenderView(theme: theme, previewNumeral: "1")
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: ClockRenderView, context: Context) {
        view.isRenderingEnabled = scenePhase == .active
        view.applyTheme(theme)
    }

    static func dismantleUIView(_ view: ClockRenderView, coordinator: ()) {
        view.stop()
    }
}
