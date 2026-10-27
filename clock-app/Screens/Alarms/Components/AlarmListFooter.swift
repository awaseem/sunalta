import SwiftUI

struct AlarmListFooter: View {
    @Environment(\.appTheme) private var theme
    let showsCreateAlarm: Bool
    let createAlarm: () -> Void

    var body: some View {
        VStack(alignment: .trailing) {
            if showsCreateAlarm {
                Button("Create alarm", action: createAlarm)
                    .buttonStyle(.appCapsule(fillsWidth: true))
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 0) {
                Text("Made in Calgary AB 🇨🇦")
                    .font(.footnote)
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                ClockSupportButton()
                ClockSettingsButton()
            }
            .font(.body)
            .foregroundStyle(theme.palette.control)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: 640, alignment: .trailing)
        .frame(maxWidth: .infinity)
    }
}
