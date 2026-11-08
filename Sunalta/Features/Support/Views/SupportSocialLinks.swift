import SwiftUI

struct SupportSocialLinks: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Follow along or share how Sunalta fits into your day.")
                .font(.callout)
                .foregroundStyle(theme.palette.secondaryForeground)
            HStack(spacing: 20) {
                SupportSocialLink(title: "Threads", image: .threads, destination: "https://www.threads.com/@softwarecuddler")
                SupportSocialLink(title: "X", image: .twitter, destination: "https://x.com/softwarecuddler")
                SupportSocialLink(title: "Reddit", image: .reddit, destination: "https://www.reddit.com/user/waseema393/")
                SupportSocialLink(title: "LinkedIn", image: .linkedin, destination: "https://www.linkedin.com/in/aliw")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
