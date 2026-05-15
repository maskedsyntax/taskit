import Foundation
import EventKit
import SwiftData

class RemindersManager {
    static let shared = RemindersManager()
    private let eventStore = EKEventStore()
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestFullAccessToReminders { success, error in
            completion(success)
        }
    }
    
    func syncTaskToReminders(_ task: Task) {
        requestAccess { granted in
            guard granted else { return }
            
            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = task.title
            reminder.notes = task.taskDescription
            reminder.isCompleted = task.isCompleted
            reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            
            if let dueDate = task.dueDate {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
                let alarm = EKAlarm(absoluteDate: dueDate)
                reminder.addAlarm(alarm)
            }
            
            switch task.priority {
            case 1: reminder.priority = 9 // Low
            case 2: reminder.priority = 5 // Medium
            case 3: reminder.priority = 1 // High
            default: reminder.priority = 0
            }
            
            do {
                try self.eventStore.save(reminder, commit: true)
                print("Task synced to Reminders successfully")
            } catch {
                print("Failed to save reminder: \(error.localizedDescription)")
            }
        }
    }
}
