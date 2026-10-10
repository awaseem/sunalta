import SwiftUI

extension EnvironmentValues {
    @Entry var appTheme: AppTheme = .defaultTheme
}

struct AppThemeModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, theme)
            .preferredColorScheme(theme.colorScheme)
            .foregroundStyle(theme.palette.foreground)
            .tint(theme.palette.control)
            .background(theme.palette.background.ignoresSafeArea())
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        modifier(AppThemeModifier(theme: theme))
    }
}
