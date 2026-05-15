import Foundation
import SwiftData

@Model
final class Attachment: Identifiable {
    var id: UUID
    var fileName: String
    var fileType: String // MIME type or extension
    var fileURL: URL?
    
    var task: Task?
    
    init(fileName: String, fileType: String, fileURL: URL? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.fileURL = fileURL
    }
}
