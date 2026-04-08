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

    private var suppressTextChange = false

    var document: Document? {
        didSet { if isViewLoaded { loadDoc() } }
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
    }

    // MARK: - Document

    private func loadDoc() {
        guard let doc = document else { return }
        suppressTextChange = true
        textView.string = doc.content
        suppressTextChange = false
        highlighter = SyntaxHighlighter(language: doc.language)
        rehighlightAll()
        lineNumbers?.needsDisplay = true
    }

    private func rehighlightAll() {
        guard let ts = textView.textStorage, ts.length > 0 else { return }
        ts.beginEditing()
        highlighter?.highlight(ts, in: NSRange(location: 0, length: ts.length))
        ts.endEditing()
    }

    // MARK: - NSTextViewDelegate

    func textDidChange(_ n: Notification) {
        guard !suppressTextChange else { return }
        let content = textView.string
        document?.content = content
        document?.markModified()
        delegate?.editorTextDidChange(self)
        lineNumbers?.needsDisplay = true
        emitCursor()

        if let ts = textView.textStorage, ts.length > 0 {
            let sel = textView.selectedRange()
            let ns = content as NSString
            let lineRange = ns.lineRange(for: NSRange(location: min(sel.location, ns.length), length: 0))
            ts.beginEditing()
            highlighter?.highlight(ts, in: lineRange)
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
