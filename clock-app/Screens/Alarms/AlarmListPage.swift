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
