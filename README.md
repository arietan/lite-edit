# LiteEdit

A lightweight, fast code editor for macOS — built entirely with Swift and AppKit. No Electron, no web views, no bloat.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Features

- **Syntax highlighting** for 20+ languages (Swift, Python, JS/TS, Rust, Go, C/C++, Java, HTML, CSS, JSON, YAML, SQL, and more)
- **Tabbed editing** with Cmd+W to close, Cmd+click for new tab
- **Sidebar file explorer** with folder tree navigation
- **Find & Replace** with regex support and match count
- **Quick Open** (Cmd+P) for fast file switching
- **Session persistence** — reopens your folder, files, cursor positions, and window state on relaunch
- **Line numbers** with current-line highlighting
- **Status bar** showing cursor position and detected language

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+N | New file |
| Cmd+O | Open file |
| Cmd+Shift+O | Open folder |
| Cmd+S | Save |
| Cmd+Shift+S | Save as |
| Cmd+W | Close tab |
| Cmd+F | Find & Replace |
| Cmd+G | Go to line |
| Cmd+P | Quick Open |
| Cmd+B | Toggle sidebar |
| Option+Up/Down | Move line up/down |
| Cmd+Shift+K | Delete current line |
| Cmd+Shift+L | Select all occurrences (multi-cursor edit) |

## Build

Requires **Xcode Command Line Tools** and **macOS 13+**.

```bash
# Build and package the .app bundle
bash build.sh

# Run directly
open LiteEdit.app

# Or install to /Applications
cp -r LiteEdit.app /Applications/
```

## Project Structure

```
lite-edit/
├── Package.swift
├── build.sh
├── Sources/LiteEdit/
│   ├── main.swift                          # App entry point
│   ├── AppDelegate.swift                   # Menu bar, app lifecycle
│   ├── MainWindowController.swift          # Window, tabs, session persistence
│   ├── EditorViewController.swift          # Text view, find/replace, cursor
│   ├── EditorViewController+Shortcuts.swift # Line move, delete, multi-edit
│   ├── SidebarViewController.swift         # File tree explorer
│   ├── SyntaxHighlighter.swift             # Regex-based highlighting
│   ├── Document.swift                      # File model
│   ├── TabBarView.swift                    # Tab strip
│   ├── FindBarView.swift                   # Find/replace bar
│   ├── StatusBarView.swift                 # Bottom status bar
│   ├── LineNumberView.swift                # Gutter with line numbers
│   ├── QuickOpenPanel.swift                # Cmd+P fuzzy file picker
│   ├── RecentItems.swift                   # Recent files/folders
│   └── Theme.swift                         # Colors and fonts
└── .gitignore
```

## License

[MIT](LICENSE)
