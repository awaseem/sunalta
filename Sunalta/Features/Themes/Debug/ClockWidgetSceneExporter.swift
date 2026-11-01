#if DEBUG
import OSLog
import SwiftUI

/// Positional layers with the home materials and the widget's final geometry and light source.
@MainActor
enum ClockWidgetSceneExporter {
    static func exportIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--export-widget-scenes") else { return }
        do {
            let root = URL.documentsDirectory.appending(path: "WidgetScenes", directoryHint: .isDirectory)
            for theme in AppTheme.available {
                try Task.checkCancellation()
                try await export(theme: theme, to: root.appending(path: theme.id, directoryHint: .isDirectory))
            }
        } catch {
            Logger(subsystem: "dev.ambitionsoftware.sunalta", category: "WidgetExport")
                .error("Widget scene export failed: \(error)")
        }
    }

    private static func export(theme: AppTheme, to folder: URL) async throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let completion = folder.appending(path: "complete.txt")
        if FileManager.default.fileExists(atPath: completion.path()) {
            try FileManager.default.removeItem(at: completion)
        }
        let view = ClockRenderView(theme: theme)
        defer { view.stop() }
        // Keep the home camera and material setup, then crop around the widget composition.
        view.frame = CGRect(x: 0, y: 0, width: 874, height: 874)
        view.contentSafeAreaInsets = .init(top: 62, left: 0, bottom: 34, right: 0)
        let deadline = ContinuousClock.now + .seconds(15)
        while !view.isReady {
            if let error = view.initializationError { throw error }
            guard ContinuousClock.now < deadline else { throw CocoaError(.coderInvalidValue) }
            try await Task.sleep(for: .milliseconds(20))
        }
        for slot in 0..<4 {
            for numeral in "0123456789" {
                try Task.checkCancellation()
                var digits = Array("0000")
                digits[slot] = numeral
                let image = try await capture(view: view, time: String(digits), visibleSlot: slot)
                try ClockArtworkRenderer.write(image, to: folder.appending(path: "\(theme.id)-\(slot)-\(numeral).png"))
            }
        }
        let image = try await capture(view: view, time: "09:41", visibleSlot: nil)
        let preview = ImageRenderer(content: ZStack(alignment: .topLeading) {
            theme.palette.background
            Image(decorative: image, scale: 1).resizable().scaledToFit()
            Text("Mon").font(.system(.title, weight: .medium)).foregroundStyle(Color(theme.weekday.glow.color))
                .offset(x: ClockWidgetComposition.header.minX, y: ClockWidgetComposition.header.minY)
        }.frame(width: ClockWidgetComposition.side, height: ClockWidgetComposition.side))
        preview.scale = 3
        guard let previewImage = preview.cgImage else { throw CocoaError(.coderInvalidValue) }
        try ClockArtworkRenderer.write(previewImage, to: folder.appending(path: "preview.png"))
        try Data("Calendar row; weekday light above hours".utf8).write(to: completion)
    }

    private static func capture(view: ClockRenderView, time: String, visibleSlot: Int?) async throws -> CGImage {
        guard let renderer = view.realityRenderer else { throw CocoaError(.featureUnsupported) }
        let crop = try view.prepareWidgetArtwork(time: time, visibleSlot: visibleSlot)
        let size = 1024
        let image = try await ClockArtworkRenderer.renderImage(
            renderer: renderer, width: size, height: size, transparent: true
        )
        let scale = CGFloat(size) / view.bounds.height
        guard let cropped = image.cropping(to: crop.applying(.init(scaleX: scale, y: scale)).integral) else {
            throw CocoaError(.coderInvalidValue)
        }
        return cropped
    }
}
#endif
