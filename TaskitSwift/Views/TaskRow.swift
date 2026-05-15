import SwiftUI

struct TaskRow: View {
    @Bindable var task: Task
    @State private var showingEdit = false
    @State private var isExpanded = false
    @State private var showingFocus = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Toggle("", isOn: $task.isCompleted)
                    .toggleStyle(.taskitCheckbox)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }

                    if let tags = task.tagsList, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(tags.sorted(by: { $0.name < $1.name })) { tag in
                                Text(tag.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(tag.color.opacity(0.1))
                                    .foregroundColor(tag.color)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.top, 2)
                    }

                    if task.recurrenceFrequency != .none {
                        HStack(spacing: 2) {
                            Image(systemName: "repeat")
                            Text(task.recurrenceFrequency.rawValue)
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                    }
                    
                    if !task.taskDescription.isEmpty {
                        Text(LocalizedStringKey(task.taskDescription))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }

                    if let attachments = task.attachmentsList, !attachments.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "paperclip")
                            Text("\(attachments.count)")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                    }
                }
                
                Spacer()
                
                if let subtasks = task.subtasks, !subtasks.isEmpty {
                    let completedCount = subtasks.filter { $0.isCompleted }.count
                    Button {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            Text("\(completedCount)/\(subtasks.count)")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                if task.priority == 2 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .help("Medium Priority")
                } else if task.priority == 3 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .help("High Priority")
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                showingEdit = true
            }
            
            if isExpanded, let subtasks = task.subtasks, !subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(subtasks.sorted(by: { $0.title < $1.title })) { subtask in
                        SubtaskRow(subtask: subtask)
                    }
                }
                .padding(.leading, 36)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .contextMenu {
            Button {
                showingFocus = true
            } label: {
                Label("Start Focus", systemImage: "timer")
            }
            
            Button {
                RemindersManager.shared.syncTaskToReminders(task)
            } label: {
                Label("Sync to Reminders", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Divider()

            Button(role: .destructive) {
                deleteTask()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEdit) {
            TaskEditView(task: task)
        }
        .sheet(isPresented: $showingFocus) {
            FocusView(task: task)
        }
        .onChange(of: task.isCompleted) { oldValue, newValue in
            if newValue {
                RecurrenceManager.handleTaskCompletion(task, context: modelContext)
            }
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteTask() {
        withAnimation {
            modelContext.delete(task)
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
}

struct SubtaskRow: View {
    @Bindable var subtask: Task
    
    var body: some View {
        HStack {
            Toggle("", isOn: $subtask.isCompleted)
                .toggleStyle(.taskitCheckboxSmall)
            
            Text(subtask.title)
                .font(.subheadline)
                .strikethrough(subtask.isCompleted)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
    }
}

// Checkbox toggle style for Universal support
struct CheckboxToggleStyle: ToggleStyle {
    var size: CGFloat = 20
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(configuration.isOn ? .blue : .secondary)
                .font(.system(size: size))
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var taskitCheckbox: CheckboxToggleStyle { CheckboxToggleStyle() }
    static var taskitCheckboxSmall: CheckboxToggleStyle { CheckboxToggleStyle(size: 16) }
}
