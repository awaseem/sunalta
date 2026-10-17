import SwiftUI

struct ClockSettingsMenu: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(ClockAudioService.self) private var audioService

    var body: some View {
        @Bindable var audioService = audioService
        Menu("Settings", systemImage: "gearshape") {
            Picker("Theme", selection: Binding(
                get: { settings.theme.id },
                set: { settings.select(AppTheme.resolve(id: $0)) }
            )) {
                ForEach(AppTheme.available) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
            Section("Sound") {
                if settings.theme.audio.music != nil {
                    Toggle("Music", systemImage: "music.note", isOn: $audioService.musicEnabled)
                }
                Toggle("Sound Effects", systemImage: "speaker.wave.2", isOn: $audioService.soundEffectsEnabled)
            }
        }
        .labelStyle(.iconOnly)
        .font(.subheadline)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityHint("Choose a theme and manage clock sounds")
    }
}
