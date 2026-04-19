import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var priority: Int
    var dueDate: Date?
    var tags: String
    var attachments: String
    
    var project: Project?
    
    @Relationship(deleteRule: .cascade, inverse: \Task.parentTask)
    var subtasks: [Task]? = []
    
    var parentTask: Task?
    
    init(title: String, 
         taskDescription: String = "", 
         isCompleted: Bool = false, 
         priority: Int = 1, 
         dueDate: Date? = nil, 
         tags: String = "", 
         attachments: String = "") {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.attachments = attachments
        self.subtasks = []
    }
}
