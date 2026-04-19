import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias NativeColor = NSColor
#endif

struct ProjectEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var project: Project?
    
    @State private var name: String = ""
    @State private var color: Color = .blue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                    ColorPicker("Color", selection: $color)
                } header: {
                    Label("Project Settings", systemImage: "folder.fill")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            #if os(macOS)
            .frame(minWidth: 400, minHeight: 250)
            #endif
            .navigationTitle(project == nil ? "New Project" : "Edit Project")
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
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let project = project {
                    name = project.name
                    color = project.color
                }
            }
        }
    }

    private func save() {
        let hex = colorToHex(color)
        if let project = project {
            project.name = name
            project.colorHex = hex
        } else {
            let newProject = Project(name: name, colorHex: hex)
            modelContext.insert(newProject)
        }
    }

    private func colorToHex(_ color: Color) -> String {
        #if canImport(UIKit)
        let native = UIColor(color)
        #elseif canImport(AppKit)
        let native = NSColor(color)
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        #if canImport(UIKit)
        native.getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        native.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
