import SwiftUI

struct AlarmTimePicker: View {
    @Binding var time: Date
    @ScaledMetric(relativeTo: .body) private var pickerHeight = 132

    var body: some View {
        DatePicker("Alarm time", selection: $time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "en_GB"))
            .frame(height: pickerHeight)
            .clipped()
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var time = Date.now
    AlarmTimePicker(time: $time)
        .appTheme(.white)
}
