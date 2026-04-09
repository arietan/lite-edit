# Project Memory

## Current State
Native macOS code editor (~3,000 lines Swift/AppKit). Single binary under 1 MB. Builds with `swift build`. Main branch, tagged v1.0.0.

## Recent Changes
- 2026-04-09: Landing page enhancements for awesome-mac traffic: added social proof badges (GitHub stars, awesome-mac featured, downloads, MIT), hero install command (`brew install --cask lite-edit`) with copy-to-clipboard, and a dedicated 3-column Install section (Homebrew / DMG / build from source). All in `docs/index.html`.
- 2026-04-09: Added auto-indent on Enter — new line inherits leading whitespace (spaces/tabs) from the current line. Implemented via `textView(_:shouldChangeTextIn:replacementString:)` delegate in `EditorViewController.swift`.

## Architecture Decisions
- Pure AppKit + TextKit 1 (forced via `_ = textView.layoutManager`), no SwiftUI
- Global `NSEvent.addLocalMonitorForEvents` in `EditorShortcuts` handles shortcuts (Option+Up/Down, Cmd+Shift+K, Cmd+Shift+L)
- Multi-cursor edits bypass `didChangeText()` to avoid selection collapse from rehighlighting
- Auto-indent uses a `suppressAutoIndent` flag to prevent recursion when calling `insertText` from the delegate

## Known Issues & TODOs
- Auto-indent is whitespace-matching only; no smart indent (e.g. increase after `{`)
- Landing page: merged into awesome-mac (101k+ stars); remaining enhancement ideas: animated demo GIF/video, real cold-start benchmarks, honest "Not for you if..." section, mobile hamburger nav, JSON-LD structured data

## Key Files & Patterns
- `Sources/LiteEdit/EditorViewController.swift` — main text view, delegate, find/replace, auto-indent
- `Sources/LiteEdit/EditorViewController+Shortcuts.swift` — line move, delete, multi-cursor edit
- `Sources/LiteEdit/SyntaxHighlighter.swift` — regex-based highlighting for 20+ languages
- `Sources/LiteEdit/MainWindowController.swift` — window, tabs, session persistence
- `Sources/LiteEdit/SidebarViewController.swift` — file tree explorer

## Environment & Setup
- Requires macOS 13+, Xcode Command Line Tools, Swift 5.9
- Build: `swift build` or `bash build.sh`
- Run: `open LiteEdit.app`
