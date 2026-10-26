import Foundation
import Testing
@testable import clock_app

@MainActor
struct ThemeAppIconTests {
    @Test func selectionDuringAnIconChangeAppliesTheLatestThemeAfterward() async {
        var current: String?
        var requests: [String?] = []
        var resumeFirstChange: CheckedContinuation<Void, Never>?
        let (started, continuation) = AsyncStream<Void>.makeStream()
        defer { continuation.finish() }
        let icon = ThemeAppIcon(canUpdate: { true }, currentName: { current }) { name in
            requests.append(name)
            if requests.count == 1 {
                await withCheckedContinuation { resume in
                    resumeFirstChange = resume
                    continuation.yield(())
                }
            }
            current = name
        }
        let firstChange = Task { await icon.synchronize(with: .midnight) }
        var events = started.makeAsyncIterator()
        await events.next()

        await icon.synchronize(with: .grass)
        // Returning to White while the first change is pending must restore nil.
        await icon.synchronize(with: .white)
        resumeFirstChange?.resume()
        await firstChange.value

        #expect(requests == [AppTheme.midnight.appIconName, nil])
        #expect(current == nil)
    }

    @Test func failedChangeCanRetryWithoutLoopingOrRepeatingSuccessfulChanges() async {
        var current: String?
        var attempts = 0
        let icon = ThemeAppIcon(canUpdate: { true }, currentName: { current }) { name in
            attempts += 1
            if attempts == 1 { throw CocoaError(.featureUnsupported) }
            current = name
        }

        await icon.synchronize(with: .grass)
        #expect(attempts == 1)
        #expect(current == nil)
        await icon.synchronize(with: .grass)
        await icon.synchronize(with: .grass)
        #expect(attempts == 2)
        #expect(current == AppTheme.grass.appIconName)
    }

    @Test func foregroundReconciliationUsesTheLatestSelection() async {
        var isActive = false
        var current: String?
        var requests: [String?] = []
        let icon = ThemeAppIcon(canUpdate: { isActive }, currentName: { current }) { name in
            requests.append(name)
            current = name
        }

        await icon.synchronize(with: .midnight)
        await icon.synchronize(with: .grass)
        #expect(requests.isEmpty)
        isActive = true
        await icon.synchronize(with: .grass)

        #expect(requests == [AppTheme.grass.appIconName])
    }
}
