import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

@Model
final class Task {
    var id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var isArchived: Bool = false
    var priority: Int
    var dueDate: Date?
    var tags: String
    var attachments: String
    var order: Int = 0
    
    var recurrenceFrequency: RecurrenceFrequency = RecurrenceFrequency.none
    var recurrenceEndDate: Date?
    
    var project: Project?
    
    @Relationship(deleteRule: .cascade, inverse: \Task.parentTask)
    var subtasks: [Task]? = []
    
    var parentTask: Task?
    
    @Relationship(deleteRule: .nullify)
    var tagsList: [Tag]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \Attachment.task)
    var attachmentsList: [Attachment]? = []
    
    init(title: String, 
         taskDescription: String = "", 
         isCompleted: Bool = false, 
         isArchived: Bool = false,
         priority: Int = 1, 
         dueDate: Date? = nil, 
         tags: String = "", 
         attachments: String = "",
         recurrenceFrequency: RecurrenceFrequency = .none,
         recurrenceEndDate: Date? = nil,
         order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.attachments = attachments
        self.order = order
        self.recurrenceFrequency = recurrenceFrequency
        self.recurrenceEndDate = recurrenceEndDate
        self.subtasks = []
        self.tagsList = []
        self.attachmentsList = []
    }
}
