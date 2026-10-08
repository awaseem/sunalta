import SwiftUI

struct ClockLightingPanel: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var section = Section.finish
    @Binding var settings: ClockLightingSettings
    @Binding var isEditing: Bool
    var onClose: () -> Void

    private enum Section: String, CaseIterable {
        case background = "Background", lighting = "Lighting", finish = "Finish"
    }

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
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close appearance controls")
            }
            Picker("Appearance controls", selection: $section) {
                ForEach(Section.allCases, id: \.self) { section in
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
                slider("Brightness", value: $settings.strength, range: 0...6000,
                       display: "\(Int(settings.strength / 2600 * 100))%")
                slider("Ambient light", value: $settings.fill, range: -3...3,
                       display: String(format: "%+.1f", settings.fill))
                slider("Direction", value: $settings.direction, range: -180...180,
                       display: "\(Int(settings.direction))°")
                slider("Light angle", value: $settings.tilt, range: 5...75,
                       display: "\(Int(settings.tilt))°")
            case .finish:
                slider("Shimmer", value: $settings.shimmer, range: 0...1,
                       display: "\(Int(settings.shimmer * 100))%")
                Text("Drag across the numbers to catch the light.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .onDisappear { isEditing = false }
    }

    private func slider(_ title: String, value: Binding<Double>,
                        range: ClosedRange<Double>, display: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                Spacer()
                Text(display).monospacedDigit().foregroundStyle(.secondary)
            }
            .font(.caption)
            Slider(value: value, in: range, onEditingChanged: { isEditing = $0 })
                .accessibilityLabel(title)
                .accessibilityValue(display)
        }
    }
}
