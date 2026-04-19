import SwiftUI
import SwiftData

struct TaskListView: View {
    var selection: SidebarItem
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var showingAddTask = false

    init(selection: SidebarItem) {
        self.selection = selection
        
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!

        switch selection {
        case .all:
            _tasks = Query(sort: \Task.dueDate)
        case .today:
            _tasks = Query(filter: #Predicate<Task> { task in
                if let dueDate = task.dueDate {
                    return dueDate >= startOfToday && dueDate < endOfToday
                } else {
                    return false
                }
            }, sort: \Task.dueDate)
        case .scheduled:
            _tasks = Query(filter: #Predicate<Task> { task in
                task.dueDate != nil
            }, sort: \Task.dueDate)
        case .project(let project):
            let projectId = project.id
            _tasks = Query(filter: #Predicate<Task> { task in
                task.project?.id == projectId
            }, sort: \Task.dueDate)
        }
    }

    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRow(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
        .navigationTitle(selection.title)
        .toolbar {
            ToolbarItem {
                Button(action: { showingAddTask = true }) {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            TaskEditView(initialProject: projectFromSelection)
        }
    }

    private var projectFromSelection: Project? {
        if case .project(let project) = selection {
            return project
        }
        return nil
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }
}
