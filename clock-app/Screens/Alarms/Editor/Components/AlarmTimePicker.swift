import SwiftUI

struct AlarmTimePicker: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    @Binding var time: Date
    @ScaledMetric(relativeTo: .body) private var pickerHeight = 132

    var body: some View {
        DatePicker("Alarm time", selection: $time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, settings.format.locale(overriding: locale))
            .frame(height: pickerHeight)
            .clipped()
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var settings = ClockDisplaySettings(defaults: PreviewDefaults.make(timeFormat: .twelveHour))
    @Previewable @State var time = Date(timeIntervalSinceReferenceDate: 12 * 3600)
    AlarmTimePicker(time: $time)
        .appTheme(.white)
        .environment(settings)
}
