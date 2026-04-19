import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case all
    case today
    case scheduled
    case project(Project)
    
    var title: String {
        switch self {
        case .all: return "All Tasks"
        case .today: return "Today"
        case .scheduled: return "Scheduled"
        case .project(let project): return project.name
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .today: return "sun.max"
        case .scheduled: return "calendar"
        case .project: return "folder"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Query(sort: \Project.name) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddProject = false

    var body: some View {
        List(selection: $selection) {
            Section("Filters") {
                NavigationLink(value: SidebarItem.all) {
                    Label("All Tasks", systemImage: "tray.full")
                }
                NavigationLink(value: SidebarItem.today) {
                    Label("Today", systemImage: "sun.max")
                }
                NavigationLink(value: SidebarItem.scheduled) {
                    Label("Scheduled", systemImage: "calendar")
                }
            }
            
            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink(value: SidebarItem.project(project)) {
                        Label {
                            Text(project.name)
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(project.color)
                        }
                    }
                }
                .onDelete(perform: deleteProjects)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: { showingAddProject = true }) {
                    Label("Add Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            ProjectEditView()
        }
    }

    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
        }
    }
}
