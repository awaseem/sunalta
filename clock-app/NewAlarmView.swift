import SwiftData
import SwiftUI

struct NewAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var time = AlarmTimeInput()
    @State private var repeatDays: Set<ClockWeekday> = []
    @State private var snoozeEnabled = true
    @State private var snoozeMinutes = 9
    @State private var saveError: String?
    @State private var showingDiscardConfirmation = false

    private let titles = ["Set your time", "Find your rhythm", "A little more time"]
    private let subtitles = ["Enter four digits. 07:30 for a fresh start.",
                             "Choose your days, or leave it as a one-time alarm.",
                             "Decide how long your next morning can wait."]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                AlarmClockPreview(time: time.displayTime, days: step == 0 ? [] : repeatDays)
                    .frame(height: min(280, max(160, geometry.size.height * 0.30)))
                    .accessibilityLabel("Alarm preview, \(time.displayTime), \(AlarmRepeatSummary.text(for: repeatDays))")
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(titles[step])
                                .font(.title2.bold())
                                .accessibilityAddTraits(.isHeader)
                            Text(subtitles[step])
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        switch step {
                        case 0: timeKeypad
                        case 1: repeatOptions
                        default: snoozeOptions
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                footer
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .confirmationDialog("Discard this alarm?", isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard Alarm", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
        .alert("Couldn't save alarm", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private var header: some View {
        HStack {
            Button {
                if step > 0 {
                    changeStep(to: step - 1)
                } else if time.digits.isEmpty {
                    dismiss()
                } else {
                    showingDiscardConfirmation = true
                }
            } label: {
                Image(systemName: step == 0 ? "xmark" : "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(step == 0 ? "Cancel new alarm" : "Previous step")
            Spacer()
            VStack(spacing: 6) {
                Text("NEW ALARM")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                HStack(spacing: 5) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= step ? Color.primary : Color.secondary.opacity(0.25))
                            .frame(width: 24, height: 3)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("New alarm, step \(step + 1) of 3")
            Spacer()
            if step > 0 {
                Button {
                    showingDiscardConfirmation = true
                } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Cancel new alarm")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var timeKeypad: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(0..<4) { index in
                    if index == 2 { Text(":").font(.title2) }
                    let digits = Array(time.digits)
                    Text(index < digits.count ? String(digits[index]) : "–")
                        .font(.system(.title2, design: .monospaced, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(index == digits.count ? Color.primary : .clear, lineWidth: 1.5)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("24-hour time input")
            .accessibilityValue(time.isComplete ? time.displayTime : "\(time.digits.count) of 4 digits entered, \(time.digits)")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 8) {
                ForEach(1...9, id: \.self) { digit in digitButton(digit) }
                Text("24 H")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                digitButton(0)
                Button { time.deleteLast() } label: {
                    Image(systemName: "delete.left")
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .disabled(time.digits.isEmpty)
                .accessibilityLabel("Delete last digit")
            }
            .buttonStyle(.plain)
        }
    }

    private func digitButton(_ digit: Int) -> some View {
        Button { time.append(digit) } label: {
            Text("\(digit)")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                .opacity(time.canAppend(digit) ? 1 : 0.25)
        }
        .disabled(!time.canAppend(digit))
        .accessibilityLabel("\(digit)")
    }

    private var repeatOptions: some View {
        VStack(spacing: 8) {
            ForEach(AlarmRepeatSummary.orderedDays, id: \.rawValue) { day in
                Button {
                    if repeatDays.contains(day) { repeatDays.remove(day) }
                    else { repeatDays.insert(day) }
                } label: {
                    HStack {
                        Text(day.name).font(.body.weight(.medium))
                        Spacer()
                        Image(systemName: repeatDays.contains(day) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 46)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityValue(repeatDays.contains(day) ? "Selected" : "Not selected")
                .accessibilityAddTraits(repeatDays.contains(day) ? .isSelected : [])
            }
        }
    }

    private var snoozeOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Allow snooze", isOn: $snoozeEnabled)
                .font(.headline)
                .tint(.primary)
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
            if snoozeEnabled {
                Text("Snooze duration").font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                    ForEach([5, 9, 10, 15, 30], id: \.self) { minutes in
                        Button { snoozeMinutes = minutes } label: {
                            Text("\(minutes) min")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(snoozeMinutes == minutes ? Color.primary : .clear, lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(snoozeMinutes == minutes ? .isSelected : [])
                    }
                }
            }
            Text("\(time.displayTime) · \(AlarmRepeatSummary.text(for: repeatDays))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("New alarms are saved turned off.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        Button {
            if step < 2 { changeStep(to: step + 1) }
            else { save() }
        } label: {
            HStack {
                Spacer()
                Text(step == 2 ? "Create alarm" : "Continue").font(.headline)
                Spacer()
                Image(systemName: step == 2 ? "checkmark" : "arrow.right")
            }
            .padding(18)
            .foregroundStyle(Color(uiColor: .systemBackground))
            .background(Color.primary, in: .capsule)
            .opacity(time.isComplete ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!time.isComplete)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: 560)
    }

    private func changeStep(to next: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { step = next }
    }

    private func save() {
        guard time.isComplete else { return }
        do {
            let alarm = try AlarmRecord(
                hour: time.hour, minute: time.minute, isEnabled: false,
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

enum AlarmRepeatSummary {
    static var orderedDays: [ClockWeekday] {
        let first = Calendar.autoupdatingCurrent.firstWeekday
        return (0..<7).compactMap { ClockWeekday(rawValue: (first - 1 + $0) % 7 + 1) }
    }

    static func text(for days: Set<ClockWeekday>) -> String {
        if days.isEmpty { return "Once" }
        if days.count == 7 { return "Every day" }
        if days == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        if days == [.saturday, .sunday] { return "Weekends" }
        return orderedDays.filter { days.contains($0) }.map(\.abbreviation).joined(separator: ", ")
    }
}

#Preview("New alarm") {
    NewAlarmView()
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
}
