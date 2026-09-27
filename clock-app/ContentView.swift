import SwiftUI

struct ContentView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            BlenderClockView(date: context.date)
                .ignoresSafeArea()
        }
        .background(Color(white: 0.07))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
