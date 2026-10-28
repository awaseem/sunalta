import SwiftUI

struct AlarmTimePreview: View {
    @State private var periodAnchor: CGPoint?
    let display: ClockTimeDisplay
    let previewHeight: CGFloat
    let previewTopInset: CGFloat
    let contentSafeAreaInsets: UIEdgeInsets

    var body: some View {
        GeometryReader { geometry in
            AlarmTimeRenderView(display: display, onPeriodAnchorChange: { periodAnchor = $0 },
                                previewHeight: previewHeight, previewTopInset: previewTopInset,
                                contentSafeAreaInsets: contentSafeAreaInsets)
                .overlay(alignment: .topLeading) {
                    if let period = display.period, let periodAnchor {
                        ClockPeriodLabel(period: period, anchor: periodAnchor,
                                         availableWidth: geometry.size.width)
                    }
                }
        }
    }
}
