import AlarmKit
import SwiftData
import SwiftUI

struct AlarmListPage: View {
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.appTheme) private var theme
    @State private var updatingAlarmID: UUID?
    @State private var schedulingError: String?
    @State private var canReturnToClock = false
    @State private var activeSheet: AlarmPageSheet?
    let alarms: [AlarmRecord]
    var isActive = true
    let createAlarm: () -> Void
    let editAlarm: (AlarmRecord) -> Void
    var returnToClock: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if alarms.isEmpty {
                        AlarmEmptyState()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(alarms, id: \.persistentModelID) { alarm in
                                if alarm.modelContext != nil, !alarm.isDeleted {
                                    AlarmRow(alarm: alarm, isUpdating: updatingAlarmID == alarm.id, onEdit: {
                                        editAlarm(alarm)
                                    }) { enabled in
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
                        }
                        .swipeActionsContainer()
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(!isActive)
            .onScrollPhaseChange { oldPhase, phase, context in
                // A pull from the list's top returns to the clock after the finger lifts.
                // Deceleration through the top must not change pages.
                let offset = context.geometry.contentOffset.y + context.geometry.contentInsets.top
                if phase == .interacting {
                    canReturnToClock = offset <= 1
                }
                if isActive, let returnToClock, canReturnToClock,
                   oldPhase == .interacting, phase != .interacting, offset < -60 {
                    canReturnToClock = false
                    returnToClock()
                }
            }
            .background(theme.palette.background)
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(alarms.isEmpty ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Settings", systemImage: "gearshape") { activeSheet = .settings }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(theme.palette.control)
                    Button("Donations", systemImage: "heart") { activeSheet = .support }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(theme.palette.control)
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New alarm", systemImage: "plus", action: createAlarm)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .tint(theme.palette.control)
                        .foregroundStyle(theme.palette.onControl)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .support: ClockSupportSheet()
            case .settings: ClockSettingsView()
            }
        }
        .onOpenURL { url in
            if url == ClockWidgetPreferences.clockURL { activeSheet = nil }
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

#Preview("Welcome") {
    AlarmPreviewContainer {
        AlarmListPage(alarms: [], createAlarm: {}, editAlarm: { _ in })
    }
}
