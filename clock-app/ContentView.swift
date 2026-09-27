import SwiftUI

struct ContentView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            BlenderClockView(date: context.date)
                .ignoresSafeArea()
        }
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
