import SwiftData
import SwiftUI

struct AlarmListPage: View {
    @Query(sort: [SortDescriptor(\AlarmRecord.hour), SortDescriptor(\AlarmRecord.minute)])
    private var alarms: [AlarmRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Label("Clock", systemImage: "chevron.up")
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44)
                .accessibilityLabel("Swipe down to return to the clock")

            VStack(alignment: .leading, spacing: 6) {
                Text("Alarms")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(alarms.isEmpty ? "Your mornings, at your pace." : "Your daily rhythm.")
                    .foregroundStyle(.secondary)
            }

            if alarms.isEmpty {
                ContentUnavailableView {
                    Label("No alarms yet", systemImage: "alarm")
                } description: {
                    Text("Your saved alarms will appear here.")
                }
                .padding(.top, 48)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(alarms) { alarm in
                        AlarmRow(alarm: alarm)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

private struct AlarmRow: View {
    let alarm: AlarmRecord

    private var time: Date {
        Calendar.autoupdatingCurrent.date(from: DateComponents(
            year: 2001, month: 1, day: 1, hour: alarm.hour, minute: alarm.minute
        )) ?? .distantPast
    }

    private var repeatDescription: String {
        let days = alarm.repeatDays
        if days.isEmpty { return "Once" }
        if days.count == 7 { return "Every day" }
        if days == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        if days == [.saturday, .sunday] { return "Weekends" }
        return days.sorted { $0.rawValue < $1.rawValue }.map(\.abbreviation).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    timeLabel
                    Spacer(minLength: 16)
                    statusLabel
                }
                VStack(alignment: .leading, spacing: 8) {
                    timeLabel
                    statusLabel
                }
            }
            Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                .font(.headline)
            Text(repeatDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if alarm.requiresScanToStop {
                Label("Scan to stop", systemImage: "qrcode.viewfinder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private var timeLabel: some View {
        Text(time, format: .dateTime.hour().minute())
            .font(.system(.largeTitle, design: .rounded, weight: .regular))
            .monospacedDigit()
    }

    private var statusLabel: some View {
        Text(alarm.isEnabled ? "On" : "Off")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary, in: .capsule)
    }
}

#Preview("Saved alarms") {
    let container = try! ModelContainer(
        for: AlarmRecord.self, AlarmStopTarget.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let _ = container.mainContext.insert(try! AlarmRecord(
        hour: 7, minute: 0, label: "Early start",
        repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
    ))
    let _ = container.mainContext.insert(try! AlarmRecord(
        hour: 9, minute: 30, label: "Slow morning", isEnabled: false,
        repeatDays: [.saturday, .sunday]
    ))
    ScrollView {
        AlarmListPage()
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .modelContainer(container)
}
