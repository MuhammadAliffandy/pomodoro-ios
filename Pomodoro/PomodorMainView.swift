import SwiftUI

// MARK: - Main View

struct PomodoroMainView: View {
    @StateObject private var viewModel = PomodoroViewModel()
    @State private var showSettings = false
    @State private var showInfo = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    
                    // Top Section: Dot Indicators & Dynamic Catchy Title
                    VStack(spacing: 12) {
                        // 4 Dots for Session Indicator
                        HStack(spacing: 10) {
                            ForEach(0..<viewModel.targetPointsForLongBreak, id: \.self) { index in
                                Circle()
                                    .fill(index < viewModel.currentPoints ? viewModel.currentPhase.themeColor : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        
                        // Dynamic Title with Icon
                        HStack {
                            Image(systemName: viewModel.currentPhase.iconName)
                            Text(viewModel.currentPhase.catchyTitle)
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    }
                    .padding(.top, 20)
                    
                    // Circular Timer Display
                    ZStack {
                        // Background track circle
                        Circle()
                            .stroke(lineWidth: 15)
                            .opacity(0.1)
                            .foregroundColor(.gray)
                        
                        // Foreground progress circle
                        Circle()
                            .trim(from: 0.0, to: CGFloat(viewModel.progress))
                            .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                            .foregroundColor(viewModel.currentPhase.themeColor)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: viewModel.progress)
                        
                        // Time Text inside the circle
                        Text(viewModel.timeString)
                            .font(.system(size: 60, weight: .light, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    .frame(width: 260, height: 260)
                    .padding(.vertical, 20)
                    
                    // 2x2 Grid Buttons (Smaller size)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        
                        ControlButton(title: "Reset", icon: "restart", color: .black) { viewModel.resetCurrentPhase() }
                        
                        ControlButton(
                            title: viewModel.isRunning ? "Pause" : "Start",
                            icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                            color: viewModel.currentPhase.themeColor
                        ) { viewModel.toggleTimer() }
                        
                        ControlButton(title: "Skip", icon: "forward.end.fill", color: .black) { viewModel.skipPhase() }
             
                        ControlButton(title: "End", icon: "stop.fill", color: .red  ) { viewModel.endCycle() }
                    }
                    .padding(.horizontal, 40)
                    
                    // Up Next Section
                    VStack(spacing: 5) {
                        Text("UP NEXT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .tracking(2)
                        
                        Text(viewModel.nextPhase.rawValue)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(viewModel.nextPhaseDurationString)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle").foregroundColor(.black)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape").foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView(viewModel: viewModel) }
            .sheet(isPresented: $showInfo) { InfoView() }
        }
        // Use light mode explicitly since background is white
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Helper Views

// Smaller custom button
struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            // Reduced padding for smaller buttons
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings View (Dynamic Wheel Picker)

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: PomodoroViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Focus Duration")) {
                    Picker("Minutes", selection: $viewModel.config.focusMinutes) {
                        ForEach(1...120, id: \.self) { min in Text("\(min) min").tag(min) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                
                Section(header: Text("Short Break Duration")) {
                    Picker("Minutes", selection: $viewModel.config.shortBreakMinutes) {
                        ForEach(1...60, id: \.self) { min in Text("\(min) min").tag(min) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                
                Section(header: Text("Long Break Duration")) {
                    Picker("Minutes", selection: $viewModel.config.longBreakMinutes) {
                        ForEach(1...60, id: \.self) { min in Text("\(min) min").tag(min) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
            .navigationTitle("Time Settings")
            .navigationBarItems(trailing: Button("Done") {
                viewModel.setInitialTime(for: viewModel.currentPhase)
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Info View (Remains unchanged logically, just light theme adapted)

struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                InfoRow(title: "Focus Time", description: "A period of uninterrupted work, usually 25 minutes.")
                InfoRow(title: "Short Break", description: "A short 5-minute rest after completing one focus session.")
                InfoRow(title: "Session / Point", description: "1 Point is earned when you complete 1 Focus session.")
                InfoRow(title: "Long Break", description: "A longer rest (e.g., 30 minutes) rewarded after completing 4 Focus sessions (1 Cycle).")
            }
            .navigationTitle("How it Works")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct InfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(description).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Main View") {
    PomodoroMainView()
}
