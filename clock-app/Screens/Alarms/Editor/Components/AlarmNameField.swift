import SwiftUI

struct AlarmNameField: View {
    @Environment(\.appTheme) private var theme
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Alarm name", text: $name, prompt: Text("e.g. Morning workout"))
            .font(.body)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .focused($isFocused)
            .onSubmit { isFocused = false }
            .padding()
            .background(theme.palette.surface, in: .rect(cornerRadius: 18))
            .accessibilityLabel("Alarm name, optional")
            .accessibilityHint("You can create the alarm without a name.")
    }
}

#Preview("Optional name") {
    @Previewable @State var draft = AlarmEditorDraft()
    AlarmEditorStepContent(step: .name, draft: $draft)
        .appTheme(.white)
}

#Preview("Long name, large text") {
    @Previewable @State var draft = AlarmEditorDraft(name: "Morning workout before heading to work")
    AlarmEditorStepContent(step: .name, draft: $draft)
        .dynamicTypeSize(.accessibility3)
        .appTheme(.white)
}
