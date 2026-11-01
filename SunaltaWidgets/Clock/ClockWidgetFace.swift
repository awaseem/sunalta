import SwiftUI
import WidgetKit

/// Layers are captured in place so the weekday light stays above the hour digits.
struct ClockWidgetFace: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let digits: String
    let themeID: String

    var body: some View {
        // The light material retains the same geometry when the system maps its
        // luminance to the user's Home Screen tint.
        let assetTheme = renderingMode != .fullColor && themeID == "white" ? "midnight" : themeID
        ZStack {
            ForEach(digits.filter(\.isNumber).enumerated(), id: \.offset) { slot, digit in
                Image("ClockFace-\(assetTheme)-\(slot)-\(digit)")
                    .resizable()
                    .widgetAccentedRenderingMode(renderingMode == .fullColor ? .fullColor : .desaturated)
                    .scaledToFit()
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
