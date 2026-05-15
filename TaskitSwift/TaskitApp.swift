import SwiftUI
import SwiftData

@main
struct TaskitApp: App {
    init() {
        #if os(macOS)
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
            Project.self,
            Tag.self,
            Attachment.self,
            TaskTemplate.self
        ])
        
        // Note: For CloudKit sync to work, all models must have optional or default values for all properties,
        // and relationships must be optional.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            container.mainContext.undoManager = UndoManager()
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
