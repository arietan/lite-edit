import AppKit

protocol TabBarViewDelegate: AnyObject {
    func tabBarDidSelectTab(at index: Int)
    func tabBarDidCloseTab(at index: Int)
}

struct TabItem {
    let title: String
    let isModified: Bool
}

final class TabBarView: NSView {
    weak var delegate: TabBarViewDelegate?

    var tabs: [TabItem] = [] { didSet { rebuildTabs() } }
    var selectedIndex: Int = 0 { didSet { updateAppearance() } }

    private let tabHeight: CGFloat = 32
    private let tabWidth: CGFloat = 180

    private var bgLayers: [NSView] = []
    private var accentLayers: [NSView] = []
    private var titleLabels: [NSTextField] = []
    private var closeLabels: [NSTextField] = []
    private var separators: [NSView] = []
    private let bottomBorder = NSView()

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = Theme.tabBarBg.cgColor

        bottomBorder.wantsLayer = true
        bottomBorder.layer?.backgroundColor = Theme.border.cgColor
        addSubview(bottomBorder)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let b = bounds
        bottomBorder.frame = NSRect(x: 0, y: tabHeight - 1, width: b.width, height: 1)

        for (i, bg) in bgLayers.enumerated() {
            let x = CGFloat(i) * tabWidth
            bg.frame = NSRect(x: x, y: 0, width: tabWidth, height: tabHeight)
            accentLayers[i].frame = NSRect(x: x, y: 0, width: tabWidth, height: 2)
            titleLabels[i].frame = NSRect(x: x + 14, y: 8, width: tabWidth - 42, height: 16)
            closeLabels[i].frame = NSRect(x: x + tabWidth - 26, y: 8, width: 14, height: 16)
            separators[i].frame = NSRect(x: x + tabWidth - 1, y: 4, width: 1, height: tabHeight - 8)
        }
    }

    private func clearAll() {
        for arr: [NSView] in [bgLayers, accentLayers, titleLabels, closeLabels, separators] {
            arr.forEach { $0.removeFromSuperview() }
        }
        bgLayers.removeAll(); accentLayers.removeAll()
        titleLabels.removeAll(); closeLabels.removeAll(); separators.removeAll()
    }

    private func rebuildTabs() {
        clearAll()

        for (_, tab) in tabs.enumerated() {
            let bg = NSView()
            bg.wantsLayer = true
            addSubview(bg)
            bgLayers.append(bg)

            let accent = NSView()
            accent.wantsLayer = true
            accent.layer?.backgroundColor = Theme.accent.cgColor
            addSubview(accent)
            accentLayers.append(accent)

            let sep = NSView()
            sep.wantsLayer = true
            sep.layer?.backgroundColor = Theme.tabBarBg.cgColor
            addSubview(sep)
            separators.append(sep)

            let displayTitle = tab.isModified ? "● \(tab.title)" : tab.title
            let lbl = NSTextField(labelWithString: displayTitle)
            lbl.font = NSFont.systemFont(ofSize: 12)
            lbl.lineBreakMode = .byTruncatingTail
            lbl.isBordered = false
            lbl.isEditable = false
            lbl.drawsBackground = false
            addSubview(lbl)
            titleLabels.append(lbl)

            let close = NSTextField(labelWithString: "×")
            close.font = NSFont.systemFont(ofSize: 14, weight: .light)
            close.alignment = .center
            close.isBordered = false
            close.isEditable = false
            close.drawsBackground = false
            addSubview(close)
            closeLabels.append(close)
        }

        addSubview(bottomBorder)
        needsLayout = true
        updateAppearance()
    }

    private func updateAppearance() {
        for i in 0..<bgLayers.count {
            let active = (i == selectedIndex)
            bgLayers[i].layer?.backgroundColor = (active ? Theme.background : Theme.tabInactive).cgColor
            accentLayers[i].isHidden = !active
            titleLabels[i].textColor = active ? Theme.tabTextActive : Theme.tabText
            titleLabels[i].font = NSFont.systemFont(ofSize: 12, weight: active ? .medium : .regular)
            closeLabels[i].textColor = active ? Theme.tabText : Theme.tabText.withAlphaComponent(0.3)
            separators[i].isHidden = active
        }
    }

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        let idx = Int(pt.x / tabWidth)
        guard idx >= 0, idx < tabs.count else { return }

        let tabRight = CGFloat(idx + 1) * tabWidth
        if pt.x > tabRight - 30 {
            delegate?.tabBarDidCloseTab(at: idx)
        } else {
            delegate?.tabBarDidSelectTab(at: idx)
        }
    }
}
