extension AppTheme {
    /// Define each theme in its own file under Definitions, then register it here.
    /// Keep IDs stable: selection and appearance adjustments are stored by theme ID.
    static let available: [AppTheme] = [.white, .midnight, .grass]
    static let defaultTheme = white

    static func resolve(id: String?) -> AppTheme {
        available.first { $0.id == id } ?? defaultTheme
    }
}
