import AppKit

final class StatusBarView: NSView {
    private let lineColLabel = NSTextField(labelWithString: "Ln 1, Col 1")
    private let langLabel    = NSTextField(labelWithString: "Plain Text")
    private let encLabel     = NSTextField(labelWithString: "UTF-8")
    private let indentLabel  = NSTextField(labelWithString: "Spaces: 4")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = Theme.statusBg.cgColor
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let h = bounds.height
        let midY = (h - 16) / 2
        lineColLabel.frame = NSRect(x: 14, y: midY, width: 100, height: 16)
        indentLabel.frame = NSRect(x: 120, y: midY, width: 80, height: 16)
        langLabel.sizeToFit()
        langLabel.frame.origin = NSPoint(x: bounds.width - 14 - langLabel.frame.width, y: midY)
        encLabel.sizeToFit()
        encLabel.frame.origin = NSPoint(x: langLabel.frame.minX - 20 - encLabel.frame.width, y: midY)
    }

    private func setup() {
        let labels = [lineColLabel, langLabel, encLabel, indentLabel]
        for l in labels {
            l.font = Theme.uiFontSmall
            l.textColor = Theme.statusText
            l.isBordered = false
            l.isEditable = false
            l.drawsBackground = false
            addSubview(l)
        }
    }

    func updateCursor(line: Int, col: Int) {
        lineColLabel.stringValue = "Ln \(line), Col \(col)"
        needsLayout = true
    }

    func updateLanguage(_ lang: Document.Language) {
        langLabel.stringValue = lang.displayName
        needsLayout = true
    }
}
