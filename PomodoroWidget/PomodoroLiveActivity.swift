import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents



// MARK: - Interactive Button Intent (iOS 17+)
//@available(iOS 17.0, *)
//struct ToggleTimerIntent: LiveActivityIntent {
//    static var title: LocalizedStringResource = "Toggle Pomodoro Timer"
//    
//    init() {}
//    
//    func perform() async throws -> some IntentResult {
//        // Broadcasts to the ViewModel using raw string to prevent concurrency warnings
//        NotificationCenter.default.post(name: NSNotification.Name("toggleTimerIntent"), object: nil)
//        return .result()
//    }
//}

// MARK: - Lock Screen Widget View
@main
struct PomodoroWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // Lock screen / Banner UI
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.phaseName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // Uses native Text timer format for perfect background syncing
                    if context.state.isRunning {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.title2.monospacedDigit())
                            .foregroundColor(.orange)
                    } else {
                        Text("\(context.state.timeRemaining / 60):\(String(format: "%02d", context.state.timeRemaining % 60))")
                            .font(.title2.monospacedDigit())
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Interactive Play/Pause Button
                if #available(iOS 17.0, *) {
                    Button(intent: ToggleTimerIntent()) {
                        Image(systemName: context.state.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(context.state.isRunning ? .red : .green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            // Basic Dynamic Island Configuration
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.phaseName).font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isRunning {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .multilineTextAlignment(.trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if #available(iOS 17.0, *) {
                        Button(intent: ToggleTimerIntent()) {
                            Label(context.state.isRunning ? "Pause" : "Resume", systemImage: context.state.isRunning ? "pause.fill" : "play.fill")
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                if context.state.isRunning {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .frame(maxWidth: 40)
                }
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
