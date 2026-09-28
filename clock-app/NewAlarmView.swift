import SwiftData
import SwiftUI

struct NewAlarmView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var time = Calendar.autoupdatingCurrent.date(
        from: DateComponents(year: 2001, month: 1, day: 1, hour: 7, minute: 0)
    ) ?? .now
    @State private var repeatDays: Set<ClockWeekday> = []
    @State private var snoozeEnabled = true
    @State private var snoozeMinutes = 10
    @State private var saveError: String?

    private let titles = ["Time", "Repeat", "Snooze"]
    private let subtitles = ["24-hour time", "Choose the days. Leave empty for a one-time alarm.",
                             "Choose how long to snooze."]

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
                    header
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
            case 1: repeatOptions
            default: snoozeOptions
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        GlassEffectContainer {
            HStack {
                Button {
                    if step > 0 {
                        changeStep(to: step - 1)
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: step == 0 ? "xmark" : "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
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
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .accessibilityLabel("Cancel new alarm")
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var timePicker: some View {
        DatePicker("Alarm time", selection: $time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "en_GB"))
            .frame(maxWidth: .infinity)
    }

    private var timeComponents: DateComponents {
        Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: time)
    }

    private var displayTime: String {
        String(format: "%02d:%02d", timeComponents.hour ?? 7, timeComponents.minute ?? 0)
    }

    private var repeatOptions: some View {
        HStack(spacing: 6) {
            ForEach(AlarmRepeatSummary.orderedDays, id: \.rawValue) { day in
                Button {
                    if repeatDays.contains(day) { repeatDays.remove(day) }
                    else { repeatDays.insert(day) }
                } label: {
                    Text(String(day.abbreviation.prefix(1)))
                        .font(.body.weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundStyle(repeatDays.contains(day)
                            ? (colorScheme == .dark ? Color.black : Color.white)
                            : Color.primary)
                        .background(repeatDays.contains(day)
                            ? (colorScheme == .dark ? Color.white : Color.black)
                            : Color.primary.opacity(0.08), in: .circle)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.name)
                .accessibilityValue(repeatDays.contains(day) ? "Selected" : "Not selected")
                .accessibilityAddTraits(repeatDays.contains(day) ? .isSelected : [])
            }
        }
        .frame(maxWidth: 420)
    }

    private var snoozeOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Allow snooze", isOn: $snoozeEnabled)
                .font(.headline)
                .tint(.primary)
                .padding(18)
                .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 18))
            if snoozeEnabled {
                Text("Snooze duration").font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                    ForEach([5, 10, 15, 20, 25, 30], id: \.self) { minutes in
                        Button { snoozeMinutes = minutes } label: {
                            Text("\(minutes) min")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
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
        }
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
