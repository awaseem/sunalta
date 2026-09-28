import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            let pageHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    TimelineView(.everyMinute) { context in
                        BlenderClockView(date: context.date, contentSafeAreaInsets: UIEdgeInsets(
                            top: geometry.safeAreaInsets.top, left: 0,
                            bottom: geometry.safeAreaInsets.bottom, right: 0
                        ))
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

                    AlarmListPage()
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                    .frame(minHeight: pageHeight, alignment: .top)
                }
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.top)
            .scrollTargetBehavior(.paging)
            .frame(height: pageHeight)
            .ignoresSafeArea()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Light") {
    ContentView()
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
        .preferredColorScheme(.dark)
}
