import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appTheme) private var theme
    @Environment(AlarmRuntime.self) private var runtime
    @Query(sort: [SortDescriptor(\AlarmRecord.hour), SortDescriptor(\AlarmRecord.minute)])
    private var alarms: [AlarmRecord]
    @State private var alarmEditor: AlarmEditorDestination?
    @State private var isLandscape = false
    @State private var isScrolling = false
    @State private var isClockVisible = true
    @State private var pagePosition = ScrollPosition(edge: .top)
    @State private var portraitShowsAlarms = false

    var body: some View {
        // The renderer needs the full viewport and its safe areas for camera placement.
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let pageHeight = geometry.size.height + insets.top + insets.bottom
            let pageWidth = geometry.size.width + insets.leading + insets.trailing
            let columnWidth = isLandscape ? pageWidth / 2 : pageWidth
            let layout = isLandscape
                ? AnyLayout(HStackLayout(spacing: 0))
                : AnyLayout(VStackLayout(spacing: 0))
            ScrollView(isLandscape ? [] : .vertical) {
                layout {
                    Group {
                        if runtime.isAlarmPresented {
                            // Release the custom renderer while the alarm's RealityViews are visible.
                            Color.clear
                        } else {
                            HomeClockPage(
                                isScrolling: !isLandscape && isScrolling,
                                isVisible: (isLandscape || isClockVisible) && alarmEditor == nil,
                                showsAlarmHint: !isLandscape,
                                availableHeight: geometry.size.height,
                                safeAreaInsets: EdgeInsets(top: insets.top, leading: insets.leading,
                                                           bottom: insets.bottom,
                                                           trailing: isLandscape ? 0 : insets.trailing)
                            )
                        }
                    }
                    .frame(width: columnWidth, height: pageHeight)
                    .clipped()

                    AlarmListPage(
                        alarms: alarms, isActive: isLandscape || !isClockVisible,
                        createAlarm: { presentEditor(.create) },
                        editAlarm: { presentEditor(.edit($0)) },
                        returnToClock: isLandscape ? nil : {
                            withAnimation(reduceMotion ? nil : .smooth) {
                                pagePosition.scrollTo(edge: .top)
                            }
                        }
                    )
                    // Keep the navigation container at the display edge so Duo
                    // can place its toolbar in the trailing system bar region.
                    // Its native toolbar handles the bottom safe area; outer
                    // padding would leave a blank strip below the scroll view.
                    .frame(width: columnWidth, height: pageHeight - insets.top)
                    .padding(.top, insets.top)
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 0, for: .scrollContent)
            .defaultScrollAnchor(.top)
            .scrollPosition($pagePosition)
            .scrollTargetBehavior(.paging)
            .onScrollPhaseChange { _, phase, context in
                guard !isLandscape else { return }
                isScrolling = phase != .idle
                if phase == .idle {
                    let offset = context.geometry.contentOffset.y + context.geometry.contentInsets.top
                    portraitShowsAlarms = offset >= pageHeight / 2
                }
            }
            .onScrollGeometryChange(for: Bool.self) { scroll in
                scroll.contentOffset.y + scroll.contentInsets.top < pageHeight - 1
            } action: { _, visible in
                if !isLandscape { isClockVisible = visible }
            }
            .onChange(of: isLandscape) {
                restorePagePosition(pageHeight: pageHeight)
            }
            .onChange(of: pageHeight) {
                restorePagePosition(pageHeight: pageHeight)
            }
            .frame(width: pageWidth, height: pageHeight)
            .ignoresSafeArea()
        }
        .background(theme.palette.background)
        .background {
            // Measure the viewport independently of keyboard presentation.
            Color.clear
                .ignoresSafeArea(.keyboard)
                .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: {
                    isLandscape = $0
                }
        }
        .fullScreenCover(item: $alarmEditor) { destination in
            AlarmEditorView(alarm: destination.alarm, theme: theme)
                .appTheme(theme)
        }
        .onChange(of: runtime.isAlarmPresented) { _, presented in
            guard presented else { return }
            alarmEditor = nil
            portraitShowsAlarms = true
            if !isLandscape { pagePosition.scrollTo(edge: .bottom) }
        }
        .onOpenURL { url in
            guard url == ClockWidgetPreferences.clockURL else { return }
            alarmEditor = nil
            portraitShowsAlarms = false
            isClockVisible = true
            pagePosition.scrollTo(edge: .top)
        }
    }

    private func presentEditor(_ destination: AlarmEditorDestination) {
        portraitShowsAlarms = true
        alarmEditor = destination
    }

    private func restorePagePosition(pageHeight: CGFloat) {
        isScrolling = false
        if isLandscape {
            pagePosition.scrollTo(edge: .top)
        } else {
            isClockVisible = !portraitShowsAlarms
            pagePosition.scrollTo(y: portraitShowsAlarms ? pageHeight : 0)
        }
    }
}

#Preview("Portrait") {
    AlarmPreviewContainer { HomeScreen() }
}

#Preview("Landscape", traits: .landscapeLeft) {
    AlarmPreviewContainer { HomeScreen() }
}
