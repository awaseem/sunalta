import SwiftUI

struct ClockLightingControls: View {
    @Binding var settings: ClockLightingSettings
    @Binding var isEditing: Bool

    var body: some View {
        VStack {
            ClockLightingSlider(title: "Brightness", range: 0...6000,
                                display: (settings.strength / 2600).formatted(.percent.precision(.fractionLength(0))),
                                value: $settings.strength, isEditing: $isEditing)
            ClockLightingSlider(title: "Ambient light", range: -3...3,
                                display: settings.fill.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always())),
                                value: $settings.fill, isEditing: $isEditing)
            ClockLightingSlider(title: "Direction", range: -180...180,
                                display: "\(settings.direction.formatted(.number.precision(.fractionLength(0))))°",
                                value: $settings.direction, isEditing: $isEditing)
            ClockLightingSlider(title: "Light angle", range: 5...75,
                                display: "\(settings.tilt.formatted(.number.precision(.fractionLength(0))))°",
                                value: $settings.tilt, isEditing: $isEditing)
        }
    }
}
