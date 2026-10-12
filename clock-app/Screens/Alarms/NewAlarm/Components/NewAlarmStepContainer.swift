import SwiftUI

struct NewAlarmStepContainer: View {
    let step: NewAlarmStep
    @Binding var draft: NewAlarmDraft
    @Binding var idealHeight: CGFloat

    var body: some View {
        // Use the form's natural height; scrolling is only needed when it cannot fit.
        ViewThatFits(in: .vertical) {
            NewAlarmStepContent(step: step, draft: $draft)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { idealHeight = $0 }
            ScrollView {
                NewAlarmStepContent(step: step, draft: $draft)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { idealHeight = $0 }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .id(step)
    }
}
