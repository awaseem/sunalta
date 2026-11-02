#if DEBUG
import SwiftUI

struct AlarmSessionPreview: View {
    @State private var data = Result { try AlarmSessionPreviewData() }

    var body: some View {
        switch data {
        case .success(let data):
            AlarmPreviewEnvironment(container: data.container,
                                    timeFormat: ProcessInfo.processInfo.arguments.contains("--preview-12-hour")
                                        ? .twelveHour : .twentyFourHour,
                                    content: AlarmRootView(observesAlarms: false).environment(data.runtime))
                .task {
                    await data.runtime.refresh()
                    let arguments = ProcessInfo.processInfo.arguments
                    if arguments.contains("--preview-snoozed") {
                        do { try await data.runtime.snooze(data.alarm) }
                        catch { data.runtime.errorMessage = error.localizedDescription }
                    }
                    if arguments.contains("--preview-alarm-island") { data.runtime.hideActiveAlarm() }
                }
                .task(id: data.alarm.snoozedUntil) {
                    guard let deadline = data.alarm.snoozedUntil else { return }
                    do { try await Task.sleep(for: .seconds(max(0, deadline.timeIntervalSinceNow))) }
                    catch { return }
                    guard data.alarm.pendingSince != nil else { return }
                    data.ringAgain()
                    await data.runtime.refresh()
                }
                .onOpenURL { url in
                    guard url.scheme == "sunalta", url.host == "alarm-preview" else { return }
                    Task {
                        do {
                            switch url.path {
                            case "/snooze": try await data.runtime.snooze(data.alarm)
                            case "/hide": data.runtime.hideActiveAlarm()
                            case "/show": data.runtime.presentActiveAlarm()
                            case "/ring":
                                data.ringAgain()
                                await data.runtime.refresh()
                            case "/stop": try await data.runtime.finish(data.alarm)
                            case "/scan": try await data.runtime.finish(data.alarm, code: "wake-up", kind: .qrCode)
                            default: break
                            }
                        } catch {
                            data.runtime.errorMessage = error.localizedDescription
                        }
                    }
                }
        case .failure(let error):
            ContentUnavailableView("Preview unavailable", systemImage: "exclamationmark.triangle",
                                   description: Text(error.localizedDescription))
        }
    }
}

#Preview("Interactive alarm session") { AlarmSessionPreview() }
#endif
