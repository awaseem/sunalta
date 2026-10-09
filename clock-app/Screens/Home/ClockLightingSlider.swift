import SwiftUI

struct ClockLightingSlider: View {
    let title: String
    let range: ClosedRange<Double>
    let display: String
    @Binding var value: Double
    @Binding var isEditing: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                Spacer()
                Text(display).monospacedDigit().foregroundStyle(.secondary)
            }
            .font(.caption)
            Slider(value: $value, in: range, onEditingChanged: { isEditing = $0 })
                .accessibilityLabel(title)
                .accessibilityValue(display)
        }
    }
}
