import SwiftUI

struct SettingsSoundSection: View {
    @Environment(ClockAudioService.self) private var audioService
    @Environment(\.appTheme) private var theme

    var body: some View {
        @Bindable var audioService = audioService
        VStack(alignment: .leading) {
            Text("Sound")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                if theme.audio.music != nil {
                    Toggle(isOn: $audioService.musicEnabled) {
                        SettingsSoundLabel(title: "Music", detail: "Background ambience", systemImage: "music.note")
                    }
                    .padding(.vertical, 12)
                    Divider().overlay(theme.palette.separator)
                }
                Toggle(isOn: $audioService.soundEffectsEnabled) {
                    SettingsSoundLabel(title: "Sound Effects", detail: "Clock and nature sounds",
                                       systemImage: "speaker.wave.2")
                }
                .padding(.vertical, 12)
            }
            .tint(theme.palette.selection)
            .padding(.horizontal)
            .background(theme.palette.surface, in: .rect(cornerRadius: 20))
        }
    }
}
