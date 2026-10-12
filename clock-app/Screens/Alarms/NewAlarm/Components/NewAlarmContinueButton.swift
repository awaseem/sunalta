import SwiftUI

struct NewAlarmContinueButton: View {
    let isFinalStep: Bool
    let onContinue: () -> Void

    var body: some View {
        Button(isFinalStep ? "Create alarm" : "Continue", action: onContinue)
            .buttonStyle(.appCapsule(fillsWidth: true))
            .padding()
            .frame(maxWidth: 560)
    }
}
