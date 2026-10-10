import SwiftUI

struct NewAlarmContinueButton: View {
    @Environment(\.appTheme) private var theme
    let isFinalStep: Bool
    let onContinue: () -> Void

    var body: some View {
        Button(action: onContinue) {
            Text(isFinalStep ? "Create alarm" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(theme.palette.onControl)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(theme.palette.control)
        .padding()
        .frame(maxWidth: 560)
    }
}
