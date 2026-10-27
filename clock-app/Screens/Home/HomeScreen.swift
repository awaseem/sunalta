import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTheme) private var theme
    @Query(sort: [SortDescriptor(\AlarmRecord.hour), SortDescriptor(\AlarmRecord.minute)])
    private var alarms: [AlarmRecord]
    @State private var alarmEditor: AlarmEditorDestination?
    @State private var isScrolling = false
    @State private var isClockVisible = true
    @State private var pagePosition = ScrollPosition(edge: .top)
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
        // RealityKit needs both the viewport height and safe-area insets for its camera placement.
        GeometryReader { geometry in
            let pageHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    TimelineView(.everyMinute) { context in
                        SculptedClockView(date: context.date, isScrolling: isScrolling,
                                         isVisible: isClockVisible && scenePhase == .active && alarmEditor == nil,
                                         isEditingAppearance: isEditingAppearance,
                                         contentSafeAreaInsets: UIEdgeInsets(
                            top: geometry.safeAreaInsets.top, left: 0,
                            bottom: geometry.safeAreaInsets.bottom, right: 0
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
                    .frame(height: pageHeight)
                    .overlay(alignment: .bottom) {
                        ClockAlarmHint(isActive: isClockVisible && !isScrolling && scenePhase == .active)
                            .padding(.horizontal)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    }
                    #if DEBUG
                    .overlay(alignment: appearanceAtTop ? .top : .bottom) {
                        if Self.enablesAppearanceControls && showsAppearance {
                            ThemePickerPanel(isEditing: $isEditingAppearance,
                                             isAtTop: $appearanceAtTop,
                                             maximumControlsHeight: geometry.size.height * 0.24) {
                                showsAppearance = false
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, appearanceAtTop ? geometry.safeAreaInsets.top + 72 : 0)
                            .padding(.bottom, appearanceAtTop ? 0 : geometry.safeAreaInsets.bottom + 16)
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
                            .padding(.top, geometry.safeAreaInsets.top)
                            .padding()
                        }
                    }
                    #endif

                    AlarmListPage(alarms: alarms, isActive: !isClockVisible,
                                  createAlarm: { alarmEditor = .create },
                                  editAlarm: { alarmEditor = .edit($0) },
                                  returnToClock: {
                        withAnimation(.smooth) { pagePosition.scrollTo(edge: .top) }
                    })
                    .frame(height: geometry.size.height)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 0, for: .scrollContent)
            .defaultScrollAnchor(.top)
            .scrollPosition($pagePosition)
            .scrollTargetBehavior(.paging)
            .onScrollPhaseChange { _, phase in
                isScrolling = phase != .idle
            }
            .onScrollGeometryChange(for: Bool.self) { scroll in
                scroll.contentOffset.y + scroll.contentInsets.top < pageHeight - 1
            } action: { _, visible in
                isClockVisible = visible
            }
            .frame(height: pageHeight)
            .ignoresSafeArea()
        }
        .background(theme.palette.background)
        .fullScreenCover(item: $alarmEditor) { destination in
            AlarmEditorView(alarm: destination.alarm, theme: theme)
        }
    }
}

#Preview("White theme") {
    AlarmPreviewContainer { HomeScreen() }
}
