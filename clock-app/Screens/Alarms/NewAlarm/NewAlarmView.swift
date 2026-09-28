import SwiftData
import SwiftUI

struct NewAlarmView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let titles = ["Time", "Repeat", "Snooze"]
    private let subtitles = ["24-hour time", "Choose the days. Leave empty for a one-time alarm.",
                             "Choose how long to snooze."]

    @State private var step = 0
    @State private var time = Calendar.autoupdatingCurrent.date(
        from: DateComponents(year: 2001, month: 1, day: 1, hour: 7, minute: 0)
    ) ?? .now
    @State private var repeatDays: Set<ClockWeekday> = []
    @State private var snoozeEnabled = true
    @State private var snoozeMinutes = 10
    @State private var saveError: String?

    private var timeComponents: DateComponents {
        Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: time)
    }

    private var displayTime: String {
        String(format: "%02d:%02d", timeComponents.hour ?? 7, timeComponents.minute ?? 0)
    }

    var body: some View {
        GeometryReader { geometry in
            let previewHeight = min(340, max(160, geometry.size.height * 0.40))
            ZStack {
                AlarmClockPreview(
                    time: displayTime, days: repeatDays,
                    previewHeight: previewHeight,
                    contentSafeAreaInsets: UIEdgeInsets(
                        top: geometry.safeAreaInsets.top, left: 0,
                        bottom: geometry.safeAreaInsets.bottom, right: 0
                    )
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    NewAlarmHeader(step: step, onBack: goBack, onCancel: { dismiss() })
                    Color.clear
                        .frame(height: previewHeight)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel("Alarm preview, \(displayTime), \(AlarmRepeatSummary.text(for: repeatDays))")
                        .accessibilityHint("Drag to change the viewing angle. Release to return to the front view.")
                    if step == 0 {
                        // Keep the native wheels outside a scrolling container when space permits.
                        ViewThatFits(in: .vertical) {
                            stepContent.fixedSize(horizontal: false, vertical: true)
                            ScrollView { stepContent }
                        }
                        Spacer(minLength: 0)
                    } else {
                        ScrollView { stepContent }
                            .id(step)
                    }
                    footer
                }
            }
        }
        .alert("Couldn't save alarm", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(titles[step]).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                if step == 0 {
                    Spacer()
                    Text("24 H").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
            }
            if step > 0 {
                Text(subtitles[step]).font(.subheadline).foregroundStyle(.secondary)
            }
            switch step {
            case 0: timePicker
            case 1: AlarmRepeatPicker(repeatDays: $repeatDays)
            default: AlarmSnoozeOptions(snoozeEnabled: $snoozeEnabled, snoozeMinutes: $snoozeMinutes)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private var timePicker: some View {
        DatePicker("Alarm time", selection: $time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "en_GB"))
            .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        Button {
            if step < 2 { changeStep(to: step + 1) }
            else { save() }
        } label: {
            Text(step == 2 ? "Create alarm" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(colorScheme == .dark ? Color.white : Color.black)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: 560)
    }

    private func goBack() {
        if step > 0 { changeStep(to: step - 1) }
        else { dismiss() }
    }

    private func changeStep(to next: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { step = next }
    }

    private func save() {
        do {
            let alarm = try AlarmRecord(
                hour: timeComponents.hour ?? 7, minute: timeComponents.minute ?? 0, isEnabled: false,
                repeatDays: repeatDays, snoozeEnabled: snoozeEnabled,
                snoozeDurationMinutes: snoozeMinutes
            )
            modelContext.insert(alarm)
            do { try modelContext.save() }
            catch {
                modelContext.delete(alarm)
                throw error
            }
            dismiss()
        } catch { saveError = error.localizedDescription }
    }
}

#Preview("New alarm") {
    NewAlarmView()
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
}
