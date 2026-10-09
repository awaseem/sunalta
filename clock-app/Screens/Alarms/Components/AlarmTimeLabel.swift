import SwiftUI

struct AlarmTimeLabel: View {
    let hour: Int
    let minute: Int

    var body: some View {
        Text(AlarmTimeText.text(hour: hour, minute: minute))
            .font(.largeTitle)
            .fontDesign(.rounded)
            .monospacedDigit()
    }
}
