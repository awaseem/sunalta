import SwiftUI

/// Positions the header on the same reference canvas used by the lighting exporter.
struct ClockWidgetCalendarLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let side = min(bounds.width, bounds.height)
        let scale = side / ClockWidgetComposition.side
        let origin = CGPoint(x: bounds.midX - side / 2, y: bounds.midY - side / 2)
        subviews[0].place(at: origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: side, height: side))
        let header = ClockWidgetComposition.header
        subviews[1].place(at: CGPoint(x: origin.x + header.minX * scale,
                                     y: origin.y + header.minY * scale), anchor: .topLeading,
                          proposal: ProposedViewSize(width: header.width * scale, height: header.height * scale))
    }
}
