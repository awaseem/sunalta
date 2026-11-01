import SwiftUI
import WidgetKit

@main
struct ClockWidgets: WidgetBundle {
    var body: some Widget {
        SmallClockWidget()
        ClockAlarmLiveActivity()
    }
}
