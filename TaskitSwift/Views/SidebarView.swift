import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SidebarItem: Hashable {
    case dashboard
    case all
    case today
    case scheduled
    case project(Project)
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .all: return "All Tasks"
        case .today: return "Today"
        case .scheduled: return "Scheduled"
        case .project(let project): return project.name
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar"
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
    @Query private var allTasks: [Task]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddProject = false
    @State private var projectToEdit: Project?
    @State private var showingImporter = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section("Insights") {
                    NavigationLink(value: SidebarItem.dashboard) {
                        Label("Dashboard", systemImage: "chart.bar")
                    }
                }
                
                Section("Filters") {
                    NavigationLink(value: SidebarItem.all) {
                        Label("All Tasks", systemImage: "tray.full")
                    }
                    .dropDestination(for: String.self) { items, location in
                        handleTaskDrop(items: items, targetProject: nil)
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
                        .dropDestination(for: String.self) { items, location in
                            handleTaskDrop(items: items, targetProject: project)
                        }
                        .contextMenu {
                            Button {
                                projectToEdit = project
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                deleteProject(project)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteProjectsAtIndexSet)
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            HStack {
                Button(action: { showingAddProject = true }) {
                    Label("Add Project", systemImage: "plus.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button(action: { showingImporter = true }) {
                        Label("Import JSON...", systemImage: "square.and.arrow.down")
                    }
                    
                    ShareLink(item: exportData(), preview: SharePreview("Taskit Export", image: Image(systemName: "tray.and.arrow.up"))) {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("Import/Export", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            handleImport(result: result)
        }
        .sheet(isPresented: $showingAddProject) {
            ProjectEditView()
        }
        .sheet(item: $projectToEdit) { project in
            ProjectEditView(project: project)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private func handleTaskDrop(items: [String], targetProject: Project?) -> Bool {
        for idString in items {
            if let uuid = UUID(uuidString: idString),
               let task = allTasks.first(where: { $0.id == uuid }) {
                task.project = targetProject
            }
        }
        return true
    }

    private func deleteProject(_ project: Project) {
        withAnimation {
            if case .project(let selected) = selection, selected.id == project.id {
                selection = .all
            }
            modelContext.delete(project)
        }
    }

    private func deleteProjectsAtIndexSet(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                deleteProject(projects[index])
            }
        }
    }

    private func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url) {
                try? DataTransferManager.importFromJSON(data: data, context: modelContext)
            }
        case .failure(let error):
            print("Import failed: \(error.localizedDescription)")
        }
    }

    private func exportData() -> Data {
        DataTransferManager.exportAll(projects: projects, tasks: allTasks) ?? Data()
    }
}
