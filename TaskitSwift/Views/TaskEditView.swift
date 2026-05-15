import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    
    @State private var recurrenceFrequency: RecurrenceFrequency = .none
    @State private var recurrenceEndDate: Date = Date().addingTimeInterval(86400 * 30)
    @State private var hasRecurrenceEnd: Bool = false
    
    @State private var newSubtaskTitle: String = ""
    @State private var pendingSubtasks: [String] = []
    @State private var selectedTags: Set<Tag> = []
    @State private var showingAddTag = false
    @State private var newTagName = ""
    
    @State private var showingFileImporter = false
    
    @State private var showingSaveTemplate = false
    @State private var templateName = ""
    
    @Query(sort: \Project.name) private var projects: [Project]
    @Query(sort: \Tag.name) private var allTags: [Tag]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.headline)
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $taskDescription)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
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
                    
                    Divider()
                    
                    Picker("Repeat", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    if recurrenceFrequency != .none {
                        Toggle("End Repeat", isOn: $hasRecurrenceEnd)
                        if hasRecurrenceEnd {
                            DatePicker("End Date", selection: $recurrenceEndDate, displayedComponents: .date)
                        }
                    }
                } header: {
                    Label("Details", systemImage: "list.bullet")
                        .font(.headline)
                }
                
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags) { tag in
                                TagView(tag: tag, isSelected: selectedTags.contains(tag))
                                    .onTapGesture {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }
                            }
                            
                            Button {
                                showingAddTag = true
                            } label: {
                                Label("New Tag", systemImage: "plus.circle")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("Tags", systemImage: "tag")
                        .font(.headline)
                }
                
                Section {
                    if let attachments = task?.attachmentsList, !attachments.isEmpty {
                        ForEach(attachments) { attachment in
                            HStack {
                                Image(systemName: fileIcon(for: attachment.fileType))
                                    .foregroundColor(.blue)
                                Text(attachment.fileName)
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    openAttachment(attachment)
                                } label: {
                                    Image(systemName: "eye")
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            if let task = task, let attachments = task.attachmentsList {
                                for index in indexSet {
                                    let attachmentToDelete = attachments[index]
                                    modelContext.delete(attachmentToDelete)
                                }
                            }
                        }
                    }
                    
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Add Attachment", systemImage: "paperclip")
                    }
                } header: {
                    Label("Attachments", systemImage: "paperclip")
                        .font(.headline)
                }
                
                Section {
                    if let existingSubtasks = task?.subtasks, !existingSubtasks.isEmpty {
                        let sortedSubtasks = existingSubtasks.sorted(by: { $0.title < $1.title })
                        ForEach(sortedSubtasks) { subtask in
                            EditableSubtaskRow(subtask: subtask)
                        }
                        .onDelete { indexSet in
                            if let task = task {
                                let sorted = task.subtasks?.sorted(by: { $0.title < $1.title }) ?? []
                                for index in indexSet {
                                    let subtaskToDelete = sorted[index]
                                    if let idx = task.subtasks?.firstIndex(where: { $0.id == subtaskToDelete.id }) {
                                        task.subtasks?.remove(at: idx)
                                        modelContext.delete(subtaskToDelete)
                                    }
                                }
                            }
                        }
                    }
                    
                    ForEach(pendingSubtasks, id: \.self) { pending in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                            Text(pending)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        pendingSubtasks.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                        TextField("Add a subtask...", text: $newSubtaskTitle)
                            .onSubmit {
                                addPendingSubtask()
                            }
                        if !newSubtaskTitle.isEmpty {
                            Button {
                                addPendingSubtask()
                            } label: {
                                Text("Add")
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Label("Subtasks", systemImage: "list.bullet.indent")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 700)
            #endif
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingSaveTemplate = true
                    } label: {
                        Label("Save as Template", systemImage: "doc.on.doc")
                    }
                    .help("Save current details as a template")
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
                    selectedTags = Set(task.tagsList ?? [])
                    recurrenceFrequency = task.recurrenceFrequency
                    if let end = task.recurrenceEndDate {
                        recurrenceEndDate = end
                        hasRecurrenceEnd = true
                    }
                } else if let project = initialProject {
                    selectedProject = project
                }
            }
            .alert("Save as Template", isPresented: $showingSaveTemplate) {
                TextField("Template Name", text: $templateName)
                Button("Cancel", role: .cancel) {
                    templateName = ""
                }
                Button("Save") {
                    saveTemplate()
                }
                .disabled(templateName.isEmpty)
            } message: {
                Text("Enter a name for this template.")
            }
            .alert("New Tag", isPresented: $showingAddTag) {
                TextField("Tag Name", text: $newTagName)
                Button("Cancel", role: .cancel) {
                    newTagName = ""
                }
                Button("Add") {
                    addNewTag()
                }
                .disabled(newTagName.isEmpty)
            } message: {
                Text("Enter a name for the new tag.")
            }
            .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.item]) { result in
                handleFileImport(result: result)
            }
        }
    }
    
    private func saveTemplate() {
        let tagNames = selectedTags.map { $0.name }
        let template = TaskTemplate(
            name: templateName,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            tagNames: tagNames
        )
        modelContext.insert(template)
        templateName = ""
    }

    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let fileName = url.lastPathComponent
            let fileType = url.pathExtension
            
            if let task = task {
                let attachment = Attachment(fileName: fileName, fileType: fileType, fileURL: url)
                attachment.task = task
                if task.attachmentsList == nil {
                    task.attachmentsList = []
                }
                task.attachmentsList?.append(attachment)
                modelContext.insert(attachment)
            }
        case .failure(let error):
            print("File import failed: \(error.localizedDescription)")
        }
    }

    private func fileIcon(for type: String) -> String {
        switch type.lowercased() {
        case "pdf": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif": return "photo"
        case "txt", "md": return "doc.text"
        default: return "doc"
        }
    }

    private func openAttachment(_ attachment: Attachment) {
        if let url = attachment.fileURL {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
        }
    }

    private func addNewTag() {
        let tag = Tag(name: newTagName)
        modelContext.insert(tag)
        selectedTags.insert(tag)
        newTagName = ""
    }

    private func addPendingSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            pendingSubtasks.append(trimmed)
            newSubtaskTitle = ""
        }
    }

    private func save() {
        if let task = task {
            task.title = title
            task.taskDescription = taskDescription
            task.priority = priority
            task.dueDate = hasDueDate ? dueDate : nil
            task.project = selectedProject
            task.tagsList = Array(selectedTags)
            task.recurrenceFrequency = recurrenceFrequency
            task.recurrenceEndDate = hasRecurrenceEnd ? recurrenceEndDate : nil
            
            for subTitle in pendingSubtasks {
                let subtask = Task(title: subTitle)
                subtask.parentTask = task
                if task.subtasks == nil {
                    task.subtasks = []
                }
                task.subtasks?.append(subtask)
                modelContext.insert(subtask)
            }
        } else {
            let newTask = Task(
                title: title,
                taskDescription: taskDescription,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                recurrenceFrequency: recurrenceFrequency,
                recurrenceEndDate: hasRecurrenceEnd ? recurrenceEndDate : nil
            )
            newTask.project = selectedProject
            newTask.tagsList = Array(selectedTags)
            
            for subTitle in pendingSubtasks {
                let subtask = Task(title: subTitle)
                subtask.parentTask = newTask
                if newTask.subtasks == nil {
                    newTask.subtasks = []
                }
                newTask.subtasks?.append(subtask)
                modelContext.insert(subtask)
            }
            
            modelContext.insert(newTask)
        }
    }
}

struct EditableSubtaskRow: View {
    @Bindable var subtask: Task
    
    var body: some View {
        HStack {
            Toggle("", isOn: $subtask.isCompleted)
                .toggleStyle(.taskitCheckboxSmall)
            
            TextField("Subtask Title", text: $subtask.title)
                .strikethrough(subtask.isCompleted)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
        }
    }
}

struct TagView: View {
    let tag: Tag
    let isSelected: Bool
    
    var body: some View {
        Text(tag.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? tag.color : tag.color.opacity(0.1))
            .foregroundColor(isSelected ? .white : tag.color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tag.color, lineWidth: 1)
            )
    }
}
