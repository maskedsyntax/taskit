import Foundation
import SwiftData

struct RecurrenceManager {
    static func handleTaskCompletion(_ task: Task, context: ModelContext) {
        guard task.isCompleted, task.recurrenceFrequency != .none else { return }
        
        // Calculate next due date
        guard let currentDueDate = task.dueDate else { return }
        
        let calendar = Calendar.current
        var nextDueDate: Date?
        
        switch task.recurrenceFrequency {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: 1, to: currentDueDate)
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDueDate)
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: currentDueDate)
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: currentDueDate)
        case .none:
            break
        }
        
        guard let nextDate = nextDueDate else { return }
        
        // Check if next date is beyond recurrence end date
        if let endDate = task.recurrenceEndDate, nextDate > endDate {
            return
        }
        
        // Create new task
        let newTask = Task(
            title: task.title,
            taskDescription: task.taskDescription,
            priority: task.priority,
            dueDate: nextDate,
            recurrenceFrequency: task.recurrenceFrequency,
            recurrenceEndDate: task.recurrenceEndDate
        )
        
        newTask.project = task.project
        newTask.tagsList = task.tagsList
        
        // Note: We don't necessarily want to copy subtasks as completed, 
        // but maybe we want to copy them as incomplete? 
        // Usually, recurring tasks are "templates".
        if let subtasks = task.subtasks {
            for sub in subtasks {
                let newSub = Task(title: sub.title)
                newSub.parentTask = newTask
                newTask.subtasks?.append(newSub)
                context.insert(newSub)
            }
        }
        
        context.insert(newTask)
    }
}
