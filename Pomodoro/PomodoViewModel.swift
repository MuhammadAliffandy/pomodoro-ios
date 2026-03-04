import SwiftUI
import Combine
import ActivityKit

// MARK: - ViewModel

class PomodoroViewModel: ObservableObject {
    @Published var config = PomodoroConfig()
    @Published var currentPhase: PomodoroPhase = .focus
    @Published var timeRemaining: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var currentPoints: Int = 0
    
    private var timer: AnyCancellable?
    let targetPointsForLongBreak = 4
    
    // Background tracking
    private var backgroundDate: Date?
    private var currentActivity: Activity<PomodoroAttributes>?
    
    init() {
        // Listen for background/foreground transitions to calculate elapsed time
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.backgroundDate = Date()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleForeground()
        }
        
        // Listen for interactive Live Activity intent
        NotificationCenter.default.addObserver(forName: .toggleTimerIntent, object: nil, queue: .main) { [weak self] _ in
            self?.toggleTimer()
        }
    }
    
    // Calculate progress for the circular bar (0.0 to 1.0)
    var progress: Double {
        let totalTime: Int
        switch currentPhase {
        case .focus: totalTime = config.focusMinutes * 60
        case .shortBreak: totalTime = config.shortBreakMinutes * 60
        case .longBreak: totalTime = config.longBreakMinutes * 60
        }
        guard totalTime > 0 else { return 0.0 }
        return Double(timeRemaining) / Double(totalTime)
    }
    
    var nextPhase: PomodoroPhase {
        if currentPhase == .focus {
            return (currentPoints + 1 >= targetPointsForLongBreak) ? .longBreak : .shortBreak
        } else {
            return .focus
        }
    }
    
    var nextPhaseDurationString: String {
        switch nextPhase {
        case .focus: return "\(config.focusMinutes) Minutes"
        case .shortBreak: return "\(config.shortBreakMinutes) Minutes"
        case .longBreak: return "\(config.longBreakMinutes) Minutes"
        }
    }
    
    var timeString: String {
        let minutes = max(timeRemaining / 60, 0)
        let seconds = max(timeRemaining % 60, 0)
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Controls
    
    func toggleTimer() {
        if isRunning { pauseTimer() } else { startTimer() }
    }
    
    private func startTimer() {
        isRunning = true
        timer?.cancel() // Prevent duplicate timers
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
        
        if currentActivity == nil {
            startLiveActivity()
        } else {
            updateLiveActivity()
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.cancel()
        updateLiveActivity()
    }
    
    func skipPhase() {
        // Bug Fix: Check if it was running before we skip.
        let wasRunning = isRunning
        handlePhaseCompletion()
        
        // If it was paused, keep it paused after skip. Otherwise, it autos-starts.
        if !wasRunning {
            pauseTimer()
        }
    }
    
    func resetCurrentPhase() {
        pauseTimer()
        setInitialTime(for: currentPhase)
        updateLiveActivity()
    }
    
    func endCycle() {
        pauseTimer()
        currentPoints = 0
        currentPhase = .focus
        setInitialTime(for: .focus)
        stopLiveActivity()
    }
    
    // MARK: - Internal Logic
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            handlePhaseCompletion()
        }
    }
    
    private func handlePhaseCompletion() {
        if currentPhase == .focus {
            currentPoints += 1
            if currentPoints >= targetPointsForLongBreak {
                currentPhase = .longBreak
            } else {
                currentPhase = .shortBreak
            }
        } else if currentPhase == .longBreak {
            currentPoints = 0
            currentPhase = .focus
        } else if currentPhase == .shortBreak {
            currentPhase = .focus
        }
        
        setInitialTime(for: currentPhase)
        
        // Bug Fix: Auto-continue the timer instead of stopping
        startTimer()
    }
    
    func setInitialTime(for phase: PomodoroPhase) {
        switch phase {
        case .focus: timeRemaining = config.focusMinutes * 60
        case .shortBreak: timeRemaining = config.shortBreakMinutes * 60
        case .longBreak: timeRemaining = config.longBreakMinutes * 60
        }
    }
    
    private func handleForeground() {
        guard let bgDate = backgroundDate, isRunning else { return }
        let elapsedSeconds = Int(Date().timeIntervalSince(bgDate))
        timeRemaining -= elapsedSeconds
        
        if timeRemaining <= 0 {
            // If time expired while in background, jump to next phase immediately
            timeRemaining = 0
            handlePhaseCompletion()
        }
        backgroundDate = nil
        updateLiveActivity()
    }
    
    // MARK: - Live Activity Management
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = PomodoroAttributes(phaseName: currentPhase.catchyTitle)
        let estimatedEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        let contentState = PomodoroAttributes.ContentState(
            isRunning: isRunning,
            endTime: estimatedEndTime,
            timeRemaining: timeRemaining
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = currentActivity else { return }
        
        let estimatedEndTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        let contentState = PomodoroAttributes.ContentState(
            isRunning: isRunning,
            endTime: estimatedEndTime,
            timeRemaining: timeRemaining
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    private func stopLiveActivity() {
            guard let activity = currentActivity else { return }
            
            let finalContentState = PomodoroAttributes.ContentState(
                isRunning: false,
                endTime: Date(),
                timeRemaining: timeRemaining
            )
            
            Task {
                // Updated for iOS 16.2+ API
                if #available(iOS 16.2, *) {
                    await activity.end(
                        ActivityContent(state: finalContentState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                } else {
                    // Fallback for older iOS 16 versions
                    await activity.end(dismissalPolicy: .immediate)
                }
                
                self.currentActivity = nil
            }
        }
}

// Custom Notification for App Intent
extension Notification.Name {
    static let toggleTimerIntent = Notification.Name("toggleTimerIntent")
}
