import SwiftUI

struct ThemePalette: Equatable {
    var background: Color
    let surface: Color
    let foreground: Color
    let secondaryForeground: Color
    let control: Color
    let onControl: Color
    let selection: Color
    let separator: Color
    let error: Color
    var clockPeriod: Color { foreground.opacity(0.7) }

    /// Derived colors follow the supplied foreground, control, and background unless overridden.
    init(
        background: Color,
        foreground: Color,
        selection: Color,
        control: Color? = nil,
        onControl: Color? = nil,
        surface: Color? = nil,
        secondaryForeground: Color? = nil,
        separator: Color? = nil,
        error: Color = .red
    ) {
        self.background = background
        self.foreground = foreground
        self.selection = selection
        self.control = control ?? foreground
        self.onControl = onControl ?? background
        self.surface = surface ?? foreground.opacity(0.06)
        self.secondaryForeground = secondaryForeground ?? foreground.opacity(0.6)
        self.separator = separator ?? (control ?? foreground).opacity(0.15)
        self.error = error
    }
}
