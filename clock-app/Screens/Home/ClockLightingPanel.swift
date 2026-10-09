import SwiftUI

struct ClockLightingPanel: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var section = ClockAppearanceSection.finish
    @Binding var settings: ClockLightingSettings
    @Binding var isEditing: Bool
    var onClose: () -> Void

    private var backgroundColor: Binding<Color> {
        Binding {
            settings.backgroundColor(for: colorScheme)
        } set: { color in
            if colorScheme == .dark { settings.darkBackground = color }
            else { settings.lightBackground = color }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Appearance").font(.headline)
                Spacer()
                Button("Reset") { settings = ClockLightingSettings() }
                    .font(.subheadline)
                Button("Close appearance controls", systemImage: "xmark.circle.fill", action: onClose)
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                .accessibilityLabel("Close appearance controls")
            }
            Picker("Appearance controls", selection: $section) {
                ForEach(ClockAppearanceSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            switch section {
            case .background:
                ColorPicker("Background color", selection: backgroundColor, supportsOpacity: false)
                    .font(.subheadline)
                Text("Stays fixed as you adjust the lighting. Each mode has its own color.")
                    .font(.caption).foregroundStyle(.secondary)
            case .lighting:
                ClockLightingSlider(title: "Brightness", range: 0...6000,
                                    display: "\(Int(settings.strength / 2600 * 100))%",
                                    value: $settings.strength, isEditing: $isEditing)
                ClockLightingSlider(title: "Ambient light", range: -3...3,
                                    display: settings.fill.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always())),
                                    value: $settings.fill, isEditing: $isEditing)
                ClockLightingSlider(title: "Direction", range: -180...180,
                                    display: "\(Int(settings.direction))°",
                                    value: $settings.direction, isEditing: $isEditing)
                ClockLightingSlider(title: "Light angle", range: 5...75,
                                    display: "\(Int(settings.tilt))°",
                                    value: $settings.tilt, isEditing: $isEditing)
            case .finish:
                ClockLightingSlider(title: "Shimmer", range: 0...1,
                                    display: "\(Int(settings.shimmer * 100))%",
                                    value: $settings.shimmer, isEditing: $isEditing)
                Text("Drag across the numbers to catch the light.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
        .onDisappear { isEditing = false }
    }

}
