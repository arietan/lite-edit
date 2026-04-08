import AppKit

/// Line number gutter implemented as a plain NSView (not NSRulerView) because
/// overriding drawHashMarksAndLabels on NSRulerView subclasses breaks
/// NSTextView rendering on macOS 15+.
final class LineNumberView: NSView {
    private weak var textView: NSTextView?
    override var isFlipped: Bool { true }

    init(textView: NSTextView) {
        self.textView = textView
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 48).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        Theme.gutterBg.setFill()
        dirtyRect.fill()

        Theme.border.setFill()
        NSRect(x: bounds.width - 1, y: dirtyRect.origin.y, width: 1, height: dirtyRect.height).fill()

        guard let tv = textView,
              let lm = tv.layoutManager,
              let tc = tv.textContainer else {
            drawNumber(1, y: 8, active: true)
            return
        }

        let string = tv.string as NSString
        let containerOrigin = tv.textContainerOrigin

        if string.length == 0 {
            drawNumber(1, y: containerOrigin.y - scrollOffset, active: true)
            return
        }

        let selectedRange = tv.selectedRange()
        guard let sv = tv.enclosingScrollView else { return }
        let visibleRect = sv.contentView.bounds
        let glyphRange = lm.glyphRange(forBoundingRect: visibleRect, in: tc)
        let charRange = lm.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        var lineNum = 1
        var idx = 0
        while idx < charRange.location {
            let lr = string.lineRange(for: NSRange(location: idx, length: 0))
            lineNum += 1
            idx = NSMaxRange(lr)
        }

        let yOffset = scrollOffset
        var gi = glyphRange.location
        while gi < NSMaxRange(glyphRange) {
            var effectiveRange = NSRange()
            let fragRect = lm.lineFragmentRect(forGlyphAt: gi, effectiveRange: &effectiveRange)
            let cr = lm.characterRange(forGlyphRange: effectiveRange, actualGlyphRange: nil)
            let lr = string.lineRange(for: NSRange(location: cr.location, length: 0))

            if cr.location == lr.location {
                let y = fragRect.origin.y + containerOrigin.y - yOffset
                let active = NSLocationInRange(selectedRange.location, lr)
                drawNumber(lineNum, y: y, active: active)
                lineNum += 1
            }
            gi = NSMaxRange(effectiveRange)
        }
    }

    private var scrollOffset: CGFloat {
        textView?.enclosingScrollView?.contentView.bounds.origin.y ?? 0
    }

    private func drawNumber(_ num: Int, y: CGFloat, active: Bool) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Theme.lineNumFont,
            .foregroundColor: active ? Theme.gutterActiveText : Theme.gutterText
        ]
        let str = "\(num)" as NSString
        let sz = str.size(withAttributes: attrs)
        let pt = NSPoint(x: bounds.width - sz.width - 10,
                         y: y + (Theme.editorFont.ascender - sz.height) / 2 + 2)
        str.draw(at: pt, withAttributes: attrs)
    }
}
