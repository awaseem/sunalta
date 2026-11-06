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
            // Add help/privacy destinations when finalized in #5.
        }
    }
}
