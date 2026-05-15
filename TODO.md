# Taskit TODO List

## Core Task Management Enhancements
- [x] **Subtasks UI:** Add expandable list or dedicated subtask section in `TaskEditView` and `TaskRow`.
- [x] **Proper Tagging System:** Implement a dedicated `Tag` model with colors and allow filtering by tags.
- [x] **Recurring Tasks:** Add support for repeating tasks (Daily, Weekly, Monthly) and logic to spawn new tasks.
- [x] **Attachments Support:** Improve attachments to support actual file URLs (images, PDFs) or links.

## UI & UX Refinement
- [x] **Rich Text Descriptions:** Use Markdown or a `TextEditor` with basic formatting support for descriptions.
- [x] **Drag and Drop:** Reorder tasks within a list and drag tasks to projects in the sidebar.
- [x] **Task Archiving:** Add an "Archive" feature to hide old completed tasks instead of deleting them.
- [x] **Keyboard Shortcuts:** Add support for common shortcuts (`Cmd+N`, `Cmd+F`).

## Productivity & Insights
- [x] **Focus Mode (Pomodoro):** Integrate a timer for specific tasks to aid focus.
- [x] **Dashboard & Statistics:** Create a view for productivity trends and charts.
- [x] **Reminders Sync:** Integrate with system `Reminders.app`.

## System Integration
- [ ] **Widgets:** Create Home & Lock Screen widgets for "Today's Tasks" or "Overdue Tasks".
- [ ] **App Shortcuts & Siri:** Support adding tasks via voice commands.
- [x] **iCloud Sync:** Ensure SwiftData is configured for CloudKit for cross-device sync.

## Customization
- [x] **Custom Themes:** Allow users to choose accent colors or background themes.
- [x] **Task Templates:** Allow saving frequently created tasks as templates.
