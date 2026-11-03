import SwiftUI

extension AppTheme {
    private static let whiteAccent = Color.Resolved(red: 1, green: 0.08, blue: 0.16)

    static let white = AppTheme(
        id: "white",
        name: "White",
        colorScheme: .light,
        palette: .white,
        clock: ClockAppearance(
            numeralColor: .black,
            lighting: ClockLightingSettings(
                direction: 0.36364316940307617, tilt: 50.24, strength: 2600, fill: 0
            )
        ),
        weekday: ClockWeekdayAppearance(
            glow: ClockWeekdayGlowSettings(
                color: whiteAccent,
                halo: 0.09848485141992569,
                brightness: 3012.121081352234,
                spread: 60,
                direction: 20.36363124847412,
                reach: 5.518181622028351
            )
        ),
        clockFlyby: .bird,
        audio: ClockAudioConfiguration(
            alarm: .morningLight,
            music: ClockSound(fileName: "white-dawn.mp3", volume: 0.25),
            musicLoopDelay: .seconds(10),
            flyby: ClockSound(fileName: "bird-sounds.wav", volume: 0.65),
            entrance: ClockSound(fileName: "clock-entrance.wav", volume: 0.4)
        )
    )
}
