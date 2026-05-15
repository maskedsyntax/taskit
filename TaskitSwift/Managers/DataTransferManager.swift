import Foundation
import SwiftData

struct ProjectExport: Codable {
    var name: String
    var colorHex: String
}

struct TaskExport: Codable {
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Int
    var dueDate: Date?
    var tags: String
    var attachments: String
    var projectName: String?
}

struct AppExport: Codable {
    var projects: [ProjectExport]
    var tasks: [TaskExport]
}

class DataTransferManager {
    static func exportAll(projects: [Project], tasks: [Task]) -> Data? {
        let pExports = projects.map { ProjectExport(name: $0.name, colorHex: $0.colorHex) }
        let tExports = tasks.map { TaskExport(
            title: $0.title,
            description: $0.taskDescription,
            isCompleted: $0.isCompleted,
            priority: $0.priority,
            dueDate: $0.dueDate,
            tags: $0.tags,
            attachments: $0.attachments,
            projectName: $0.project?.name
        )}
        
        let appExport = AppExport(projects: pExports, tasks: tExports)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        return try? encoder.encode(appExport)
    }
    
    static func importFromJSON(data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let appExport = try decoder.decode(AppExport.self, from: data)
        
        // Fetch existing projects to avoid duplicates or to link correctly
        let projectDescriptor = FetchDescriptor<Project>()
        let existingProjects = try context.fetch(projectDescriptor)
        var projectMap = Dictionary(uniqueKeysWithValues: existingProjects.map { ($0.name, $0) })
        
        // Create missing projects
        for pExport in appExport.projects {
            if projectMap[pExport.name] == nil {
                let newProject = Project(name: pExport.name, colorHex: pExport.colorHex)
                context.insert(newProject)
                projectMap[pExport.name] = newProject
            }
        }
        
        // Import tasks
        for tExport in appExport.tasks {
            let task = Task(
                title: tExport.title,
                taskDescription: tExport.description,
                isCompleted: tExport.isCompleted,
                priority: tExport.priority,
                dueDate: tExport.dueDate,
                tags: tExport.tags,
                attachments: tExport.attachments
            )
            
            if let pName = tExport.projectName {
                task.project = projectMap[pName]
            }
            
            context.insert(task)
        }
        
        try context.save()
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
