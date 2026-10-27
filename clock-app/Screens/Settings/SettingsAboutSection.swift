import SwiftUI

struct SettingsAboutSection: View {
    @Environment(\.appTheme) private var theme
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        VStack(alignment: .leading) {
            Text("About")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LabeledContent("Version", value: "\(version) (\(build))")
                .foregroundStyle(theme.palette.foreground, theme.palette.secondaryForeground)
                .padding()
                .background(theme.palette.surface, in: .rect(cornerRadius: 20))
            NavigationLink(value: SettingsDestination.support) {
                HStack {
                    SupportLabel()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(theme.palette.secondaryForeground)
                        .accessibilityHidden(true)
                }
                .padding()
                .background(theme.palette.surface, in: .rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            // Add help/privacy destinations when finalized in #5.
        }
    }
}
