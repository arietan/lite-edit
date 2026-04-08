# Contributing to LiteEdit

Thanks for your interest in contributing. LiteEdit is a small, focused project — contributions that keep it small and focused are welcome.

## Principles

- **No third-party dependencies.** LiteEdit compiles with `swift build` alone — no SPM packages, no CocoaPods, no frameworks.
- **AppKit only.** No SwiftUI, no web views, no Electron.
- **Keep the binary small.** Every feature should justify its weight.

## Getting Started

1. Fork the repository and clone your fork:

   ```bash
   git clone https://github.com/<your-username>/lite-edit.git
   cd lite-edit
   git remote add upstream https://github.com/arietan/lite-edit.git
   ```

2. Build and run:

   ```bash
   bash build.sh
   open LiteEdit.app
   ```

   Requires Xcode Command Line Tools and macOS 13+.

## Making Changes

1. Create a branch from `main`:

   ```bash
   git checkout -b feature/your-change
   ```

2. Make your changes. Keep commits small and descriptive.

3. Verify the app builds and runs:

   ```bash
   bash build.sh
   open LiteEdit.app
   ```

4. Push to your fork and open a pull request against `main`.

## What to Contribute

- Bug fixes
- Performance improvements
- New syntax highlighting grammars
- Keyboard shortcut additions
- Accessibility improvements
- Documentation

## What to Avoid

- Adding third-party dependencies
- Large features that significantly increase binary size
- UI frameworks other than AppKit
- Changes that break macOS 13 compatibility

## Code Style

- Follow existing patterns in the codebase.
- Use `// MARK: -` to organize sections within files.
- Keep files focused — one responsibility per file.
- Prefer clarity over cleverness.

## Reporting Issues

Use the [GitHub issue tracker](https://github.com/arietan/lite-edit/issues). Please include:

- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Console output if relevant (`open LiteEdit.app` from Terminal to see logs)
