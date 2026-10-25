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
                    Picker("Alarm sound", selection: pickerSelection) {
                        ForEach(AlarmSound.allCases) { sound in
                            Text(sound.title).tag(AlarmSoundSelection.named(sound.rawValue))
                        }
                        Text("System default").tag(AlarmSoundSelection.systemDefault)
                        if case .named(let name) = selection, AlarmSound(rawValue: name) == nil {
                            Text("Previous sound").tag(selection)
                        }
                        if case .theme = pickerSelection.wrappedValue {
                            Text("Unavailable sound").tag(selection)
                        }
                    }
                    .pickerStyle(.inline)
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

                Button(preview.playingSelection == selection ? "Stop preview" : "Preview sound",
                       systemImage: preview.playingSelection == selection ? "stop.fill" : "play.fill") {
                    preview.toggle(selection)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(theme.palette.selection)
                .accessibilityHint("Plays the selected alarm sound once.")
                .accessibilityIdentifier("alarmSoundPreview")
                .disabled(fileName == nil)
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

    // Show the captured theme's track as the selected item without a duplicate theme option.
    private var pickerSelection: Binding<AlarmSoundSelection> {
        Binding(
            get: {
                if case .theme(let id) = selection,
                   let sound = AppTheme.available.first(where: { $0.id == id })?.audio.alarm {
                    return .named(sound.rawValue)
                }
                return selection
            },
            set: { selection = $0 }
        )
    }

    private var selectionTitle: String {
        switch pickerSelection.wrappedValue {
        case .systemDefault: "System default"
        case .theme: "Unavailable sound"
        case .named(let name): AlarmSound(rawValue: name)?.title ?? "Previous sound"
        }
    }
}
