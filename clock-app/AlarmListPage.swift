import SwiftData
import SwiftUI

struct AlarmListPage: View {
    @Query(sort: [SortDescriptor(\AlarmRecord.hour), SortDescriptor(\AlarmRecord.minute)])
    private var alarms: [AlarmRecord]
    @State private var showingNewAlarm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Label("Clock", systemImage: "chevron.up")
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44)
                .accessibilityLabel("Swipe down to return to the clock")

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alarms")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(alarms.isEmpty ? "Your mornings, at your pace." : "Your daily rhythm.")
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Button {
                    showingNewAlarm = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.primary)
                .accessibilityLabel("Add alarm")
            }

            if alarms.isEmpty {
                ContentUnavailableView {
                    Label("No alarms yet", systemImage: "alarm")
                } description: {
                    Text("Give your next morning a time.")
                } actions: {
                    Button("Add your first alarm") {
                        showingNewAlarm = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
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
        .fullScreenCover(isPresented: $showingNewAlarm) {
            NewAlarmView()
        }
    }
}

private struct AlarmRow: View {
    let alarm: AlarmRecord

    private var repeatDescription: String {
        AlarmRepeatSummary.text(for: alarm.repeatDays)
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
        Text(String(format: "%02d:%02d", alarm.hour, alarm.minute))
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
