import SwiftUI

struct NewAlarmHeader: View {
    let step: Int
    let onBack: () -> Void
    let onCancel: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack {
                Button(action: onBack) {
                    Image(systemName: step == 0 ? "xmark" : "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .accessibilityLabel(step == 0 ? "Cancel new alarm" : "Previous step")
                Spacer()
                VStack(spacing: 6) {
                    Text("NEW ALARM")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                    HStack(spacing: 5) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(index <= step ? Color.primary : Color.secondary.opacity(0.25))
                                .frame(width: 24, height: 3)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("New alarm, step \(step + 1) of 3")
                Spacer()
                if step > 0 {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .accessibilityLabel("Cancel new alarm")
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
