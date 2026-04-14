# Project Memory

## Current State
Native macOS code editor (~3,000 lines Swift/AppKit). Single binary under 1 MB. Builds with `swift build`. Main branch, tagged v1.0.0.

## Recent Changes
- 2026-04-14: Tab-switch cursor reset fix — cursor jumped to line 1 when switching tabs because `replaceTextStorage()` triggers a deferred layout pass that resets NSTextView's selection *after* the synchronous `restoreCursorPosition()`. Fixed by adding `deferredRestoreCursor()` which dispatches restoration to the next run-loop iteration (matching the existing pattern in `restoreSession()`). Applied to `tabBarDidSelectTab`, `openFile`, `openFileInCurrentTab`, and `closeCurrentTab`.
- 2026-04-13: Tab indent/unindent — Tab with multi-line selection now indents all selected lines instead of deleting them. Shift+Tab unindents (removes one tab or up to 4 leading spaces). Handled in `EditorViewController+Shortcuts.swift` via keyCode 48 in `handleShortcutEvent`.
- 2026-04-13: Markdown highlighting fix — rewrote rules to fix bold/italic overlap (italic regex `\*text\*` was matching inside `**bold**`). Added negative lookaround on italic patterns, reordered rules so bold overrides italic. Added blockquotes, horizontal rules, ordered lists, underscore-based bold/italic, and image links.
- 2026-04-13: Tab-switch performance overhaul — three optimizations: (1) TabBarView uses smart diffing (`setTabs`/`selectTab`/`updateTab`) to avoid tearing down/rebuilding all subviews on every switch and keystroke; (2) SyntaxHighlighter instances cached per language (static dict) to avoid regex recompilation; (3) NSTextStorage cached per Document so switching to a previously-viewed tab swaps pre-highlighted storage via `layoutManager.replaceTextStorage()` instead of re-setting text + rehighlighting. Also fixed double-modified-indicator bug (● and • both shown).
- 2026-04-09: Landing page enhancements for awesome-mac traffic: added social proof badges (GitHub stars, awesome-mac featured, downloads, MIT), hero install command (`brew install --cask lite-edit`) with copy-to-clipboard, and a dedicated 3-column Install section (Homebrew / DMG / build from source). All in `docs/index.html`.
- 2026-04-09: Added auto-indent on Enter — new line inherits leading whitespace (spaces/tabs) from the current line. Implemented via `textView(_:shouldChangeTextIn:replacementString:)` delegate in `EditorViewController.swift`.

## Architecture Decisions
- Pure AppKit + TextKit 1 (forced via `_ = textView.layoutManager`), no SwiftUI
- Global `NSEvent.addLocalMonitorForEvents` in `EditorShortcuts` handles shortcuts (Option+Up/Down, Cmd+Shift+K, Cmd+Shift+L)
- Multi-cursor edits bypass `didChangeText()` to avoid selection collapse from rehighlighting
- Auto-indent uses a `suppressAutoIndent` flag to prevent recursion when calling `insertText` from the delegate
- Tab switching uses NSTextStorage-per-document caching: each Document holds a `cachedTextStorage` that preserves text + highlighting attributes across tab switches. `loadDoc()` swaps via `layoutManager.replaceTextStorage()` for O(1) switches. Cursor/scroll restoration must be deferred (`DispatchQueue.main.async`) because `replaceTextStorage` invalidates layout asynchronously, resetting the selection.
- TabBarView exposes `setTabs(_:selectedIndex:)` (smart rebuild), `selectTab(at:)` (appearance only), `updateTab(at:item:)` (single tab label). Hot paths (tab click, keystroke) use targeted methods; structural changes (open/close tab) use `setTabs`.

## Known Issues & TODOs
- Auto-indent is whitespace-matching only; no smart indent (e.g. increase after `{`)
- Markdown multi-line constructs (fenced code blocks) lose highlighting when editing inside them (line-by-line rehighlight limitation; full rehighlight restores on tab switch)
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
