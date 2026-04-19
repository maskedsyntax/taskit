import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem? = .all

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            if let selection = selection {
                TaskListView(selection: selection)
            } else {
                Text("Select a filter or project")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
