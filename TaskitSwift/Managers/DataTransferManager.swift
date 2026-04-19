import Foundation
import SwiftData

struct TaskExport: Codable {
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Int
    var dueDate: Date?
    var tags: String
    var attachments: String
}

class DataTransferManager {
    static func exportToJSON(tasks: [Task]) -> Data? {
        let exports = tasks.map { TaskExport(
            title: $0.title,
            description: $0.taskDescription,
            isCompleted: $0.isCompleted,
            priority: $0.priority,
            dueDate: $0.dueDate,
            tags: $0.tags,
            attachments: $0.attachments
        )}
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        return try? encoder.encode(exports)
    }
    
    static func exportToICal(tasks: [Task]) -> String {
        var ical = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Taskit//Task Manager//EN\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        for task in tasks {
            guard let dueDate = task.dueDate else { continue }
            ical += "BEGIN:VTODO\n"
            ical += "UID:\(task.id.uuidString)@taskit\n"
            ical += "SUMMARY:\(task.title)\n"
            if !task.taskDescription.isEmpty {
                ical += "DESCRIPTION:\(task.taskDescription)\n"
            }
            if task.isCompleted {
                ical += "STATUS:COMPLETED\n"
            }
            ical += "DUE:\(formatter.string(from: dueDate))\n"
            ical += "END:VTODO\n"
        }
        
        ical += "END:VCALENDAR"
        return ical
    }
}
