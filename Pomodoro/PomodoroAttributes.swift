import ActivityKit
import Foundation
import AppIntents // <--- Added so we can use Intents here

// MARK: - Shared Attributes Data
public struct PomodoroAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isRunning: Bool
        public var endTime: Date
        public var timeRemaining: Int
        
        public init(isRunning: Bool, endTime: Date, timeRemaining: Int) {
            self.isRunning = isRunning
            self.endTime = endTime
            self.timeRemaining = timeRemaining
        }
    }
    
    public var phaseName: String
    
    public init(phaseName: String) {
        self.phaseName = phaseName
    }
}

// MARK: - Interactive Button Intent (iOS 17+)
// MARK: - Interactive Button Intent (iOS 17+)
@available(iOS 17.0, *)
public struct ToggleTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Toggle Pomodoro Timer"
    
    public init() {}
    
    // Add @MainActor right here! 👇
    @MainActor
    public func perform() async throws -> some IntentResult {
        // 1. Instantly update the Lock Screen widget UI for zero lag
        for activity in Activity<PomodoroAttributes>.activities {
            var state = activity.content.state
            let now = Date()
            
            if state.isRunning {
                // We are pausing: Calculate exactly how many seconds are left
                let left = Int(state.endTime.timeIntervalSince(now))
                state.timeRemaining = max(0, left)
                state.isRunning = false
            } else {
                // We are resuming: Push the end time into the future
                state.endTime = now.addingTimeInterval(TimeInterval(state.timeRemaining))
                state.isRunning = true
            }
            
            // Push the update to the Lock Screen immediately
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
        
        // 2. Alert the main app to sync its internal ViewModel in the background
        NotificationCenter.default.post(name: NSNotification.Name("toggleTimerIntent"), object: nil)
        
        return .result()
    }
}
