import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard
    @AppStorage("accentColor") private var accentColorHex: String = "#007bff"

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            if let selection = selection {
                switch selection {
                case .dashboard:
                    DashboardView()
                default:
                    TaskListView(selection: selection)
                }
            } else {
                Text("Select a filter or project")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(Color(hex: accentColorHex) ?? .blue)
    }
}
