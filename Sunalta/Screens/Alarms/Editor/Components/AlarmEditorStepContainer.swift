import SwiftUI

struct AlarmEditorStepContainer: View {
    let step: AlarmEditorStep
    @Binding var draft: AlarmEditorDraft
    @Binding var idealHeight: CGFloat

    var body: some View {
        // Use the form's natural height; scrolling is only needed when it cannot fit.
        ViewThatFits(in: .vertical) {
            AlarmEditorStepContent(step: step, draft: $draft)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { idealHeight = $0 }
            ScrollView {
                AlarmEditorStepContent(step: step, draft: $draft)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { idealHeight = $0 }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .id(step)
    }
}
