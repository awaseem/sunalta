import Testing
import UIKit
@testable import clock_app

@Suite(.serialized)
@MainActor
struct ClockRenderingTests {
    @Test func settledClockDoesNotRenderUntilItsContentChanges() async throws {
        let clock = ClockRenderView(theme: .white)
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        clock.show(date: date)
        let window = try host(clock)
        defer {
            clock.stop()
            window.isHidden = true
        }
        try await waitForFrame(clock, after: 0)
        try await Task.sleep(for: .milliseconds(200))
        let settledFrames = clock.renderedFrameCount

        // SwiftUI may update the representable without changing the displayed minute.
        for _ in 0..<10 {
            clock.show(date: date)
            clock.applyTheme(.white)
        }
        try await Task.sleep(for: .milliseconds(500))
        #expect(clock.renderedFrameCount == settledFrames)

        clock.show(date: date.addingTimeInterval(60))
        try await waitForFrame(clock, after: settledFrames)
        let changedFrames = clock.renderedFrameCount
        try await Task.sleep(for: .milliseconds(200))
        #expect(clock.renderedFrameCount == changedFrames)
    }

    @Test func suspendedClockCoalescesChangesAndResumesWithoutReloading() async throws {
        let clock = ClockRenderView(theme: .white)
        let window = try host(clock)
        defer {
            clock.stop()
            window.isHidden = true
        }
        try await waitForFrame(clock, after: 0)
        clock.isRenderingEnabled = false
        try await Task.sleep(for: .milliseconds(200))
        let suspendedFrames = clock.renderedFrameCount
        for index in 0..<20 {
            clock.showAlarm(time: index.isMultiple(of: 2) ? "07:00" : "08:00")
            clock.entranceAngles = [Float(index) * 0.01, 0]
        }
        try await Task.sleep(for: .milliseconds(200))
        #expect(clock.renderedFrameCount == suspendedFrames)
        #expect(clock.isReady)

        clock.isRenderingEnabled = true
        try await waitForFrame(clock, after: suspendedFrames)
        try await Task.sleep(for: .milliseconds(200))
        #expect(clock.renderedFrameCount == suspendedFrames + 1)
    }

    @Test func grassBreezeStopsRenderingWhenAmbientAnimationIsDisabled() async throws {
        let clock = ClockRenderView(theme: .grass)
        let window = try host(clock)
        defer {
            clock.stop()
            window.isHidden = true
        }
        try await waitForFrame(clock, after: 0)
        clock.allowsAmbientAnimation = true
        try await waitForFrame(clock, after: clock.renderedFrameCount)
        try await waitForFrame(clock, after: clock.renderedFrameCount)

        clock.allowsAmbientAnimation = false
        try await Task.sleep(for: .milliseconds(200))
        let pausedFrames = clock.renderedFrameCount
        try await Task.sleep(for: .milliseconds(300))
        #expect(clock.renderedFrameCount == pausedFrames)

        clock.allowsAmbientAnimation = true
        try await waitForFrame(clock, after: pausedFrames)
    }

    @Test func pagingKeepsThePreparedRendererForImmediateInteraction() async throws {
        let page = ClockPageView(theme: .white, scene: .numbers)
        let date = Date.now
        func update(scrolling: Bool, visible: Bool) {
            page.update(date: date, theme: .white, insets: .zero,
                        isScrolling: scrolling, isVisible: visible,
                        isEditingAppearance: false, weekdayFrame: .zero, allowsFlybys: false)
        }
        update(scrolling: false, visible: true)
        let window = try host(page)
        defer {
            page.stop()
            window.isHidden = true
        }
        page.layoutIfNeeded()
        let clock = try #require(page.subviews.first as? ClockRenderView)
        try await waitForFrame(clock, after: 0)
        update(scrolling: true, visible: true)
        update(scrolling: true, visible: false)
        update(scrolling: false, visible: false)
        try await Task.sleep(for: .milliseconds(200))
        let suspendedFrames = clock.renderedFrameCount
        try await Task.sleep(for: .milliseconds(200))
        #expect(clock.renderedFrameCount == suspendedFrames)

        update(scrolling: true, visible: true)
        update(scrolling: false, visible: true)
        #expect(page.subviews.first === clock)
        #expect(clock.isReady)
        clock.entranceAngles = [0.2, 0]
        try await waitForFrame(clock, after: suspendedFrames)
    }

    @Test func scrollingDuringFirstFrameDoesNotLeaveClockHidden() async throws {
        let page = ClockPageView(theme: .white, scene: .numbers)
        func update(scrolling: Bool) {
            page.update(date: .now, theme: .white, insets: .zero,
                        isScrolling: scrolling, isVisible: true,
                        isEditingAppearance: false, weekdayFrame: .zero, allowsFlybys: false)
        }
        update(scrolling: true)
        let window = try host(page)
        defer {
            page.stop()
            window.isHidden = true
        }
        let clock = try #require(page.subviews.first as? ClockRenderView)
        try await waitForFrame(clock, after: 0)
        update(scrolling: false)
        let timeout = ContinuousClock.now.advanced(by: .seconds(2))
        while clock.alpha < 1 && ContinuousClock.now < timeout {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(clock.alpha == 1, "The clock must reveal after an interrupted opening")
    }

    private func host(_ view: UIView) throws -> UIWindow {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        let controller = UIViewController()
        window.rootViewController = controller
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
        controller.view.addSubview(view)
        window.isHidden = false
        view.layoutIfNeeded()
        return window
    }

    private func waitForFrame(_ clock: ClockRenderView, after count: Int) async throws {
        let timeout = ContinuousClock.now.advanced(by: .seconds(10))
        while clock.renderedFrameCount <= count && ContinuousClock.now < timeout {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(clock.renderedFrameCount > count, "The clock must present a fresh frame")
    }
}
