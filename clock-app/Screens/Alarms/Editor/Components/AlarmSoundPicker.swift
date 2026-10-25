import SwiftUI

struct AlarmSoundPicker: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Binding var selection: AlarmSoundSelection
    @State private var preview = AlarmSoundPreview()

    var body: some View {
        let fileName = AlarmSoundResolver().fileName(for: selection)
        VStack(alignment: .leading) {
            HStack {
                Menu {
                    ForEach(AlarmSound.allCases) { sound in
                        Button {
                            selection = .named(sound.rawValue)
                        } label: {
                            if selectedSound == sound {
                                Label(sound.title, systemImage: "checkmark")
                            } else {
                                Text(sound.title)
                            }
                        }
                        .accessibilityAddTraits(selectedSound == sound ? .isSelected : [])
                    }
                } label: {
                    HStack {
                        Text(selectionTitle)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "chevron.down")
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
                }
                .tint(theme.palette.foreground)
                .accessibilityLabel("Alarm sound")
                .accessibilityValue(selectionTitle)
                .accessibilityIdentifier("alarmSoundPicker")

                if fileName != nil {
                    Button(preview.playingSelection == selection ? "Stop preview" : "Preview sound",
                           systemImage: preview.playingSelection == selection ? "stop.fill" : "play.fill") {
                        preview.toggle(selection)
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(theme.palette.onControl)
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(theme.palette.control)
                    .accessibilityHint("Plays the selected alarm sound once.")
                    .accessibilityIdentifier("alarmSoundPreview")
                }
            }
            if let error = preview.errorMessage {
                Text(error).font(.footnote).foregroundStyle(theme.palette.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(theme.palette.surface, in: .rect(cornerRadius: 18))
        .onChange(of: selection) { preview.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { preview.stop() }
        }
        .onDisappear { preview.stop() }
        .task { await preview.observeInterruptions() }
    }

    private var selectedSound: AlarmSound? {
        switch selection {
        case .systemDefault: nil
        case .theme(let id): AppTheme.available.first { $0.id == id }?.audio.alarm
        case .named(let name): AlarmSound(rawValue: name)
        }
    }

    private var selectionTitle: String {
        if let selectedSound { return selectedSound.title }
        return switch selection {
        case .systemDefault: "System default"
        case .theme: "Unavailable sound"
        case .named: "Previous sound"
        }
    }
}
