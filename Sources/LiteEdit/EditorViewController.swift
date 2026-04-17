import AppKit

protocol EditorViewControllerDelegate: AnyObject {
    func editorTextDidChange(_ vc: EditorViewController)
    func editorCursorMoved(_ vc: EditorViewController, line: Int, col: Int)
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

final class EditorViewController: NSViewController, NSTextViewDelegate {
    weak var delegate: EditorViewControllerDelegate?

    private(set) var scrollView: NSScrollView!
    private(set) var textView: NSTextView!
    private var lineNumbers: LineNumberView?
    private var highlighter: SyntaxHighlighter?

    private static var highlighterCache: [Document.Language: SyntaxHighlighter] = [:]
    private static let fullHighlightThreshold = 100_000
    private var highlightWorkItem: DispatchWorkItem?
    private var scrollHighlightItem: DispatchWorkItem?

    private var suppressTextChange = false
    private var suppressAutoIndent = false

    var document: Document? {
        didSet { if isViewLoaded && document !== oldValue { loadDoc() } }
    }

    private static func cachedHighlighter(for language: Document.Language) -> SyntaxHighlighter {
        if let h = highlighterCache[language] { return h }
        let h = SyntaxHighlighter(language: language)
        highlighterCache[language] = h
        return h
    }

    // MARK: - View lifecycle

    override func loadView() {
        let wrapper = FlippedView()

        scrollView = NSTextView.scrollableTextView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        textView = scrollView.documentView as? NSTextView
        // Force TextKit 1 so layout manager APIs work reliably
        _ = textView.layoutManager

        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = false
        textView.backgroundColor = Theme.background
        textView.insertionPointColor = Theme.cursor
        textView.selectedTextAttributes = [
            .backgroundColor: Theme.selection,
            .foregroundColor: Theme.foreground,
        ]
        textView.font = Theme.editorFont
        textView.textColor = Theme.foreground
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = self

        let tabW = " ".size(withAttributes: [.font: Theme.editorFont]).width * 4
        let para = NSMutableParagraphStyle()
        para.tabStops = []
        para.defaultTabInterval = tabW
        textView.defaultParagraphStyle = para
        textView.typingAttributes = [
            .font: Theme.editorFont,
            .foregroundColor: Theme.foreground,
            .paragraphStyle: para,
        ]

        lineNumbers = LineNumberView(textView: textView)

        wrapper.addSubview(lineNumbers!)
        wrapper.addSubview(scrollView)
        NSLayoutConstraint.activate([
            lineNumbers!.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lineNumbers!.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            lineNumbers!.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: wrapper.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: lineNumbers!.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            self, selector: #selector(boundsChanged),
            name: NSView.boundsDidChangeNotification, object: scrollView.contentView
        )

        view = wrapper
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.async { [weak self] in
            self?.textView.window?.makeFirstResponder(self?.textView)
        }
    }

    @objc private func boundsChanged(_ n: Notification) {
        lineNumbers?.needsDisplay = true
        scheduleScrollHighlight()
    }

    private func scheduleScrollHighlight() {
        scrollHighlightItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.highlightVisible()
        }
        scrollHighlightItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: item)
    }

    // MARK: - Document

    private func loadDoc() {
        guard let doc = document else { return }
        highlightWorkItem?.cancel()
        scrollHighlightItem?.cancel()
        highlighter = Self.cachedHighlighter(for: doc.language)

        let lm = textView.layoutManager!
        suppressTextChange = true

        if let cached = doc.cachedTextStorage {
            lm.replaceTextStorage(cached)
        } else {
            let para = textView.defaultParagraphStyle ?? NSParagraphStyle.default
            let ts = NSTextStorage(string: doc.content, attributes: [
                .font: Theme.editorFont,
                .foregroundColor: Theme.foreground,
                .paragraphStyle: para,
            ])
            lm.replaceTextStorage(ts)
            doc.cachedTextStorage = ts
        }

        suppressTextChange = false
        lineNumbers?.needsDisplay = true
        deferredHighlightVisible()
    }

    /// Deferred to next run-loop so the scroll view geometry is settled
    /// after replaceTextStorage.  For small files the full document is
    /// highlighted; large files get viewport-only (scroll handles the rest).
    private func deferredHighlightVisible() {
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard let ts = self.textView.textStorage, ts.length > 0 else { return }

            let visible = self.visibleCharacterRange()
            if ts.length <= Self.fullHighlightThreshold {
                ts.beginEditing()
                self.highlighter?.highlight(ts, in: NSRange(location: 0, length: ts.length))
                ts.endEditing()
            } else if visible.length > 0 {
                ts.beginEditing()
                self.highlighter?.highlight(ts, in: visible)
                ts.endEditing()
            }
        }
        highlightWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02, execute: item)
    }

    /// Highlights the visible range plus a buffer for smooth scrolling.
    private func highlightVisible() {
        guard let ts = textView.textStorage, ts.length > 0 else { return }
        let visible = visibleCharacterRange()
        guard visible.length > 0 else { return }

        let buffer = 3000
        let start = max(0, visible.location - buffer)
        let end = min(ts.length, NSMaxRange(visible) + buffer)
        let range = NSRange(location: start, length: end - start)

        ts.beginEditing()
        highlighter?.highlight(ts, in: range)
        ts.endEditing()
    }

    private func visibleCharacterRange() -> NSRange {
        guard let lm = textView.layoutManager, let tc = textView.textContainer else {
            return NSRange(location: 0, length: textView.textStorage?.length ?? 0)
        }
        let visibleRect = scrollView.documentVisibleRect
        let glyphRange = lm.glyphRange(forBoundingRect: visibleRect, in: tc)
        return lm.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    }

    private func rehighlightAll() {
        guard let ts = textView.textStorage, ts.length > 0 else { return }
        if ts.length > Self.fullHighlightThreshold {
            highlightVisible()
            return
        }
        ts.beginEditing()
        highlighter?.highlight(ts, in: NSRange(location: 0, length: ts.length))
        ts.endEditing()
    }

    // MARK: - NSTextViewDelegate

    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange,
                  replacementString text: String?) -> Bool {
        guard !suppressAutoIndent, let text = text, text == "\n" else { return true }

        let ns = textView.string as NSString
        let lineRange = ns.lineRange(for: NSRange(location: min(range.location, ns.length), length: 0))
        let line = ns.substring(with: lineRange)

        var indent = ""
        for ch in line {
            if ch == " " || ch == "\t" { indent.append(ch) }
            else { break }
        }
        guard !indent.isEmpty else { return true }

        suppressAutoIndent = true
        textView.insertText("\n" + indent, replacementRange: range)
        suppressAutoIndent = false
        return false
    }

    func textDidChange(_ n: Notification) {
        guard !suppressTextChange else { return }
        let content = textView.string
        document?.content = content
        document?.markModified()
        delegate?.editorTextDidChange(self)
        lineNumbers?.needsDisplay = true
        emitCursor()

        if let ts = textView.textStorage, ts.length > 0 {
            let rehighlightRange: NSRange
            if document?.language == .markdown {
                rehighlightRange = visibleCharacterRange()
            } else {
                let sel = textView.selectedRange()
                let ns = content as NSString
                rehighlightRange = ns.lineRange(for: NSRange(location: min(sel.location, ns.length), length: 0))
            }
            ts.beginEditing()
            highlighter?.highlight(ts, in: rehighlightRange)
            ts.endEditing()
        }
    }

    func textViewDidChangeSelection(_ n: Notification) {
        lineNumbers?.needsDisplay = true
        emitCursor()
    }

    private func emitCursor() {
        let sel = textView.selectedRange()
        let ns = textView.string as NSString
        var line = 1
        var i = 0
        while i < sel.location && i < ns.length {
            if ns.character(at: i) == 0x0A { line += 1 }
            i += 1
        }
        let lineStart = ns.lineRange(for: NSRange(location: min(sel.location, ns.length), length: 0)).location
        delegate?.editorCursorMoved(self, line: line, col: sel.location - lineStart + 1)
    }

    // MARK: - Find / Replace

    func findNext(_ text: String, caseSensitive: Bool = false, regex: Bool = false) -> Bool {
        guard !text.isEmpty else { return false }
        let ns = textView.string as NSString
        let start = NSMaxRange(textView.selectedRange())
        var opts: NSString.CompareOptions = []
        if !caseSensitive { opts.insert(.caseInsensitive) }
        if regex { opts.insert(.regularExpression) }
        var r = ns.range(of: text, options: opts, range: NSRange(location: start, length: ns.length - start))
        if r.location == NSNotFound {
            r = ns.range(of: text, options: opts, range: NSRange(location: 0, length: ns.length))
        }
        if r.location != NSNotFound {
            textView.setSelectedRange(r)
            textView.scrollRangeToVisible(r)
            textView.showFindIndicator(for: r)
            return true
        }
        return false
    }

    func findPrev(_ text: String, caseSensitive: Bool = false) -> Bool {
        guard !text.isEmpty else { return false }
        let ns = textView.string as NSString
        let end = textView.selectedRange().location
        var opts: NSString.CompareOptions = [.backwards]
        if !caseSensitive { opts.insert(.caseInsensitive) }
        var r = ns.range(of: text, options: opts, range: NSRange(location: 0, length: end))
        if r.location == NSNotFound {
            r = ns.range(of: text, options: opts, range: NSRange(location: 0, length: ns.length))
        }
        if r.location != NSNotFound {
            textView.setSelectedRange(r)
            textView.scrollRangeToVisible(r)
            textView.showFindIndicator(for: r)
            return true
        }
        return false
    }

    func replaceCurrent(_ search: String, with repl: String, caseSensitive: Bool = false) -> Bool {
        let sel = textView.selectedRange()
        let selected = (textView.string as NSString).substring(with: sel)
        let match = caseSensitive ? selected == search : selected.caseInsensitiveCompare(search) == .orderedSame
        if match { textView.insertText(repl, replacementRange: sel) }
        return findNext(search, caseSensitive: caseSensitive)
    }

    func replaceAll(_ search: String, with repl: String, caseSensitive: Bool = false) -> Int {
        guard !search.isEmpty else { return 0 }
        let ranges = allRanges(search, caseSensitive: caseSensitive)
        guard !ranges.isEmpty else { return 0 }
        var result = textView.string
        for r in ranges.reversed() {
            guard let sr = Range(r, in: result) else { continue }
            result.replaceSubrange(sr, with: repl)
        }
        textView.string = result
        document?.content = result
        document?.markModified()
        delegate?.editorTextDidChange(self)
        rehighlightAll()
        return ranges.count
    }

    func matchCount(_ text: String, caseSensitive: Bool = false) -> Int {
        allRanges(text, caseSensitive: caseSensitive).count
    }

    private func allRanges(_ text: String, caseSensitive: Bool) -> [NSRange] {
        guard !text.isEmpty else { return [] }
        let ns = textView.string as NSString
        var opts: NSString.CompareOptions = []
        if !caseSensitive { opts.insert(.caseInsensitive) }
        var results: [NSRange] = []
        var pos = 0
        while pos < ns.length {
            let r = ns.range(of: text, options: opts, range: NSRange(location: pos, length: ns.length - pos))
            if r.location == NSNotFound { break }
            results.append(r)
            pos = NSMaxRange(r)
        }
        return results
    }

    func goToLine(_ line: Int) {
        let ns = textView.string as NSString
        var cur = 1, idx = 0
        while cur < line && idx < ns.length {
            if ns.character(at: idx) == 0x0A { cur += 1 }
            idx += 1
        }
        if cur == line {
            let lr = ns.lineRange(for: NSRange(location: idx, length: 0))
            textView.setSelectedRange(NSRange(location: lr.location, length: 0))
            textView.scrollRangeToVisible(lr)
        }
    }
}
