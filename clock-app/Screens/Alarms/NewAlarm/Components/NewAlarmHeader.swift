import SwiftUI

struct NewAlarmHeader: View {
    @Environment(\.appTheme) private var theme
    let step: Int
    let stepCount: Int
    let onBack: () -> Void
    let onCancel: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack {
                Button(step == 0 ? "Cancel new alarm" : "Previous step",
                       systemImage: step == 0 ? "xmark" : "chevron.left", action: onBack)
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel(step == 0 ? "Cancel new alarm" : "Previous step")
                Spacer()
                VStack(spacing: 6) {
                    Text("NEW ALARM")
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
                .accessibilityLabel("New alarm, step \(step + 1) of \(stepCount)")
                Spacer()
                if step > 0 {
                    Button("Cancel new alarm", systemImage: "xmark", action: onCancel)
                        .labelStyle(.iconOnly)
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
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
