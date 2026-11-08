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
    private static let enablesAppearanceControls = true
    @State private var showsAppearance = false
    @State private var appearanceAtTop = false
    #endif
    @State private var isEditingAppearance = false

    var body: some View {
        ClockFaceView(isScrolling: isScrolling,
                      isVisible: isVisible && scenePhase == .active,
                      isEditingAppearance: isEditingAppearance,
                      showsAlarmHint: showsAlarmHint,
                      contentSafeAreaInsets: safeAreaInsets)
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
