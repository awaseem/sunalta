import SwiftUI

struct ThemePickerPanel: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(\.appTheme) private var theme
    @Environment(\.self) private var environment
    @State private var section = ClockAppearanceSection.theme
    @Binding var isEditing: Bool
    let onClose: () -> Void

    var body: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading) {
            HStack {
                Text("Appearance").font(.headline)
                Spacer()
                Button("Reset", action: settings.resetCurrentTheme)
                    .font(.subheadline)
                    .accessibilityHint("Restores the selected theme's default appearance")
                Button("Close appearance controls", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
            }
            Picker("Appearance controls", selection: $section) {
                ForEach(ClockAppearanceSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            switch section {
            case .theme:
                ForEach(AppTheme.available) { option in
                    ThemeOptionButton(theme: option, isSelected: settings.theme.id == option.id) {
                        settings.select(option)
                    }
                }
            case .background:
                ColorPicker("Background color", selection: Binding(
                    get: { settings.theme.palette.background },
                    set: { settings.setBackground($0.resolve(in: environment)) }
                ), supportsOpacity: false)
                .font(.subheadline)
                Text("Saved for this theme. Stays fixed as you adjust the lighting.")
                    .font(.caption)
                    .foregroundStyle(theme.palette.secondaryForeground)
            case .lighting:
                ClockLightingControls(settings: $settings.lighting, isEditing: $isEditing)
            case .finish:
                ClockLightingSlider(title: "Shimmer", range: 0...1,
                                    display: settings.shimmer.formatted(.percent.precision(.fractionLength(0))),
                                    value: $settings.shimmer, isEditing: $isEditing)
                Text("Drag across the numbers to catch the light.")
                    .font(.caption)
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
            if let message = settings.errorMessage {
                Text(message).font(.caption).foregroundStyle(theme.palette.error)
            }
        }
        .padding()
        .background(theme.palette.background, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.palette.separator)
        }
        .shadow(color: theme.panelShadow.color, radius: theme.panelShadow.radius,
                x: theme.panelShadow.x, y: theme.panelShadow.y)
        .onDisappear { isEditing = false }
    }
}

#Preview {
    ThemePickerPanel(isEditing: .constant(false), onClose: {})
        .environment(ThemeSettings(defaults: UserDefaults(suiteName: "ThemePickerPreview") ?? .standard))
        .appTheme(.white)
        .padding()
}
