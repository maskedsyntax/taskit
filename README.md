<div align="center">
  <img src="data/icons/hicolor/256x256/apps/org.gnome.Taskit.png" width="128" height="128" />

  # Taskit

  Taskit is a lightweight, intuitive, and modern task management application designed for the GNOME desktop environment. Modeled after the GNOME Todo app, it provides a clean interface for organizing personal and professional tasks, projects, and deadlines.

  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![GTK 4](https://img.shields.io/badge/GTK-4-blue.svg)](https://www.gtk.org/)
  [![Libadwaita](https://img.shields.io/badge/Libadwaita-1-blue.svg)](https://gnome.pages.gitlab.gnome.org/libadwaita/)
</div>

---

## Features

- **Task Management**: Easily create, edit, and complete tasks with priority levels and tags.
- **Projects & Folders**: Organize tasks into color-coded project folders for better categorization.
- **Deadlines & Reminders**: Set precise deadlines and receive desktop notifications via `libnotify`.
- **Hierarchical Subtasks**: Break down complex tasks into smaller, manageable subtasks.
- **Modern UI**: Built with GTK 4 and Libadwaita for a native GNOME experience, supporting dark/light modes.
- **Persistence**: Powered by SQLite for efficient local data storage.

## Screenshots

*(Screenshots coming soon)*

## Dependencies

To build Taskit, you will need the following dependencies:

- `valac` (Vala compiler)
- `meson` and `ninja`
- `gtk4`
- `libadwaita-1`
- `granite-7`
- `sqlite3`
- `gee-0.8`
- `libnotify`

### On Fedora:

```bash
sudo dnf install vala meson ninja-build gtk4-devel libadwaita-devel granite7-devel sqlite-devel libgee-devel libnotify-devel
```

### On Ubuntu/Debian:

```bash
sudo apt install valac meson ninja-build libgtk-4-dev libadwaita-1-dev libgranite-7-dev libsqlite3-dev libgee-0.8-dev libnotify-dev
```

### On Arch Linux:

```bash
sudo pacman -S vala meson ninja gtk4 libadwaita granite7 sqlite3 libgee libnotify
```

## Building and Installation

Clone the repository and build using Meson:

```bash
git clone https://github.com/maskedsyntax/taskit.git
cd taskit
meson setup build
meson compile -C build
```

To install:

```bash
sudo meson install -C build
```

## Running

You can run the application directly from the build directory:

```bash
./build/src/taskit
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
