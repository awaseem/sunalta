import SwiftUI

/// Keep momentum within the alarms; the next gesture at the header uses native paging.
nonisolated struct AlarmListScrollTargetBehavior: ScrollTargetBehavior {
    let topOffset: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard context.axes.contains(.vertical) else { return }
        target.rect.origin.y = destination(proposedOffset: target.rect.minY)
    }

    func destination(proposedOffset: CGFloat) -> CGFloat {
        max(topOffset, proposedOffset)
    }
}
