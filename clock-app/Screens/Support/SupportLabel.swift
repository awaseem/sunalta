import SwiftUI

struct SupportLabel: View {
    @ScaledMetric(relativeTo: .subheadline) var heartSize = 24

    var body: some View {
        Label {
            Text("Support")
        } icon: {
            Image(.supportStickerLogo)
                .resizable()
                .scaledToFit()
                .frame(width: heartSize, height: heartSize)
                .accessibilityHidden(true)
        }
    }
}
