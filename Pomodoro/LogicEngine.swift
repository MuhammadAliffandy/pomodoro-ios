import SwiftUI
import Combine

class PomodoroModel: ObservableObject {
    @Published var timeRemaining: Int = 1500 // 25 mins
    @Published var isRunning = false
    @Published var workDuration: Int = 25 {
        didSet { resetTimer() }
    }
    
    private var timer: AnyCancellable?
    
    func toggleTimer() {
        if isRunning {
            timer?.cancel()
        } else {
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    } else {
                        self.isRunning = false
                    }
                }
        }
        isRunning.toggle()
    }
    
    func resetTimer() {
        timer?.cancel()
        isRunning = false
        timeRemaining = workDuration * 60
    }
    
    func formatTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
