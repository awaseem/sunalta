import SwiftUI

struct ClockWeekdayControls: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(\.appTheme) private var theme
    @Environment(\.self) private var environment
    @Binding var isEditing: Bool

    var body: some View {
        @Bindable var settings = settings
        VStack {
            ClockLightingSlider(
                title: "Size", range: ClockWeekdayAppearance.sizeRange,
                display: settings.weekday.size.formatted(.number.precision(.fractionLength(0))) + " pt",
                value: $settings.weekday.size, isEditing: $isEditing
            )
            Picker("Weight", selection: $settings.weekday.weight) {
                ForEach(ClockWeekdayWeight.allCases, id: \.self) { weight in
                    Text(weight.rawValue).tag(weight)
                }
            }
            .pickerStyle(.menu)
            ColorPicker("Text and light color", selection: Binding(
                get: { Color(settings.weekday.glow.color) },
                set: { settings.weekday.glow.color = $0.resolve(in: environment) }
            ), supportsOpacity: false)
            .font(.subheadline)
            ClockLightingSlider(
                title: "Text glow", range: 0...1,
                display: settings.weekday.glow.halo.formatted(.percent.precision(.fractionLength(0))),
                value: $settings.weekday.glow.halo, isEditing: $isEditing
            )
            DisclosureGroup("Light on numbers") {
                ClockWeekdayLightControls(glow: $settings.weekday.glow, isEditing: $isEditing)
            }
            .font(.subheadline)
            Text("The light stays with the weekday and shares its color.")
                .font(.caption)
                .foregroundStyle(theme.palette.secondaryForeground)
        }
    }
}
