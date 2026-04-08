# LiteEdit

A lightweight, fast code editor for macOS — built entirely with Swift and AppKit. No Electron, no web views, no bloat.

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://arietan.github.io/lite-edit/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://arietan.github.io/lite-edit/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Download DMG](https://img.shields.io/github/v/release/arietan/lite-edit?label=Download&color=blue)](https://github.com/arietan/lite-edit/releases/latest)

**[Website](https://arietan.github.io/lite-edit/)** · **[Download](https://github.com/arietan/lite-edit/releases/latest)** · **[Source](https://github.com/arietan/lite-edit)**

## Why LiteEdit?

Most code editors today ship hundreds of megabytes of bundled runtimes, web engines, and frameworks before you even open a file. LiteEdit takes the opposite approach: a single native binary under 1 MB that launches instantly and uses minimal resources.

### Size Comparison

| Editor | App Size | RAM at Idle | Runtime |
|---|---|---|---|
| **LiteEdit** | **~728 KB** | **~20 MB** | Native (AppKit) |
| Sublime Text | ~42 MB | ~90–140 MB | Native (C++) |
| VS Code | ~400 MB | ~226+ MB | Electron (Chromium + Node.js) |

LiteEdit is **~550x smaller than VS Code** and **~60x smaller than Sublime Text**. The entire app — editor, syntax highlighter, file explorer, session persistence — compiles to a single **500 KB binary** from ~3,000 lines of Swift. Zero dependencies. Zero frameworks. Just `swift build`.

### What makes it different

- **Instant launch** — no runtime to bootstrap, opens in milliseconds
- **Native macOS citizen** — built on AppKit and TextKit, uses system text rendering, respects macOS conventions
- **Single binary** — no `node_modules`, no embedded Chromium, no support files
- **Session persistence** — remembers your folder, open tabs, cursor positions, and window state across restarts
- **Multi-cursor editing** — VS Code-style Cmd+Shift+L to rename across a file in one shot

LiteEdit is not trying to replace VS Code or Sublime Text. It's for when you want to open a project, read code, make quick edits, and move on — without waiting for a 400 MB Electron app to wake up.

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

## Install

Download the latest DMG from the [Releases page](https://github.com/arietan/lite-edit/releases/latest), open it, and drag LiteEdit to Applications.

## Build from Source

Requires **Xcode Command Line Tools** and **macOS 13+**.

```bash
# Build and package the .app bundle
bash build.sh

# Run directly
open LiteEdit.app

# Or install to /Applications
cp -r LiteEdit.app /Applications/

# Or create a DMG installer
bash create-dmg.sh
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
