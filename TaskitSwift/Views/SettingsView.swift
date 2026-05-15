import SwiftUI

struct SettingsView: View {
    @AppStorage("accentColor") private var accentColorHex: String = "#007bff"
    @Environment(\.dismiss) private var dismiss
    
    let colors: [String] = [
        "#007bff", // Blue
        "#28a745", // Green
        "#dc3545", // Red
        "#ffc107", // Yellow
        "#6610f2", // Indigo
        "#6f42c1", // Purple
        "#e83e8c", // Pink
        "#fd7e14", // Orange
        "#20c997", // Teal
        "#17a2b8"  // Cyan
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: accentColorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    accentColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Accent Color", systemImage: "paintpalette")
                }
                
                Section {
                    Button("Reset to Default") {
                        accentColorHex = "#007bff"
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(macOS)
            .frame(minWidth: 400, minHeight: 400)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
