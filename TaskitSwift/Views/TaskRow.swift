import SwiftUI

struct TaskRow: View {
    @Bindable var task: Task
    @State private var showingEdit = false

    var body: some View {
        HStack {
            Toggle("", isOn: $task.isCompleted)
                .toggleStyle(.taskitCheckbox)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
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
        .sheet(isPresented: $showingEdit) {
            TaskEditView(task: task)
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
}

// Checkbox toggle style for Universal support
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(configuration.isOn ? .blue : .secondary)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var taskitCheckbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}
