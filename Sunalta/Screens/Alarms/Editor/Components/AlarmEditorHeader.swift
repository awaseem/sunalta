import SwiftUI

struct AlarmEditorHeader: View {
    @Environment(\.appTheme) private var theme
    let isEditing: Bool
    let step: Int
    let stepCount: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(isEditing ? "EDIT ALARM" : "NEW ALARM")
                .font(.caption.weight(.semibold))
                .tracking(2)
            HStack(spacing: 5) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? theme.palette.selection : theme.palette.separator)
                        .frame(width: 24, height: 3)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isEditing ? "Edit alarm" : "New alarm"), step \(step + 1) of \(stepCount)")
    }
}
