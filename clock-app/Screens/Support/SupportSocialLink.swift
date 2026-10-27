import SwiftUI

struct SupportSocialLink: View {
    @ScaledMetric(relativeTo: .body) private var iconSize = 24
    let title: String
    let image: ImageResource
    let destination: String

    var body: some View {
        if let url = URL(string: destination) {
            Link(destination: url) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(title)
            .accessibilityHint("Opens the developer's profile")
        }
    }
}
