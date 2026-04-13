// EditorViewController+Shortcuts.swift
// STAGING — New keyboard shortcuts for the editor.
//
//   Option+Up/Down     Move current line (or selected lines) up / down
//   Cmd+Shift+K        Delete the current line
//   Cmd+Shift+L        Select all occurrences → enters multi-edit mode
//                      (type to replace all at once, Backspace works, Escape exits)
//
// Activation: call  EditorShortcuts.install()  once at app launch,
// e.g. at the top of AppDelegate.applicationDidFinishLaunching(_:).

import AppKit

// MARK: - Per-editor multi-edit state

private var multiEditActive:  [ObjectIdentifier: Bool] = [:]
private var multiEditCursors: [ObjectIdentifier: [NSRange]] = [:]

// MARK: - Global event monitors

enum EditorShortcuts {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let editor = activeEditor(for: event) else { return event }

            if multiEditActive[ObjectIdentifier(editor)] == true {
                return editor.handleMultiEditKey(event) ? nil : event
            }
            return editor.handleShortcutEvent(event) ? nil : event
        }

        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            for key in multiEditActive.keys { multiEditActive[key] = false }
            return event
        }
    }

    fileprivate static func activeEditor(for event: NSEvent) -> EditorViewController? {
        guard let window = event.window,
              let tv = window.firstResponder as? NSTextView else { return nil }
        var next: NSResponder? = tv.nextResponder
        while let r = next {
            if let vc = r as? EditorViewController, vc.textView === tv { return vc }
            next = r.nextResponder
        }
        return nil
    }
}

// MARK: - Shortcut dispatch

extension EditorViewController {

    fileprivate func handleShortcutEvent(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key  = event.keyCode

        switch (mods, key) {
        case (.option, 126):            moveLineUp();          return true
        case (.option, 125):            moveLineDown();        return true
        case ([.command, .shift], 40):  deleteCurrentLine();   return true
        case ([.command, .shift], 37):  selectAllOccurrences();return true
        case ([], 48):                  if indentSelectedLines() { return true }; return false
        case (.shift, 48):              unindentSelectedLines(); return true
        default:                        return false
        }
    }
}

// MARK: - Option+Up / Option+Down — move line

extension EditorViewController {

    fileprivate func moveLineUp() {
        let ns = textView.string as NSString
        guard ns.length > 0 else { return }

        let sel      = textView.selectedRange()
        let curRange = ns.lineRange(for: sel)
        guard curRange.location > 0 else { return }

        let aboveRange = ns.lineRange(for: NSRange(location: curRange.location - 1, length: 0))

        var curText   = ns.substring(with: curRange)
        var aboveText = ns.substring(with: aboveRange)

        if !curText.hasSuffix("\n") && aboveText.hasSuffix("\n") {
            curText   += "\n"
            aboveText  = String(aboveText.dropLast())
        }

        let fullRange = NSRange(location: aboveRange.location,
                                length: NSMaxRange(curRange) - aboveRange.location)
        replaceText(in: fullRange, with: curText + aboveText)

        let newStart = aboveRange.location + (sel.location - curRange.location)
        textView.setSelectedRange(NSRange(location: newStart, length: sel.length))
    }

    fileprivate func moveLineDown() {
        let ns = textView.string as NSString
        guard ns.length > 0 else { return }

        let sel      = textView.selectedRange()
        let curRange = ns.lineRange(for: sel)
        guard NSMaxRange(curRange) < ns.length else { return }

        let belowRange = ns.lineRange(for: NSRange(location: NSMaxRange(curRange), length: 0))

        var curText   = ns.substring(with: curRange)
        var belowText = ns.substring(with: belowRange)

        if !belowText.hasSuffix("\n") && curText.hasSuffix("\n") {
            belowText += "\n"
            curText    = String(curText.dropLast())
        }

        let fullRange = NSRange(location: curRange.location,
                                length: NSMaxRange(belowRange) - curRange.location)
        replaceText(in: fullRange, with: belowText + curText)

        let newStart = curRange.location
                     + (belowText as NSString).length
                     + (sel.location - curRange.location)
        textView.setSelectedRange(NSRange(location: newStart, length: sel.length))
    }
}

// MARK: - Cmd+Shift+K — delete current line

extension EditorViewController {

    fileprivate func deleteCurrentLine() {
        let ns = textView.string as NSString
        guard ns.length > 0 else { return }

        let sel = textView.selectedRange()
        var lineRange = ns.lineRange(for: sel)

        if NSMaxRange(lineRange) == ns.length && lineRange.location > 0 {
            lineRange = NSRange(location: lineRange.location - 1,
                                length: lineRange.length + 1)
        }

        replaceText(in: lineRange, with: "")

        let newPos = min(lineRange.location, (textView.string as NSString).length)
        textView.setSelectedRange(NSRange(location: newPos, length: 0))
    }
}

// MARK: - Cmd+Shift+L — select all occurrences & enter multi-edit

extension EditorViewController {

    fileprivate func selectAllOccurrences() {
        let sel = textView.selectedRange()
        guard sel.length > 0 else { return }

        let ns     = textView.string as NSString
        let needle = ns.substring(with: sel)

        var ranges: [NSValue] = []
        var pos = 0
        while pos < ns.length {
            let r = ns.range(of: needle,
                             range: NSRange(location: pos, length: ns.length - pos))
            if r.location == NSNotFound { break }
            ranges.append(NSValue(range: r))
            pos = NSMaxRange(r)
        }

        guard !ranges.isEmpty else { return }
        textView.setSelectedRanges(ranges, affinity: .downstream, stillSelecting: false)

        if ranges.count > 1 {
            let id = ObjectIdentifier(self)
            multiEditActive[id] = true
            multiEditCursors[id] = ranges.map { $0.rangeValue }
        }
    }
}

// MARK: - Multi-edit key routing

extension EditorViewController {

    fileprivate func handleMultiEditKey(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key  = event.keyCode

        if key == 53 { exitMultiEdit(); return true }

        if [123, 124, 125, 126, 36, 76, 48].contains(key) {
            exitMultiEdit(); return false
        }

        if mods.contains(.command) { exitMultiEdit(); return false }

        if key == 51  { multiEditBackspace();     return true }
        if key == 117 { multiEditForwardDelete(); return true }

        if let chars = event.characters, !chars.isEmpty,
           chars.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) {
            multiEditInsert(chars)
            return true
        }

        exitMultiEdit()
        return false
    }

    fileprivate func exitMultiEdit() {
        let id = ObjectIdentifier(self)
        multiEditActive[id] = false
        multiEditCursors[id] = nil
    }
}

// MARK: - Multi-edit operations

extension EditorViewController {

    fileprivate func multiEditInsert(_ text: String) {
        guard let cursors = multiEditCursors[ObjectIdentifier(self)],
              !cursors.isEmpty else { exitMultiEdit(); return }
        batchReplace(cursors, with: text)
    }

    fileprivate func multiEditBackspace() {
        guard let cursors = multiEditCursors[ObjectIdentifier(self)],
              !cursors.isEmpty else { exitMultiEdit(); return }

        if cursors.contains(where: { $0.length > 0 }) {
            batchReplace(cursors, with: "")
        } else {
            let expanded = cursors.compactMap { r -> NSRange? in
                guard r.location > 0 else { return nil }
                return NSRange(location: r.location - 1, length: 1)
            }
            guard !expanded.isEmpty else { return }
            batchReplace(expanded, with: "")
        }
    }

    fileprivate func multiEditForwardDelete() {
        guard let cursors = multiEditCursors[ObjectIdentifier(self)],
              !cursors.isEmpty else { exitMultiEdit(); return }
        let len = (textView.string as NSString).length

        if cursors.contains(where: { $0.length > 0 }) {
            batchReplace(cursors, with: "")
        } else {
            let expanded = cursors.compactMap { r -> NSRange? in
                guard r.location < len else { return nil }
                return NSRange(location: r.location, length: 1)
            }
            guard !expanded.isEmpty else { return }
            batchReplace(expanded, with: "")
        }
    }
}

// MARK: - Batch replacement engine (multi-cursor aware)

extension EditorViewController {

    /// Replaces every range with `text`, merges overlaps, repositions all cursors,
    /// and auto-exits multi-edit when only one cursor remains.
    ///
    /// We deliberately bypass `didChangeText()` here because the delegate's
    /// `textDidChange` handler runs rehighlighting via `ts.beginEditing/endEditing`,
    /// which collapses multi-selection back to a single cursor.  Instead we update
    /// the document state and undo stack manually.
    fileprivate func batchReplace(_ targetRanges: [NSRange], with text: String) {
        guard let ts = textView.textStorage else { return }

        let sorted = targetRanges.sorted { $0.location < $1.location }
        var merged: [NSRange] = []
        for range in sorted {
            if let last = merged.last, range.location <= NSMaxRange(last) {
                let end = max(NSMaxRange(last), NSMaxRange(range))
                merged[merged.count - 1] = NSRange(location: last.location,
                                                    length: end - last.location)
            } else {
                merged.append(range)
            }
        }
        guard !merged.isEmpty else { return }

        let insertLen = (text as NSString).length

        var positions: [Int] = []
        var offset = 0
        for range in merged {
            positions.append(range.location + offset + insertLen)
            offset += insertLen - range.length
        }

        let oldString = textView.string
        let oldRanges = textView.selectedRanges

        ts.beginEditing()
        for range in merged.reversed() {
            ts.replaceCharacters(in: range, with: text)
        }
        ts.endEditing()

        let newContent = textView.string
        document?.content = newContent
        document?.markModified()
        delegate?.editorTextDidChange(self)

        textView.undoManager?.registerUndo(withTarget: textView) { [weak self] tv in
            guard let self = self else { return }
            tv.textStorage?.beginEditing()
            tv.textStorage?.replaceCharacters(
                in: NSRange(location: 0, length: (tv.string as NSString).length),
                with: oldString)
            tv.textStorage?.endEditing()
            self.document?.content = oldString
            self.document?.markModified()
            self.delegate?.editorTextDidChange(self)
            tv.setSelectedRanges(oldRanges, affinity: .downstream, stillSelecting: false)
        }

        let maxLen = (newContent as NSString).length
        let unique = Array(Set(positions.map { max(0, min($0, maxLen)) })).sorted()
        let newCursors = unique.map { NSRange(location: $0, length: 0) }

        if newCursors.count <= 1 { exitMultiEdit() }
        else { multiEditCursors[ObjectIdentifier(self)] = newCursors }

        let nsValues = newCursors.map { NSValue(range: $0) }
        if !nsValues.isEmpty {
            textView.setSelectedRanges(nsValues, affinity: .downstream, stillSelecting: false)
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !nsValues.isEmpty else { return }
                self.textView.setSelectedRanges(nsValues, affinity: .downstream,
                                                stillSelecting: false)
            }
        }
    }
}

// MARK: - Tab / Shift+Tab — indent / unindent selected lines

extension EditorViewController {

    /// Indents all selected lines when the selection spans multiple lines.
    /// Returns `false` (pass-through to default Tab behavior) for single-line or empty selections.
    fileprivate func indentSelectedLines() -> Bool {
        let sel = textView.selectedRange()
        guard sel.length > 0 else { return false }

        let ns = textView.string as NSString
        guard ns.substring(with: sel).contains("\n") else { return false }

        let lineRange = ns.lineRange(for: sel)
        let text = ns.substring(with: lineRange)

        var indented = "\t" + text.replacingOccurrences(of: "\n", with: "\n\t")
        if text.hasSuffix("\n") { indented = String(indented.dropLast()) }

        replaceText(in: lineRange, with: indented)
        textView.setSelectedRange(NSRange(location: lineRange.location,
                                          length: (indented as NSString).length))
        return true
    }

    /// Removes one level of indentation (one tab or up to 4 leading spaces) from
    /// each selected line, or the current line when nothing is selected.
    fileprivate func unindentSelectedLines() {
        let sel = textView.selectedRange()
        let ns = textView.string as NSString
        let lineRange = ns.lineRange(for: sel)
        let text = ns.substring(with: lineRange)

        let lines = text.components(separatedBy: "\n")
        let result = lines.enumerated().map { i, line -> String in
            if i == lines.count - 1 && line.isEmpty { return line }
            if line.hasPrefix("\t") { return String(line.dropFirst()) }
            var s = line[...]
            var n = 0
            while s.hasPrefix(" ") && n < 4 { s = s.dropFirst(); n += 1 }
            return String(s)
        }.joined(separator: "\n")

        guard result != text else { return }
        replaceText(in: lineRange, with: result)
        textView.setSelectedRange(NSRange(location: lineRange.location,
                                          length: (result as NSString).length))
    }
}

// MARK: - Single-range text replacement (used by move / delete line)

extension EditorViewController {

    fileprivate func replaceText(in range: NSRange, with replacement: String) {
        guard textView.shouldChangeText(in: range, replacementString: replacement) else { return }
        textView.textStorage?.replaceCharacters(in: range, with: replacement)
        textView.didChangeText()
    }
}
