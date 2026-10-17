import AlarmKit
import SwiftData
import SwiftUI

struct AlarmListPage: View {
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.appTheme) private var theme
    @Query(sort: [SortDescriptor(\AlarmRecord.hour), SortDescriptor(\AlarmRecord.minute)])
    private var alarms: [AlarmRecord]
    @State private var showingNewAlarm = false
    @State private var updatingAlarmID: UUID?
    @State private var schedulingError: String?
    var isScrolling = false
    let returnToClock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Button("Clock", systemImage: "chevron.up", action: returnToClock)
                    .font(.subheadline.weight(.medium))
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Return to the clock")
                Spacer()
                ClockSettingsMenu()
            }

            if alarms.isEmpty {
                AlarmEmptyState(isScrolling: isScrolling, isPresentingAlarm: showingNewAlarm) {
                    showingNewAlarm = true
                }
            } else {
                AlarmListHeader { showingNewAlarm = true }
                LazyVStack(spacing: 12) {
                    ForEach(alarms) { alarm in
                        AlarmRow(alarm: alarm, isUpdating: updatingAlarmID == alarm.id) { enabled in
                            Task { await setEnabled(enabled, for: alarm) }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                Task { await delete(alarm) }
                            }
                            .tint(theme.palette.selection)
                            .foregroundStyle(theme.palette.onControl)
                        }
                        .disabled(updatingAlarmID != nil)
                    }
                }
                .swipeActionsContainer()
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

    private func delete(_ alarm: AlarmRecord) async {
        guard updatingAlarmID == nil else { return }
        updatingAlarmID = alarm.id
        defer { updatingAlarmID = nil }
        do {
            try await runtime.delete(alarm)
        } catch {
            schedulingError = error.localizedDescription
        }
    }

}

#Preview("Saved alarms") {
    AlarmPreviewContainer {
        ScrollView { AlarmListPage(returnToClock: {}) }
            .background(AppTheme.white.palette.background)
    }
}
