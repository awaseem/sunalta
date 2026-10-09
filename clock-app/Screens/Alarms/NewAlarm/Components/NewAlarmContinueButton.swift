import SwiftUI

struct NewAlarmContinueButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let isFinalStep: Bool
    let onContinue: () -> Void

    var body: some View {
        Button(action: onContinue) {
            Text(isFinalStep ? "Create alarm" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(colorScheme == .dark ? Color.white : Color.black)
        .padding()
        .frame(maxWidth: 560)
    }
}
