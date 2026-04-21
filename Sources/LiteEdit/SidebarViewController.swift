import AppKit

protocol SidebarDelegate: AnyObject {
    func sidebarDidSelectFile(_ url: URL, inNewTab: Bool)
}

final class FileItem: NSObject {
    let url: URL
    let isDirectory: Bool
    private var childrenLoaded = false
    var children: [FileItem]?

    var name: String { url.lastPathComponent }

    private static let skippedDirs: Set<String> = [
        ".git", ".svn", ".hg", "node_modules", ".build", ".swiftpm",
        "Pods", "DerivedData", ".next", "__pycache__", ".cache",
        "build", "dist", ".DS_Store", ".Trash",
    ]

    init(url: URL, isDir: Bool? = nil) {
        self.url = url
        if let known = isDir {
            self.isDirectory = known
        } else {
            var d: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &d)
            self.isDirectory = d.boolValue
        }
        super.init()
    }

    func loadChildrenIfNeeded() {
        guard isDirectory, !childrenLoaded else { return }
        childrenLoaded = true
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { children = []; return }

        children = items
            .filter { !FileItem.skippedDirs.contains($0.lastPathComponent) }
            .sorted {
                let aDir = (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let bDir = (try? $1.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if aDir != bDir { return aDir }
                return $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
            .map {
                let isDir = (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return FileItem(url: $0, isDir: isDir)
            }
    }
}

// MARK: - Custom outline view that intercepts Cmd+Click

private final class SidebarOutlineView: NSOutlineView {
    var onCmdClick: ((_ row: Int) -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            let pt = convert(event.locationInWindow, from: nil)
            let row = self.row(at: pt)
            if row >= 0 {
                onCmdClick?(row)
                return
            }
        }
        super.mouseDown(with: event)
    }
}

// MARK: - Sidebar

final class SidebarViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    weak var sidebarDelegate: SidebarDelegate?

    private var outlineView: SidebarOutlineView!
    private var headerLabel: NSTextField!
    private var rootItems: [FileItem] = []
    private(set) var rootFolderURL: URL?
    private var suppressSelectionCallback = false

    override func loadView() {
        let wrapper = NSView()
        wrapper.wantsLayer = true
        wrapper.layer?.backgroundColor = Theme.sidebarBg.cgColor
        wrapper.appearance = NSAppearance(named: .darkAqua)

        headerLabel = NSTextField(labelWithString: "EXPLORER")
        headerLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        headerLabel.textColor = Theme.sidebarText.withAlphaComponent(0.5)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(headerLabel)

        let sv = NSScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.hasVerticalScroller = true
        sv.autohidesScrollers = true
        sv.borderType = .noBorder
        sv.drawsBackground = false
        sv.scrollerStyle = .overlay

        outlineView = SidebarOutlineView()
        outlineView.headerView = nil
        outlineView.backgroundColor = Theme.sidebarBg
        outlineView.indentationPerLevel = 16
        outlineView.rowHeight = 24
        outlineView.selectionHighlightStyle = .regular
        outlineView.allowsMultipleSelection = false

        outlineView.onCmdClick = { [weak self] row in
            self?.handleNewTab(row: row)
        }

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("F"))
        col.isEditable = false
        outlineView.addTableColumn(col)
        outlineView.outlineTableColumn = col

        outlineView.dataSource = self
        outlineView.delegate = self

        let contextMenu = NSMenu()
        contextMenu.delegate = self
        outlineView.menu = contextMenu

        sv.documentView = outlineView
        wrapper.addSubview(sv)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 14),

            sv.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            sv.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            sv.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            sv.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])

        view = wrapper
    }

    func openFolder(_ url: URL) {
        rootFolderURL = url
        let root = FileItem(url: url, isDir: true)
        root.loadChildrenIfNeeded()
        rootItems = root.children ?? []
        headerLabel.stringValue = url.lastPathComponent.uppercased()
        outlineView.reloadData()
    }

    /// Expand parent directories and select the row matching `url`.
    func revealFile(_ url: URL) {
        guard let root = rootFolderURL else { return }
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard url.path.hasPrefix(rootPath) else { return }

        let relative = String(url.path.dropFirst(rootPath.count))
        let components = relative.split(separator: "/").map(String.init)
        guard !components.isEmpty else { return }

        var currentItems = rootItems

        for (i, name) in components.enumerated() {
            guard let match = currentItems.first(where: { $0.name == name }) else { return }

            if i < components.count - 1 {
                guard match.isDirectory else { return }
                match.loadChildrenIfNeeded()
                outlineView.expandItem(match)
                currentItems = match.children ?? []
            } else {
                let row = outlineView.row(forItem: match)
                guard row >= 0 else { return }
                suppressSelectionCallback = true
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                outlineView.scrollRowToVisible(row)
                suppressSelectionCallback = false
            }
        }
    }

    // MARK: - New tab handling

    private func handleNewTab(row: Int) {
        guard let fi = outlineView.item(atRow: row) as? FileItem, !fi.isDirectory else { return }
        sidebarDelegate?.sidebarDidSelectFile(fi.url, inNewTab: true)
    }

    @objc private func contextOpenInNewTab(_ sender: Any?) {
        let row = outlineView.clickedRow
        guard row >= 0 else { return }
        handleNewTab(row: row)
    }

    // MARK: - Data source

    func outlineView(_ ov: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { return rootItems.count }
        guard let fi = item as? FileItem else { return 0 }
        fi.loadChildrenIfNeeded()
        return fi.children?.count ?? 0
    }

    func outlineView(_ ov: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil { return rootItems[index] }
        return (item as! FileItem).children![index]
    }

    func outlineView(_ ov: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? FileItem)?.isDirectory ?? false
    }

    // MARK: - Delegate

    func outlineView(_ ov: NSOutlineView, viewFor col: NSTableColumn?, item: Any) -> NSView? {
        guard let fi = item as? FileItem else { return nil }

        let cell = NSTableCellView()
        let iv = NSImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        let iconName = fi.isDirectory ? "folder.fill" : fileIcon(fi.url)
        iv.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        iv.contentTintColor = fi.isDirectory
            ? NSColor(srgbRed: 0.4, green: 0.85, blue: 0.94, alpha: 1)
            : Theme.sidebarText
        iv.imageScaling = .scaleProportionallyDown

        let tf = NSTextField(labelWithString: fi.name)
        tf.font = Theme.uiFontSmall
        tf.textColor = Theme.sidebarText
        tf.lineBreakMode = .byTruncatingTail
        tf.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(iv)
        cell.addSubview(tf)
        cell.imageView = iv
        cell.textField = tf

        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            iv.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 16),
            iv.heightAnchor.constraint(equalToConstant: 16),
            tf.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: 6),
            tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    func outlineViewSelectionDidChange(_ n: Notification) {
        guard !suppressSelectionCallback else { return }
        let row = outlineView.selectedRow
        guard row >= 0, let fi = outlineView.item(atRow: row) as? FileItem, !fi.isDirectory else { return }
        sidebarDelegate?.sidebarDidSelectFile(fi.url, inNewTab: false)
    }

    private func fileIcon(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "swift":                        return "swift"
        case "html", "htm":                  return "globe"
        case "css", "scss":                  return "paintbrush"
        case "json":                         return "curlybraces"
        case "md", "markdown":               return "doc.richtext"
        case "sh", "bash", "zsh":            return "terminal"
        case "png", "jpg", "jpeg", "gif":    return "photo"
        case "pdf":                          return "doc.fill"
        case "zip", "tar", "gz":             return "archivebox"
        case "js", "ts", "jsx", "tsx":       return "chevron.left.forwardslash.chevron.right"
        case "py":                           return "text.word.spacing"
        case "rs":                           return "gearshape.2"
        case "go":                           return "arrow.right.arrow.left"
        case "yml", "yaml", "toml":          return "list.bullet.indent"
        default:                             return "doc"
        }
    }
}

// MARK: - Context menu

extension SidebarViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let row = outlineView.clickedRow
        guard row >= 0, let fi = outlineView.item(atRow: row) as? FileItem else { return }

        if !fi.isDirectory {
            let openItem = NSMenuItem(title: "Open", action: #selector(contextOpen(_:)), keyEquivalent: "")
            openItem.target = self
            menu.addItem(openItem)

            let newTabItem = NSMenuItem(title: "Open in New Tab", action: #selector(contextOpenInNewTab(_:)), keyEquivalent: "")
            newTabItem.target = self
            menu.addItem(newTabItem)

            menu.addItem(.separator())
        }

        let revealItem = NSMenuItem(title: "Reveal in Finder", action: #selector(contextRevealInFinder(_:)), keyEquivalent: "")
        revealItem.target = self
        menu.addItem(revealItem)
    }

    @objc private func contextOpen(_ sender: Any?) {
        let row = outlineView.clickedRow
        guard row >= 0, let fi = outlineView.item(atRow: row) as? FileItem, !fi.isDirectory else { return }
        sidebarDelegate?.sidebarDidSelectFile(fi.url, inNewTab: false)
    }

    @objc private func contextRevealInFinder(_ sender: Any?) {
        let row = outlineView.clickedRow
        guard row >= 0, let fi = outlineView.item(atRow: row) as? FileItem else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fi.url])
    }
}
