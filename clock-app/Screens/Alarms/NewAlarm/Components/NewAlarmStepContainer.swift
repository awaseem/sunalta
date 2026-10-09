import SwiftUI

struct NewAlarmStepContainer: View {
    let step: NewAlarmStep
    @Binding var draft: NewAlarmDraft

    var body: some View {
        VStack(spacing: 0) {
            if step == .time {
                // Keep native wheels outside scrolling content when they fit.
                ViewThatFits(in: .vertical) {
                    NewAlarmStepContent(step: step, draft: $draft)
                        .fixedSize(horizontal: false, vertical: true)
                    ScrollView { NewAlarmStepContent(step: step, draft: $draft) }
                }
                Spacer(minLength: 0)
            } else {
                ScrollView { NewAlarmStepContent(step: step, draft: $draft) }
                    .id(step)
            }
        }
    }
}
