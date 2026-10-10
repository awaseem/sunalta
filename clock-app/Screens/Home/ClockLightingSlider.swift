import SwiftUI

struct ClockLightingSlider: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let range: ClosedRange<Double>
    let display: String
    @Binding var value: Double
    @Binding var isEditing: Bool

    var body: some View {
        VStack {
            HStack {
                Text(title)
                Spacer()
                Text(display)
                    .monospacedDigit()
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
            .font(.caption)
            Slider(value: $value, in: range, onEditingChanged: { isEditing = $0 })
                .accessibilityLabel(title)
                .accessibilityValue(display)
        }
    }
}
