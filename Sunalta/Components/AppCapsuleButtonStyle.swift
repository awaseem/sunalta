import SwiftUI

/// Shared sizing and theme colors, with native Liquid Glass button interactions.
struct AppCapsuleButtonStyle: PrimitiveButtonStyle {
    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .headline) private var minimumLabelHeight = 28
    @ScaledMetric(relativeTo: .headline) private var horizontalPadding = 12
    @ScaledMetric(relativeTo: .headline) private var verticalPadding = 4

    var fillsWidth = false

    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minimumLabelHeight)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .foregroundStyle(theme.palette.onControl)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(theme.palette.control)
    }
}

extension PrimitiveButtonStyle where Self == AppCapsuleButtonStyle {
    static var appCapsule: AppCapsuleButtonStyle { AppCapsuleButtonStyle() }

    static func appCapsule(fillsWidth: Bool) -> AppCapsuleButtonStyle {
        AppCapsuleButtonStyle(fillsWidth: fillsWidth)
    }
}

#Preview("Capsule buttons") {
    GlassEffectContainer {
        VStack {
            Button("Create alarm") {}
                .buttonStyle(.appCapsule(fillsWidth: true))
            Button("Scan a specific QR code", systemImage: "qrcode") {}
                .buttonStyle(.appCapsule(fillsWidth: true))
            Button("Continue") {}
                .buttonStyle(.appCapsule(fillsWidth: true))
                .disabled(true)
            Button("Reset") {}
                .buttonStyle(.appCapsule)
        }
        .padding()
    }
    .appTheme(.white)
}

#Preview("Accessibility text") {
    Button("Scan a specific QR code", systemImage: "qrcode") {}
        .buttonStyle(.appCapsule(fillsWidth: true))
        .padding()
        .appTheme(.white)
        .environment(\.dynamicTypeSize, .accessibility3)
}
