import SwiftData
import SwiftUI

struct NewAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = NewAlarmStep.time
    @State private var draft = NewAlarmDraft()
    @State private var saveError: String?
    @State private var headerHeight: CGFloat = 44
    @State private var footerHeight: CGFloat = 100
    @State private var idealFormHeight: CGFloat = 240

    var body: some View {
        // Pass the full viewport and safe-area insets to the existing RealityKit renderer.
        GeometryReader { geometry in
            let layout = NewAlarmLayoutMetrics(
                availableHeight: geometry.size.height,
                headerHeight: headerHeight,
                footerHeight: footerHeight,
                idealFormHeight: idealFormHeight
            )
            ZStack {
                AlarmTimePreview(
                    time: draft.displayTime,
                    previewHeight: layout.previewHeight,
                    previewTopInset: headerHeight,
                    contentSafeAreaInsets: UIEdgeInsets(
                        top: geometry.safeAreaInsets.top, left: 0,
                        bottom: geometry.safeAreaInsets.bottom, right: 0
                    )
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    NewAlarmHeader(step: step.rawValue, stepCount: NewAlarmStep.allCases.count, onBack: goBack, onCancel: { dismiss() })
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                    Color.clear
                        .frame(height: layout.previewHeight)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel("Alarm preview, \(draft.displayTime), \(AlarmRepeatSummary.text(for: draft.repeatDays))")
                        .accessibilityHint("Drag to change the viewing angle. Release to return to the front view.")
                    NewAlarmStepContainer(step: step, draft: $draft, idealHeight: $idealFormHeight)
                        .frame(height: layout.formHeight)
                    NewAlarmContinueButton(isFinalStep: step == .exitPoint, onContinue: continueStep)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
                }
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: idealFormHeight)
        }
        .alert("Couldn't save alarm", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private func goBack() {
        if let previous = step.previous { changeStep(to: previous) }
        else { dismiss() }
    }

    private func changeStep(to next: NewAlarmStep) {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) { step = next }
    }

    private func continueStep() {
        if let next = step.next { changeStep(to: next) }
        else { save() }
    }

    private func save() {
        do {
            try AlarmCreationService(context: modelContext).create(draft)
            dismiss()
        } catch { saveError = error.localizedDescription }
    }
}

#Preview("New alarm") {
    NewAlarmView()
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
        .appTheme(.white)
}
