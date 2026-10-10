import AlarmKit
import SwiftData
import SwiftUI

struct AlarmListPage: View {
    @Environment(\.appTheme) private var theme
    @Environment(AlarmRuntime.self) private var runtime
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
                        .foregroundStyle(theme.palette.secondaryForeground)
                }
                Spacer(minLength: 12)
                Button("Add alarm", systemImage: "plus") { showingNewAlarm = true }
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(theme.palette.control)
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
                    .tint(theme.palette.control)
                    .foregroundStyle(theme.palette.onControl)
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
                AppSettingsButton()
            }
            Button("OK", role: .cancel) { schedulingError = nil }
        } message: {
            Text(schedulingError ?? "Please try again.")
        }
    }

    private func setEnabled(_ enabled: Bool, for alarm: AlarmRecord) async {
        guard updatingAlarmID == nil else { return }
        updatingAlarmID = alarm.id
        defer { updatingAlarmID = nil }
        do {
            try await runtime.setEnabled(enabled, for: alarm)
        } catch {
            schedulingError = error.localizedDescription
        }
    }

}

#Preview("Saved alarms") {
    AlarmPreviewContainer {
        ScrollView { AlarmListPage() }
            .background(AppTheme.white.palette.background)
    }
}
