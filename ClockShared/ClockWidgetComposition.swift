import CoreGraphics

/// One reference canvas keeps the baked light source aligned with the live weekday label.
nonisolated enum ClockWidgetComposition {
    static let side: CGFloat = 188
    static let numerals = CGRect(x: 9, y: 59, width: 170, height: 111)
    static let header = CGRect(x: 17, y: 15, width: 154, height: 34)
    static let weekdayLight = CGRect(x: 17, y: 15, width: 64, height: 34)
}
