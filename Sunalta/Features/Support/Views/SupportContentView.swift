import SwiftUI

struct SupportContentView: View {
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                SupportStampView()
                    .padding(.bottom, 12)
                SupportStoryView()
                    .modifier(SupportEntranceAnimation(delay: 0.3))
                SupportSocialLinks()
                    .modifier(SupportEntranceAnimation(delay: 0.4))

                Spacer()

                SupportTipSection()
                    .modifier(SupportEntranceAnimation(delay: 0.6))
            }
            .frame(maxWidth: 600)
            .frame(minHeight: max(0, viewportHeight - 40))
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.height - geometry.contentInsets.top - geometry.contentInsets.bottom
        } action: { _, height in
            viewportHeight = height
        }
    }
}
