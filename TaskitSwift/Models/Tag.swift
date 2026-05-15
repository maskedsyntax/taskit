import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String
    
    @Relationship(inverse: \Task.tagsList)
    var tasks: [Task]? = []
    
    init(name: String, colorHex: String = "#6c757d") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.tasks = []
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}
