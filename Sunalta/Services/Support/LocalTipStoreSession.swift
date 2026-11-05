#if DEBUG && targetEnvironment(simulator)
import Foundation
import StoreKitTest

/// Activates the bundled store before any StoreKit API establishes a sandbox connection.
enum LocalTipStoreSession {
    static func startIfRequested() -> SKTestSession? {
        guard ProcessInfo.processInfo.arguments.contains("--local-storekit") else { return nil }
        do {
            let session = try SKTestSession(configurationFileNamed: "SupportTips")
            session.resetToDefaultState()
            return session
        } catch {
            // An explicitly requested development configuration must not silently use the live catalog.
            fatalError("Couldn't start local tip testing: \(error)")
        }
    }
}
#endif
