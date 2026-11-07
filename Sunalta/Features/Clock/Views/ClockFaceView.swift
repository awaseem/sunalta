import SwiftUI

struct ClockFaceView: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @State private var weekdayAnchor: CGPoint?
    @State private var weekdayFrame: CGRect = .zero
    @State private var periodAnchor: CGPoint?
    @State private var hasRevealedClock = false
    let isScrolling: Bool
    let isVisible: Bool
    let isEditingAppearance: Bool
    let showsAlarmHint: Bool
    let contentSafeAreaInsets: EdgeInsets

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.everyMinute) { context in
                let display = ClockTimeDisplay(date: context.date, format: settings.format,
                                               calendar: calendar, locale: locale)
                SculptedClockView(display: display, isScrolling: isScrolling, isVisible: isVisible,
                                 isEditingAppearance: isEditingAppearance,
                                 showsAlarmHint: showsAlarmHint,
                                 contentSafeAreaInsets: UIEdgeInsets(
                                    top: contentSafeAreaInsets.top, left: contentSafeAreaInsets.leading,
                                    bottom: contentSafeAreaInsets.bottom, right: contentSafeAreaInsets.trailing
                                 ), weekdayFrame: weekdayFrame,
                                 onWeekdayAnchorChange: { weekdayAnchor = $0 },
                                 onPeriodAnchorChange: { periodAnchor = $0 },
                                 onContentRevealed: { hasRevealedClock = true })
                    .overlay(alignment: .topLeading) {
                        if let weekdayAnchor {
                            ClockWeekdayLabel(date: context.date)
                                .opacity(hasRevealedClock ? 1 : 0)
                                .animation(.easeOut(duration: ClockEntranceAnimation.fadeDuration),
                                           value: hasRevealedClock)
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    geometry.frame(in: .named("clockFace"))
                                } action: { weekdayFrame = $0 }
                                .padding(.top, 8)
                                .offset(x: weekdayAnchor.x, y: weekdayAnchor.y)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if settings.showsPeriod, let period = display.period, let periodAnchor {
                            ClockPeriodLabel(period: period, anchor: periodAnchor,
                                             availableWidth: geometry.size.width)
                                .opacity(hasRevealedClock ? 1 : 0)
                                .animation(.easeOut(duration: ClockEntranceAnimation.fadeDuration),
                                           value: hasRevealedClock)
                        }
                    }
                    .coordinateSpace(name: "clockFace")
            }
        }
    }
}
