import SwiftUI
import SwiftData
import UserNotifications

struct FocusView: View {
    @Bindable var task: Task
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: TimeInterval = 25 * 60 // 25 minutes
    @State private var isActive = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding()
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Text(task.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining / (25 * 60)))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                Text(timeString(timeRemaining))
                    .font(.system(size: 80, weight: .thin, design: .monospaced))
            }
            .frame(width: 300, height: 300)
            
            HStack(spacing: 40) {
                Button {
                    isActive.toggle()
                } label: {
                    Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isActive ? .orange : .green)
                }
                .buttonStyle(.plain)
                
                Button {
                    isActive = false
                    timeRemaining = 25 * 60
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            requestNotificationPermission()
        }
        .onReceive(timer) { _ in
            guard isActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                isActive = false
                sendNotification()
            }
        }
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete"
        content.body = "Time to take a break from '\(task.title)'!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
