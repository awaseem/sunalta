import SwiftUI

/// Only the clock reveal settles on a page boundary; alarms keep native free scrolling.
nonisolated struct HomeScrollTargetBehavior: ScrollTargetBehavior {
    let clockHeight: CGFloat
    // SwiftUI can retain the behavior from the start of a drag. Read the current threshold at release.
    let hasPulledPastReturnThreshold: Binding<Bool>
    let isPaging: Bool

    func properties(context: PropertiesContext) -> Properties {
        // Match the system's shorter deceleration for the clock transition only.
        isPaging ? PagingScrollTargetBehavior().properties(context: context) : Properties()
    }

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard context.axes.contains(.vertical), clockHeight > 0 else { return }
        if context.originalTarget.rect.minY < clockHeight - 1 {
            PagingScrollTargetBehavior().updateTarget(&target, context: context)
            target.rect.origin.y = min(clockHeight, target.rect.minY)
            return
        }
        target.rect.origin.y = destination(
            proposedOffset: target.rect.minY,
            originalOffset: context.originalTarget.rect.minY
        )
    }

    func destination(proposedOffset: CGFloat, originalOffset: CGFloat) -> CGFloat {
        // A fling from within the list stops at its beginning. A new pull can reveal the clock.
        if originalOffset > clockHeight + 1 {
            return max(clockHeight, proposedOffset)
        }

        if originalOffset >= clockHeight - 1 {
            guard proposedOffset < clockHeight else { return proposedOffset }
            // Actual scroll distance, not projected momentum, commits the return to the clock.
            return hasPulledPastReturnThreshold.wrappedValue ? 0 : clockHeight
        }

        return proposedOffset
    }
}
