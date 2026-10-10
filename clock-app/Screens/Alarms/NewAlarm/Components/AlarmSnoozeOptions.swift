import SwiftUI

struct AlarmSnoozeOptions: View {
    @Environment(\.appTheme) private var theme
    @Binding var snoozeEnabled: Bool
    @Binding var snoozeMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Allow snooze", isOn: $snoozeEnabled)
                .font(.headline)
                .tint(theme.palette.control)
                .padding(18)
                .background(theme.palette.surface, in: .rect(cornerRadius: 18))
            if snoozeEnabled {
                Text("Snooze duration").font(.subheadline).foregroundStyle(theme.palette.secondaryForeground)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                    ForEach([5, 10, 15, 20, 25, 30], id: \.self) { minutes in
                        Button { snoozeMinutes = minutes } label: {
                            Text("\(minutes) min")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(theme.palette.surface, in: .rect(cornerRadius: 16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(snoozeMinutes == minutes ? theme.palette.selection : .clear, lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(snoozeMinutes == minutes ? .isSelected : [])
                    }
                }
            }
        }
    }
}
