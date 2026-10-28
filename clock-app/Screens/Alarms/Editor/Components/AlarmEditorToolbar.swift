import SwiftUI

struct AlarmEditorToolbar: ToolbarContent {
    @Environment(\.appTheme) private var theme
    @Environment(\.self) private var environment
    let isEditing: Bool
    let step: AlarmEditorStep
    let onBack: () -> Void
    let onCancel: () -> Void

    var body: some ToolbarContent {
        if step.previous != nil {
            ToolbarItem(placement: .cancellationAction) {
                Button("Previous step", systemImage: "chevron.left", action: onBack)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(theme.palette.control)
            }
        }
        ToolbarItem(placement: closePlacement) {
            Button("Cancel alarm changes", systemImage: "xmark", action: onCancel)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderedProminent)
                .tint(theme.palette.control)
                .foregroundStyle(theme.palette.onControl)
        }
        ToolbarItem(placement: .principal) {
            AlarmEditorHeader(isEditing: isEditing, step: step.rawValue,
                              stepCount: AlarmEditorStep.allCases.count)
        }
    }

    private var closePlacement: ToolbarItemPlacement {
        // Preserve Duo's navigation ordering; horizontal bars keep Close opposite Back.
        if #available(iOS 27.1, *), environment.toolbarVerticalEdge != nil {
            return .cancellationAction
        }
        return .topBarTrailing
    }
}
