import SwiftUI

struct AlarmListHeader: View {
    @Environment(\.appTheme) private var theme
    let createAlarm: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Alarms")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Your daily rhythm.")
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
            Spacer(minLength: 12)
            Button("Add alarm", systemImage: "plus", action: createAlarm)
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(theme.palette.control)
        }
    }
}
