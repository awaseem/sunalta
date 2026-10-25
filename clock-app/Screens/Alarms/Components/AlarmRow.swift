import SwiftUI

struct AlarmRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.appTheme) private var theme
    private let content: AlarmRowContent
    private let isEnabled: Bool
    private let isUpdating: Bool
    private let onEdit: () -> Void
    private let onEnabledChange: @MainActor @Sendable (Bool) -> Void

    init(alarm: AlarmRecord, isUpdating: Bool = false, onEdit: @escaping () -> Void,
         onEnabledChange: @escaping @MainActor @Sendable (Bool) -> Void = { _ in }) {
        // SwiftUI can retain and redraw a row during its deletion animation.
        // Capture values while the record is live; child views must not read it afterward.
        content = AlarmRowContent(hour: alarm.hour, minute: alarm.minute, name: alarm.label,
                                  repeatSummary: AlarmRepeatSummary.text(for: alarm.repeatDays),
                                  exitPointSummary: alarm.exitPointSummary, exitPointSymbol: alarm.exitPoint.symbol)
        isEnabled = alarm.isEnabled
        self.isUpdating = isUpdating
        self.onEdit = onEdit
        self.onEnabledChange = onEnabledChange
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading))
            : AnyLayout(HStackLayout(alignment: .top))
        layout {
            Button(action: onEdit) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit this alarm")
            AlarmEnabledToggle(hour: content.hour, minute: content.minute, isEnabled: isEnabled,
                               isUpdating: isUpdating, onEnabledChange: onEnabledChange)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.palette.surface, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
    }
}
