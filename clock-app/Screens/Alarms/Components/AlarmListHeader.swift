import SwiftUI

struct AlarmListHeader: View {
    let createAlarm: () -> Void

    var body: some View {
        HStack {
            Text("Alarms")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            Button("New", systemImage: "plus", action: createAlarm)
                .buttonStyle(.appCapsule)
                .fixedSize()
                .accessibilityLabel("New alarm")
        }
    }
}
