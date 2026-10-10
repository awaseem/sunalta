import SwiftUI

struct ClockWeekdayLightControls: View {
    @Binding var glow: ClockWeekdayGlowSettings
    @Binding var isEditing: Bool

    var body: some View {
        VStack {
            ClockLightingSlider(
                title: "Brightness", range: 0...12000,
                display: (glow.brightness / 3000).formatted(.percent.precision(.fractionLength(0))),
                value: $glow.brightness, isEditing: $isEditing
            )
            ClockLightingSlider(
                title: "Spread", range: 15...85,
                display: glow.spread.formatted(.number.precision(.fractionLength(0))) + "°",
                value: $glow.spread, isEditing: $isEditing
            )
            ClockLightingSlider(
                title: "Direction", range: -90...90,
                display: glow.direction.formatted(.number.precision(.fractionLength(0))) + "°",
                value: $glow.direction, isEditing: $isEditing
            )
            ClockLightingSlider(
                title: "Reach", range: 1...10,
                display: (glow.reach / 5).formatted(.percent.precision(.fractionLength(0))),
                value: $glow.reach, isEditing: $isEditing
            )
            Text("0° shines upward. Negative angles aim left; positive angles aim right.")
                .font(.caption)
        }
    }
}
