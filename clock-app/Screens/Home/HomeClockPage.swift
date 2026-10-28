import SwiftUI

struct HomeClockPage: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTheme) private var theme
    let isScrolling: Bool
    let isVisible: Bool
    let showsAlarmHint: Bool
    let availableHeight: CGFloat
    let safeAreaInsets: EdgeInsets
    #if DEBUG
    // Set to true while tuning themes to show the appearance controls.
    private static let enablesAppearanceControls = false
    @State private var showsAppearance = false
    @State private var appearanceAtTop = false
    #endif
    @State private var isEditingAppearance = false
    @State private var weekdayAnchor: CGPoint?
    @State private var weekdayFrame: CGRect = .zero
    @State private var hasRevealedClock = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            SculptedClockView(date: context.date, isScrolling: isScrolling,
                             isVisible: isVisible && scenePhase == .active,
                             isEditingAppearance: isEditingAppearance,
                             showsAlarmHint: showsAlarmHint,
                             contentSafeAreaInsets: UIEdgeInsets(
                top: safeAreaInsets.top, left: safeAreaInsets.leading,
                bottom: safeAreaInsets.bottom, right: safeAreaInsets.trailing
            ), weekdayFrame: weekdayFrame, onWeekdayAnchorChange: { weekdayAnchor = $0 },
                             onContentRevealed: { hasRevealedClock = true })
            .overlay(alignment: .topLeading) {
                if let weekdayAnchor {
                    ClockWeekdayLabel(date: context.date)
                        .opacity(hasRevealedClock ? 1 : 0)
                        .animation(.easeOut(duration: ClockEntranceAnimation.fadeDuration),
                                   value: hasRevealedClock)
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named("clockFace"))
                        } action: { weekdayFrame = $0 }
                        .padding(.top, 8)
                        .offset(x: weekdayAnchor.x, y: weekdayAnchor.y)
                }
            }
            .coordinateSpace(name: "clockFace")
        }
        .overlay(alignment: .bottom) {
            if showsAlarmHint {
                ClockAlarmHint(isActive: isVisible && !isScrolling && scenePhase == .active)
                    .padding(.horizontal)
                    .padding(.bottom, safeAreaInsets.bottom + 8)
            }
        }
        #if DEBUG
        .overlay(alignment: appearanceAtTop ? .top : .bottom) {
            if Self.enablesAppearanceControls && showsAppearance {
                ThemePickerPanel(isEditing: $isEditingAppearance,
                                 isAtTop: $appearanceAtTop,
                                 maximumControlsHeight: availableHeight * 0.24) {
                    showsAppearance = false
                }
                .padding(.horizontal, 20)
                .padding(.top, appearanceAtTop ? safeAreaInsets.top + 72 : 0)
                .padding(.bottom, appearanceAtTop ? 0 : safeAreaInsets.bottom + 16)
            }
        }
        .overlay(alignment: .topLeading) {
            if Self.enablesAppearanceControls {
                Button("Appearance", systemImage: "slider.horizontal.3") {
                    showsAppearance.toggle()
                }
                .font(.subheadline)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .foregroundStyle(theme.palette.onControl)
                .controlSize(.large)
                .frame(minWidth: 44, minHeight: 44)
                .padding(.top, safeAreaInsets.top)
                .padding()
            }
        }
        #endif
    }
}
