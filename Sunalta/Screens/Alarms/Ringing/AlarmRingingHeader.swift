import SwiftUI

struct AlarmRingingHeader: View {
    @Environment(\.appTheme) private var theme
    let alarm: AlarmRecord
    let display: ClockTimeDisplay
    var showsFallback: Bool
    @Binding var timeFrame: CGRect

    var body: some View {
        VStack {
            Color.clear
                .aspectRatio(2, contentMode: .fit)
                .onGeometryChange(for: CGRect.self) { geometry in
                    geometry.frame(in: .named("alarmArtwork"))
                } action: { timeFrame = $0 }
                .overlay {
                    if showsFallback {
                        Text(display.text)
                            .font(.largeTitle)
                            .monospacedDigit()
                            .foregroundStyle(theme.palette.foreground)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Alarm time, \(display.text)")
                .accessibilityAddTraits(.isHeader)
            if let period = display.period {
                Text(period)
                    .font(.headline)
                    .foregroundStyle(theme.palette.clockPeriod)
                    .accessibilityHidden(true)
            }
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.title2)
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
