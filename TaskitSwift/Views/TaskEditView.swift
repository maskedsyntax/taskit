import SwiftUI
import SwiftData

struct TaskEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var task: Task?
    var initialProject: Project?
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var priority: Int = 1
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var selectedProject: Project?
    
    @Query(sort: \Project.name) private var projects: [Project]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Description", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...10)
                } header: {
                    Label("Basic Information", systemImage: "info.circle")
                        .font(.headline)
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        Label("Low", systemImage: "arrow.down").tag(1)
                        Label("Medium", systemImage: "arrow.right").tag(2)
                        Label("High", systemImage: "arrow.up").tag(3)
                    }
                    
                    Toggle("Has Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Picker("Project", selection: $selectedProject) {
                        Text("None").tag(nil as Project?)
                        ForEach(projects) { project in
                            Label(project.name, systemImage: "folder.fill")
                                .foregroundColor(project.color)
                                .tag(project as Project?)
                        }
                    }
                } header: {
                    Label("Details", systemImage: "list.bullet")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 500)
            #endif
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let task = task {
                    title = task.title
                    taskDescription = task.taskDescription
                    priority = task.priority
                    if let date = task.dueDate {
                        dueDate = date
                        hasDueDate = true
                    }
                    selectedProject = task.project
                } else if let project = initialProject {
                    selectedProject = project
                }
            }
        }
    }

    private func save() {
        if let task = task {
            task.title = title
            task.taskDescription = taskDescription
            task.priority = priority
            task.dueDate = hasDueDate ? dueDate : nil
            task.project = selectedProject
        } else {
            let newTask = Task(
                title: title,
                taskDescription: taskDescription,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil
            )
            newTask.project = selectedProject
            modelContext.insert(newTask)
        }
    }
}
