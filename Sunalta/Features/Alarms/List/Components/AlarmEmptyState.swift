import SwiftUI

struct AlarmEmptyState: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Welcome")
                .font(.largeTitle.bold())
                .foregroundStyle(theme.palette.foreground)
                .accessibilityAddTraits(.isHeader)

            Text("Wake up your way, with alarms built around your routine.")
                .font(.body)
                .foregroundStyle(theme.palette.secondaryForeground)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading) {
                AlarmWelcomePoint(
                    title: "Set your time",
                    detail: "Choose when to wake up and which days to repeat.",
                    systemImage: "alarm"
                )
                AlarmWelcomePoint(
                    title: "Snooze on your terms",
                    detail: "Pick a snooze length, or turn snooze off.",
                    systemImage: "zzz"
                )
                AlarmWelcomePoint(
                    title: "Choose how to stop",
                    detail: "Tap a button, scan an NFC tag, or scan a QR code.",
                    systemImage: "qrcode.viewfinder"
                )
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview("No alarms") {
    ScrollView {
        AlarmEmptyState()
    }
    .appTheme(.white)
}

#Preview("Midnight") {
    ScrollView {
        AlarmEmptyState()
    }
    .background(AppTheme.midnight.palette.background)
    .appTheme(.midnight)
}

#Preview("Large text") {
    ScrollView {
        AlarmEmptyState()
    }
    .appTheme(.white)
    .environment(\.dynamicTypeSize, .accessibility3)
}
