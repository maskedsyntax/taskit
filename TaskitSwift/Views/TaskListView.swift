import SwiftUI
import SwiftData

struct TaskListView: View {
    var selection: SidebarItem
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var showingAddTask = false
    
    // Search and Filter States
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedPriority = 0 // 0 = All, 1 = Low, 2 = Medium, 3 = High
    @State private var selectedStatus = 0 // 0 = All, 1 = Incomplete, 2 = Completed
    @State private var filterByDateRange = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var onlyOverdue = false
    @State private var selectedTags: Set<Tag> = []
    @State private var showArchived = false
    
    @FocusState private var isSearchFocused: Bool
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Query(sort: \TaskTemplate.name) private var templates: [TaskTemplate]

    init(selection: SidebarItem) {
        self.selection = selection
        
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!

        switch selection {
        case .all:
            _tasks = Query(filter: #Predicate<Task> { task in
                task.parentTask == nil
            }, sort: [SortDescriptor(\Task.order), SortDescriptor(\Task.dueDate)])
        case .today:
            _tasks = Query(filter: #Predicate<Task> { task in
                if let dueDate = task.dueDate {
                    return task.parentTask == nil && dueDate >= startOfToday && dueDate < endOfToday
                } else {
                    return false
                }
            }, sort: [SortDescriptor(\Task.order), SortDescriptor(\Task.dueDate)])
        case .scheduled:
            _tasks = Query(filter: #Predicate<Task> { task in
                task.parentTask == nil && task.dueDate != nil
            }, sort: [SortDescriptor(\Task.order), SortDescriptor(\Task.dueDate)])
        case .project(let project):
            let projectId = project.id
            _tasks = Query(filter: #Predicate<Task> { task in
                task.parentTask == nil && task.project?.id == projectId
            }, sort: [SortDescriptor(\Task.order), SortDescriptor(\Task.dueDate)])
        case .dashboard:
            _tasks = Query(filter: #Predicate<Task> { task in
                task.parentTask == nil
            })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showFilters {
                filterHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            List {
                ForEach(filteredTasks) { task in
                    TaskRow(task: task)
                        .draggable(task.id.uuidString)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(task)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                task.isArchived.toggle()
                            } label: {
                                Label(task.isArchived ? "Unarchive" : "Archive", systemImage: task.isArchived ? "archivebox.fill" : "archivebox")
                            }
                            .tint(.orange)
                        }
                }
                .onDelete(perform: deleteTasks)
                .onMove(perform: moveTasks)
            }
        }
        .navigationTitle(selection.title)
        .searchable(text: $searchText, isPresented: .constant(true), prompt: "Search tasks...")
        .focused($isSearchFocused)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button("Search") {
                        isSearchFocused = true
                    }
                    .keyboardShortcut("f", modifiers: .command)
                    .opacity(0)
                    .frame(width: 0, height: 0)

                    #if os(iOS)
                    EditButton()
                    #endif
                    
                    Button {
                        withAnimation {
                            showFilters.toggle()
                        }
                    } label: {
                        Label("Filter", systemImage: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    
                    Menu {
                        Button {
                            showingAddTask = true
                        } label: {
                            Label("New Blank Task", systemImage: "plus")
                        }
                        
                        if !templates.isEmpty {
                            Menu("From Template") {
                                ForEach(templates) { template in
                                    Button(template.name) {
                                        createTask(from: template)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    } primaryAction: {
                        showingAddTask = true
                    }
                    .keyboardShortcut("n", modifiers: .command)
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

    private var filteredTasks: [Task] {
        tasks.filter { task in
            // Archiving
            if !showArchived && task.isArchived { return false }
            if showArchived && !task.isArchived { return false }
            
            // Search Text
            let matchesSearch = searchText.isEmpty ||
                                task.title.localizedCaseInsensitiveContains(searchText) ||
                                task.taskDescription.localizedCaseInsensitiveContains(searchText)
            
            // Priority
            let matchesPriority = selectedPriority == 0 || task.priority == selectedPriority
            
            // Status
            let matchesStatus: Bool
            if selectedStatus == 1 {
                matchesStatus = !task.isCompleted
            } else if selectedStatus == 2 {
                matchesStatus = task.isCompleted
            } else {
                matchesStatus = true
            }
            
            // Overdue
            let matchesOverdue: Bool
            if onlyOverdue {
                if let dueDate = task.dueDate {
                    matchesOverdue = !task.isCompleted && dueDate < Date()
                } else {
                    matchesOverdue = false
                }
            } else {
                matchesOverdue = true
            }
            
            // Date Range
            let matchesDateRange: Bool
            if filterByDateRange {
                if let dueDate = task.dueDate {
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: startDate)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
                    matchesDateRange = dueDate >= startOfDay && dueDate < endOfDay
                } else {
                    matchesDateRange = false
                }
            } else {
                matchesDateRange = true
            }
            
            // Tags
            let matchesTags: Bool
            if selectedTags.isEmpty {
                matchesTags = true
            } else {
                let taskTags = Set(task.tagsList ?? [])
                matchesTags = !selectedTags.isDisjoint(with: taskTags)
            }
            
            return matchesSearch && matchesPriority && matchesStatus && matchesOverdue && matchesDateRange && matchesTags
        }
    }

    private var filterHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Priority", selection: $selectedPriority) {
                    Text("All Priorities").tag(0)
                    Text("Low").tag(1)
                    Text("Medium").tag(2)
                    Text("High").tag(3)
                }
                .pickerStyle(.menu)
                
                Picker("Status", selection: $selectedStatus) {
                    Text("All Status").tag(0)
                    Text("Incomplete").tag(1)
                    Text("Completed").tag(2)
                }
                .pickerStyle(.menu)
                
                Toggle("Overdue Only", isOn: $onlyOverdue)
                    .toggleStyle(.switch)
                
                Toggle("Archived", isOn: $showArchived)
                    .toggleStyle(.switch)
            }
            
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Text("Tags:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(allTags) { tag in
                            TagFilterView(tag: tag, isSelected: selectedTags.contains(tag))
                                .onTapGesture {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                        }
                    }
                }
            }
            
            HStack {
                Toggle("Date Range", isOn: $filterByDateRange)
                    .toggleStyle(.switch)
                
                if filterByDateRange {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                    Text("to")
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredTasks[index])
            }
        }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var revisedItems = filteredTasks
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].order = reverseIndex
        }
    }
    
    private func createTask(from template: TaskTemplate) {
        let newTask = Task(
            title: template.title,
            taskDescription: template.taskDescription,
            priority: template.priority
        )
        newTask.project = projectFromSelection
        
        // Handle tags from template
        // We need to fetch existing tags or create new ones if they don't exist
        // For simplicity, let's just use existing tags that match the names
        let allExistingTags = (try? modelContext.fetch(FetchDescriptor<Tag>())) ?? []
        let matchedTags = allExistingTags.filter { template.tagNames.contains($0.name) }
        newTask.tagsList = matchedTags
        
        modelContext.insert(newTask)
    }
}

struct TagFilterView: View {
    let tag: Tag
    let isSelected: Bool
    
    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? tag.color : tag.color.opacity(0.1))
            .foregroundColor(isSelected ? .white : tag.color)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tag.color, lineWidth: 1)
            )
    }
}
