import Foundation

/// Fit the form to its content and give the preview all remaining vertical space.
nonisolated struct AlarmEditorLayoutMetrics {
    let previewHeight: CGFloat
    let formHeight: CGFloat

    init(availableHeight: CGFloat, headerHeight: CGFloat, footerHeight: CGFloat, idealFormHeight: CGFloat) {
        let contentHeight = max(0, availableHeight - headerHeight - footerHeight)
        // Keep a small preview on compact screens while the form remains scrollable.
        let minimumPreviewHeight = min(120, contentHeight / 4)
        formHeight = min(max(0, idealFormHeight), contentHeight - minimumPreviewHeight)
        previewHeight = contentHeight - formHeight
    }
}
