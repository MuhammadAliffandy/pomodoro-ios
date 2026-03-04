import SwiftUI

// MARK: - Models

// Enum to represent the current phase of the Pomodoro cycle
enum PomodoroPhase: String {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    // Computed property for eye-catching titles and emojis
    var catchyTitle: String {
        switch self {
        case .focus: return "Deep Focus 🧠"
        case .shortBreak: return "Quick Relax ☕"
        case .longBreak: return "Long Rest 🛋️"
        }
    }
    
    // Computed property for motivational icons
    var iconName: String {
        switch self {
        case .focus: return "flame.fill"
        case .shortBreak: return "leaf.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
    
    // Theme color for each phase to be used in the progress bar
    var themeColor: Color {
        switch self {
        case .focus: return .black
        case .shortBreak: return .orange
        case .longBreak: return .green
        }
    }
    
    
    
}

// Model to store user preferences for timer durations
struct PomodoroConfig {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 30
}
