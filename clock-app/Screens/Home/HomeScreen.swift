import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTheme) private var theme
    @State private var isScrolling = false
    @State private var isClockVisible = true
    @State private var showsAppearance = false
    @State private var appearanceAtTop = false
    @State private var isEditingAppearance = false
    @State private var weekdayAnchor: CGPoint?
    @State private var weekdayFrame: CGRect = .zero

    var body: some View {
        // RealityKit needs both the viewport height and safe-area insets for its camera placement.
        GeometryReader { geometry in
            let pageHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    TimelineView(.everyMinute) { context in
                        SculptedClockView(date: context.date, isScrolling: isScrolling,
                                         isVisible: isClockVisible && scenePhase == .active,
                                         isEditingAppearance: isEditingAppearance,
                                         contentSafeAreaInsets: UIEdgeInsets(
                            top: geometry.safeAreaInsets.top, left: 0,
                            bottom: geometry.safeAreaInsets.bottom, right: 0
                        ), weekdayFrame: weekdayFrame, onWeekdayAnchorChange: { weekdayAnchor = $0 })
                        .overlay(alignment: .topLeading) {
                            if let weekdayAnchor {
                                ClockWeekdayLabel(date: context.date)
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
                        VStack(spacing: 8) {
                            Text("Alarms")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 32)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Swipe up for alarms")
                    }
                    .overlay(alignment: appearanceAtTop ? .top : .bottom) {
                        if showsAppearance {
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
                        Button("Appearance", systemImage: "slider.horizontal.3") {
                            showsAppearance.toggle()
                        }
                        .font(.subheadline)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .foregroundStyle(theme.palette.onControl)
                        .controlSize(.large)
                        .frame(minWidth: 44, minHeight: 44)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding()
                    }

                    AlarmListPage()
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                    .frame(minHeight: pageHeight, alignment: .top)
                }
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.top)
            .scrollTargetBehavior(.paging)
            .onScrollPhaseChange { _, phase in
                isScrolling = phase != .idle
            }
            .onScrollGeometryChange(for: Bool.self) { scroll in
                scroll.contentOffset.y < pageHeight
            } action: { _, visible in
                isClockVisible = visible
            }
            .frame(height: pageHeight)
            .ignoresSafeArea()
        }
        .background(theme.palette.background)
    }
}

#Preview("White theme") {
    AlarmPreviewContainer { HomeScreen() }
}
