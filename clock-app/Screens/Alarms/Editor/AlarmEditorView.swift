import AlarmKit
import SwiftData
import SwiftUI

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = AlarmEditorStep.time
    @State private var draft: AlarmEditorDraft
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var headerHeight: CGFloat = 44
    @State private var footerHeight: CGFloat = 100
    @State private var idealFormHeight: CGFloat = 240
    private let alarm: AlarmRecord?

    init(alarm: AlarmRecord? = nil) {
        self.alarm = alarm
        _draft = State(initialValue: alarm.map { AlarmEditorDraft(alarm: $0) } ?? AlarmEditorDraft())
    }

    var body: some View {
        // Pass the full viewport and safe-area insets to the existing RealityKit renderer.
        GeometryReader { geometry in
            let layout = AlarmEditorLayoutMetrics(
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
                    AlarmEditorHeader(isEditing: alarm != nil, step: step.rawValue,
                                      stepCount: AlarmEditorStep.allCases.count,
                                      onBack: goBack, onCancel: { dismiss() })
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                    Color.clear
                        .frame(height: layout.previewHeight)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel("Alarm preview, \(draft.displayTime), \(AlarmRepeatSummary.text(for: draft.repeatDays))")
                        .accessibilityHint("Drag to change the viewing angle. Release to return to the front view.")
                    AlarmEditorStepContainer(step: step, draft: $draft, idealHeight: $idealFormHeight)
                        .frame(height: layout.formHeight)
                    AlarmEditorContinueButton(isFinalStep: step.next == nil, isEditing: alarm != nil,
                                              isSaving: isSaving, onContinue: continueStep)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
                }
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: idealFormHeight)
        }
        .disabled(isSaving)
        .interactiveDismissDisabled(isSaving)
        .alert("Couldn't save alarm", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            if AlarmManager.shared.authorizationState == .denied {
                AppSettingsButton()
            }
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private func goBack() {
        if let previous = step.previous { changeStep(to: previous) }
        else { dismiss() }
    }

    private func changeStep(to next: AlarmEditorStep) {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) { step = next }
    }

    private func continueStep() {
        guard !isSaving else { return }
        if let next = step.next { changeStep(to: next) }
        else {
            isSaving = true
            Task { await save() }
        }
    }

    private func save() async {
        defer { isSaving = false }
        do {
            if let alarm {
                try await runtime.update(alarm, from: draft)
            } else {
                try AlarmEditorService(context: modelContext).create(draft)
            }
            dismiss()
        } catch { saveError = error.localizedDescription }
    }
}

#Preview("New alarm") {
    AlarmPreviewContainer { AlarmEditorView() }
}
