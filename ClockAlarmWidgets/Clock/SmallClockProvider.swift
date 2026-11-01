import WidgetKit

struct SmallClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallClockEntry {
        SmallClockEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallClockEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallClockEntry>) -> Void) {
        let current = entry()
        let schedule = ClockWidgetSchedule(now: current.date)
        let entries = schedule.dates.map { SmallClockEntry(date: $0, preferences: current.preferences) }
        completion(Timeline(entries: entries, policy: .after(schedule.refreshDate)))
    }

    private func entry() -> SmallClockEntry {
        let preferences = UserDefaults(suiteName: ClockWidgetPreferences.appGroup)
            .map { ClockWidgetPreferencesStore(defaults: $0).load() } ?? ClockWidgetPreferences()
        return SmallClockEntry(date: .now, preferences: preferences)
    }
}
