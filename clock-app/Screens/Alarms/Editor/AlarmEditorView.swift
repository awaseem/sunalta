import AlarmKit
import SwiftData
import SwiftUI

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(ClockDisplaySettings.self) private var clockSettings
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var step = AlarmEditorStep.time
    @State private var draft: AlarmEditorDraft
    @State private var isLandscape = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var footerHeight: CGFloat = 100
    @State private var idealFormHeight: CGFloat = 240
    private let alarm: AlarmRecord?

    init(alarm: AlarmRecord? = nil, theme: AppTheme = .defaultTheme) {
        self.alarm = alarm
        _draft = State(initialValue: alarm.map { AlarmEditorDraft(alarm: $0, theme: theme) }
                       ?? AlarmEditorDraft(theme: theme))
    }

    var body: some View {
        NavigationStack {
            // Pass the full viewport and safe-area insets to the existing RealityKit renderer.
            GeometryReader { geometry in
                let display = ClockTimeDisplay(date: draft.time, format: clockSettings.format,
                                               calendar: calendar, locale: locale)
                // Compact-height phones retain the stacked editor even in landscape.
                let usesColumns = horizontalSizeClass == .regular && verticalSizeClass == .regular && isLandscape
                let columnWidth = geometry.size.width / 2
                let layout = AlarmEditorLayoutMetrics(
                    availableHeight: geometry.size.height,
                    headerHeight: 0,
                    footerHeight: footerHeight,
                    idealFormHeight: idealFormHeight
                )
                let previewDescription = "Alarm preview, \(display.text), \(AlarmRepeatSummary.text(for: draft.repeatDays))"
                ZStack(alignment: .leading) {
                    AlarmTimePreview(
                        display: display,
                        previewHeight: usesColumns ? geometry.size.height : layout.previewHeight,
                        previewTopInset: 0,
                        contentSafeAreaInsets: UIEdgeInsets(
                            top: geometry.safeAreaInsets.top, left: 0,
                            bottom: geometry.safeAreaInsets.bottom, right: 0
                        )
                    )
                    .frame(width: usesColumns ? columnWidth : nil)
                    .ignoresSafeArea()
                    .accessibilityElement()
                    .accessibilityLabel(previewDescription)
                    .accessibilityHint("Drag to change the viewing angle. Release to return to the front view.")
                    .accessibilityHidden(!usesColumns)

                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: usesColumns ? 0 : layout.previewHeight)
                            .allowsHitTesting(false)
                            .accessibilityElement()
                            .accessibilityLabel(previewDescription)
                            .accessibilityHint("Drag to change the viewing angle. Release to return to the front view.")
                            .accessibilityHidden(usesColumns)
                        AlarmEditorStepContainer(step: step, draft: $draft, idealHeight: $idealFormHeight)
                            .frame(height: usesColumns
                                   ? max(0, geometry.size.height - footerHeight)
                                   : layout.formHeight)
                        AlarmEditorContinueButton(isFinalStep: step.next == nil, isEditing: alarm != nil,
                                                  isSaving: isSaving, onContinue: continueStep)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
                    }
                    .frame(maxWidth: usesColumns ? columnWidth : .infinity)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: idealFormHeight)
            }
            .background(theme.palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AlarmEditorToolbar(isEditing: alarm != nil, step: step,
                                   onBack: goBack, onCancel: { dismiss() })
            }
        }
        .background {
            // Opening the keyboard must not switch a portrait editor to columns.
            Color.clear
                .ignoresSafeArea(.keyboard)
                .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: {
                    isLandscape = $0
                }
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

#Preview("Wide alarm editor", traits: .landscapeLeft) {
    AlarmPreviewContainer { AlarmEditorView() }
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.verticalSizeClass, .regular)
}

#Preview("New alarm · AM/PM") {
    AlarmPreviewContainer(timeFormat: .twelveHour) { AlarmEditorView() }
}
