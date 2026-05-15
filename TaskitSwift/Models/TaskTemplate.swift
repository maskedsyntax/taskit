import Foundation
import SwiftData

@Model
final class TaskTemplate: Identifiable {
    var id: UUID
    var name: String
    var title: String
    var taskDescription: String
    var priority: Int
    
    // Store tag names as templates might exist without the actual Tag objects being linked yet
    // or to keep it simple.
    var tagNames: [String] = []
    
    init(name: String, title: String, taskDescription: String = "", priority: Int = 1, tagNames: [String] = []) {
        self.id = UUID()
        self.name = name
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.tagNames = tagNames
    }
}
