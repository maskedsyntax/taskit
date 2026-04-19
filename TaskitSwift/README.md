<div align="center">
  <img src="AppIcon.png" width="128" height="128" />

  # Taskit

  Taskit is a modern, native task management application for the Apple ecosystem. Designed with simplicity and productivity in mind, it provides a clean, native interface for organizing your daily life across macOS and iOS.

  [![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
  [![SwiftUI](https://img.shields.io/badge/SwiftUI-Universal-blue.svg)](https://developer.apple.com/xcode/swiftui/)
  [![SwiftData](https://img.shields.io/badge/SwiftData-Persistence-red.svg)](https://developer.apple.com/xcode/swiftdata/)
  [![macOS](https://img.shields.io/badge/macOS-14.0+-black.svg)](https://www.apple.com/macos/)
  [![iOS](https://img.shields.io/badge/iOS-17.0+-black.svg)](https://www.apple.com/ios/)
</div>

---

## Features

- **Native Experience**: Built entirely with SwiftUI for a seamless, high-performance experience on macOS and iOS.
- **Smart Organization**: Categorize tasks into color-coded projects with a modern grouped interface.
- **Priority Management**: Quickly identify urgent work with distinct color-coded priority indicators and tooltips.
- **Deadlines & Reminders**: Native system notifications powered by `UserNotifications` to keep you on track.
- **Flexible Views**: Quick access filters for "Today", "Scheduled", and "All Tasks" in a native sidebar.
- **Universal Persistence**: Powered by SwiftData for reliable local storage and automatic UI updates.
- **Export/Import**: Full support for JSON and iCal formats to move your data freely.
- **Undo/Redo**: Deep integration with macOS undo/redo system for worry-free task management.

## Installation

### macOS
1. Build the application using the instructions below.
2. Drag the `Taskit.app` bundle to your `/Applications` folder.
3. Launch via Spotlight or Launchpad.

## Building from Source

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later (with Swift 5.10+)

### Using Swift Package Manager (CLI)
```bash
# Build the application
swift build -c release

# Package into a .app bundle (manual steps)
mkdir -p Taskit.app/Contents/MacOS
cp .build/release/TaskitSwift Taskit.app/Contents/MacOS/TaskitSwift
# (Ensure Info.plist and Resources are configured as per the project setup)
```

### Using Xcode
1. Open `Package.swift` in Xcode.
2. Select the **TaskitSwift** target and your Mac as the destination.
3. Press `Cmd + R` to Build and Run.

## License

This project is licensed under the MIT License - see the original LICENSE file for details.
