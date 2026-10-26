import OSLog
import UIKit

/// Serializes the system's asynchronous icon changes so the latest theme wins.
@MainActor
final class ThemeAppIcon {
    private let canUpdate: () -> Bool
    private let currentName: () -> String?
    private let setName: (String?) async throws -> Void
    private var desiredName: String?
    private var isUpdating = false

    init(
        canUpdate: @escaping () -> Bool = {
            UIApplication.shared.supportsAlternateIcons && UIApplication.shared.applicationState == .active
        },
        currentName: @escaping () -> String? = { UIApplication.shared.alternateIconName },
        setName: @escaping (String?) async throws -> Void = {
            try await UIApplication.shared.setAlternateIconName($0)
        }
    ) {
        self.canUpdate = canUpdate
        self.currentName = currentName
        self.setName = setName
    }

    func synchronize(with theme: AppTheme) async {
        desiredName = theme.appIconName
        guard !isUpdating, canUpdate() else { return }
        isUpdating = true
        defer { isUpdating = false }

        // An in-flight UIKit request cannot be cancelled. A newer request replaces
        // the desired name and is applied after that request completes.
        while canUpdate(), currentName() != desiredName {
            let requestedName = desiredName
            do {
                try await setName(requestedName)
            } catch {
                Logger(subsystem: "dev.ambitionsoftware.clock-app", category: "ThemeAppIcon")
                    .error("Could not update app icon: \(error.localizedDescription)")
                // Keep the theme usable. Retry on the next selection or foreground.
                if requestedName == desiredName { return }
            }
        }
    }
}
