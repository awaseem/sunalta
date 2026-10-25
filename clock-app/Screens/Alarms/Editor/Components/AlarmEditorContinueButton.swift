import SwiftUI

struct AlarmEditorContinueButton: View {
    let isFinalStep: Bool
    let isEditing: Bool
    let isSaving: Bool
    let onContinue: () -> Void

    var body: some View {
        Button(isSaving ? "Saving…" : isFinalStep ? (isEditing ? "Save changes" : "Create alarm") : "Continue",
               action: onContinue)
            .buttonStyle(.appCapsule(fillsWidth: true))
            .padding()
            .frame(maxWidth: 560)
    }
}
