import AlarmKit
import SwiftData
import SwiftUI

struct AlarmListPage: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Query(sort: [SortDescriptor(\AlarmRecord.hour), SortDescriptor(\AlarmRecord.minute)])
    private var alarms: [AlarmRecord]
    @State private var showingNewAlarm = false
    @State private var updatingAlarmID: UUID?
    @State private var schedulingError: String?

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
                        AlarmRow(alarm: alarm, isUpdating: updatingAlarmID == alarm.id) { enabled in
                            Task { await setEnabled(enabled, for: alarm) }
                        }
                        .disabled(updatingAlarmID != nil)
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
        .alert("Couldn't update alarm", isPresented: Binding(
            get: { schedulingError != nil }, set: { if !$0 { schedulingError = nil } }
        )) {
            if AlarmManager.shared.authorizationState == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Button("OK", role: .cancel) { schedulingError = nil }
        } message: {
            Text(schedulingError ?? "Please try again.")
        }
        .task {
            refreshAlarmStates()
            for await systemAlarms in AlarmManager.shared.alarmUpdates {
                guard !Task.isCancelled else { return }
                synchronizeAlarmStates(systemAlarms)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshAlarmStates() }
        }
    }

    private func setEnabled(_ enabled: Bool, for alarm: AlarmRecord) async {
        guard updatingAlarmID == nil else { return }
        updatingAlarmID = alarm.id
        defer { updatingAlarmID = nil }
        do {
            if enabled { try await AlarmScheduler.schedule(alarm) }
            else { try AlarmScheduler.cancel(alarm) }
            alarm.isEnabled = enabled
            do { try modelContext.save() }
            catch {
                schedulingError = "The alarm is \(enabled ? "on" : "off"), but its status couldn't be saved. \(error.localizedDescription)"
            }
        } catch {
            schedulingError = error.localizedDescription
        }
    }

    private func refreshAlarmStates() {
        if AlarmManager.shared.authorizationState == .denied {
            synchronizeAlarmStates([])
        } else if let systemAlarms = try? AlarmManager.shared.alarms {
            synchronizeAlarmStates(systemAlarms)
        }
    }

    private func synchronizeAlarmStates(_ systemAlarms: [Alarm]) {
        let scheduledIDs = Set(systemAlarms.map(\.id))
        var changed = false
        for alarm in alarms where alarm.id != updatingAlarmID {
            let enabled = scheduledIDs.contains(alarm.id)
            if alarm.isEnabled != enabled {
                alarm.isEnabled = enabled
                changed = true
            }
        }
        if changed {
            do { try modelContext.save() }
            catch { schedulingError = "Couldn't save the alarm status. \(error.localizedDescription)" }
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
