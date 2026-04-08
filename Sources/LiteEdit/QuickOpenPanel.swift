import AppKit

protocol QuickOpenDelegate: AnyObject {
    func quickOpenDidSelectFile(_ url: URL)
    func quickOpenDismissed()
}

final class QuickOpenPanel: NSPanel, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    weak var quickOpenDelegate: QuickOpenDelegate?

    private let searchField = NSTextField()
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let headerLabel = NSTextField(labelWithString: "")

    private var allFiles: [(url: URL, relative: String)] = []
    private var filtered: [(url: URL, relative: String)] = []

    private static let skippedDirs: Set<String> = [
        ".git", ".svn", ".hg", "node_modules", ".build", ".swiftpm",
        "Pods", "DerivedData", ".next", "__pycache__", ".cache",
        "build", "dist", ".DS_Store", ".Trash",
    ]

    init(relativeTo parent: NSWindow) {
        let panelW: CGFloat = 520
        let panelH: CGFloat = 340
        let parentFrame = parent.frame
        let x = parentFrame.midX - panelW / 2
        let y = parentFrame.maxY - panelH - 60
        let rect = NSRect(x: x, y: y, width: panelW, height: panelH)

        super.init(
            contentRect: rect,
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false

        buildUI()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        dismiss()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            dismiss()
            return
        }
        super.keyDown(with: event)
    }

    // MARK: - UI

    private func buildUI() {
        guard let cv = contentView else { return }
        cv.wantsLayer = true
        cv.layer?.backgroundColor = Theme.sidebarBg.cgColor
        cv.layer?.cornerRadius = 8
        cv.layer?.masksToBounds = true
        cv.layer?.borderColor = Theme.border.cgColor
        cv.layer?.borderWidth = 1

        searchField.placeholderString = "Search files by name..."
        searchField.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        searchField.focusRingType = .none
        searchField.isBordered = false
        searchField.backgroundColor = Theme.background
        searchField.textColor = Theme.foreground
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(searchField)

        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = Theme.border.cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(sep)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        cv.addSubview(scrollView)

        tableView.headerView = nil
        tableView.backgroundColor = Theme.sidebarBg
        tableView.rowHeight = 28
        tableView.selectionHighlightStyle = .regular
        tableView.allowsMultipleSelection = false
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.gridStyleMask = []

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("File"))
        col.isEditable = false
        tableView.addTableColumn(col)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)

        scrollView.documentView = tableView

        headerLabel.font = Theme.uiFontSmall
        headerLabel.textColor = Theme.statusText
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(headerLabel)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: cv.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 14),
            searchField.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -14),
            searchField.heightAnchor.constraint(equalToConstant: 28),

            sep.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            sep.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: sep.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: headerLabel.topAnchor, constant: -2),

            headerLabel.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 14),
            headerLabel.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -14),
            headerLabel.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -6),
            headerLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    // MARK: - Public

    func loadFiles(from rootURL: URL) {
        allFiles = []
        collectFiles(at: rootURL, root: rootURL)
        allFiles.sort { $0.relative.localizedCaseInsensitiveCompare($1.relative) == .orderedAscending }
        filtered = allFiles
        updateHeader()
        tableView.reloadData()
        if !filtered.isEmpty { tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
    }

    func activate() {
        searchField.stringValue = ""
        filtered = allFiles
        updateHeader()
        tableView.reloadData()
        if !filtered.isEmpty { tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
        makeFirstResponder(searchField)
    }

    // MARK: - File collection

    private func collectFiles(at url: URL, root: URL) {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for item in items {
            let name = item.lastPathComponent
            if Self.skippedDirs.contains(name) { continue }
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                collectFiles(at: item, root: root)
            } else {
                let rel = item.path.replacingOccurrences(of: root.path + "/", with: "")
                allFiles.append((url: item, relative: rel))
            }
        }
    }

    // MARK: - Filtering

    private func applyFilter(_ query: String) {
        if query.isEmpty {
            filtered = allFiles
        } else {
            let lower = query.lowercased()
            filtered = allFiles.filter { fuzzyMatch(lower, in: $0.relative.lowercased()) }
            filtered.sort { lhs, rhs in
                let lName = lhs.url.lastPathComponent.lowercased()
                let rName = rhs.url.lastPathComponent.lowercased()
                let lExact = lName.contains(lower)
                let rExact = rName.contains(lower)
                if lExact != rExact { return lExact }
                let lPrefix = lName.hasPrefix(lower)
                let rPrefix = rName.hasPrefix(lower)
                if lPrefix != rPrefix { return lPrefix }
                return lhs.relative.count < rhs.relative.count
            }
        }
        updateHeader()
        tableView.reloadData()
        if !filtered.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            tableView.scrollRowToVisible(0)
        }
    }

    private func fuzzyMatch(_ query: String, in text: String) -> Bool {
        var qi = query.startIndex
        var ti = text.startIndex
        while qi < query.endIndex && ti < text.endIndex {
            if query[qi] == text[ti] {
                qi = query.index(after: qi)
            }
            ti = text.index(after: ti)
        }
        return qi == query.endIndex
    }

    private func updateHeader() {
        let total = allFiles.count
        let shown = filtered.count
        if searchField.stringValue.isEmpty {
            headerLabel.stringValue = "\(total) file\(total == 1 ? "" : "s")"
        } else {
            headerLabel.stringValue = "\(shown) of \(total) file\(total == 1 ? "" : "s")"
        }
    }

    // MARK: - Actions

    private func confirmSelection() {
        let row = tableView.selectedRow
        guard row >= 0, row < filtered.count else { return }
        let file = filtered[row]
        dismiss()
        quickOpenDelegate?.quickOpenDidSelectFile(file.url)
    }

    private func dismiss() {
        orderOut(nil)
        quickOpenDelegate?.quickOpenDismissed()
    }

    @objc private func rowDoubleClicked() {
        confirmSelection()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ n: Notification) {
        applyFilter(searchField.stringValue)
    }

    func control(_ control: NSControl, textView tv: NSTextView, doCommandBy sel: Selector) -> Bool {
        if sel == #selector(insertNewline(_:)) {
            confirmSelection()
            return true
        }
        if sel == #selector(cancelOperation(_:)) {
            dismiss()
            return true
        }
        if sel == #selector(moveUp(_:)) {
            let row = max(tableView.selectedRow - 1, 0)
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            tableView.scrollRowToVisible(row)
            return true
        }
        if sel == #selector(moveDown(_:)) {
            let row = min(tableView.selectedRow + 1, filtered.count - 1)
            if row >= 0 {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                tableView.scrollRowToVisible(row)
            }
            return true
        }
        return false
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        filtered.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tv: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        guard row < filtered.count else { return nil }
        let entry = filtered[row]

        let cell = NSTableCellView()
        cell.wantsLayer = true

        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        let iconName = fileIcon(entry.url)
        icon.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        icon.contentTintColor = Theme.sidebarText
        icon.imageScaling = .scaleProportionallyDown

        let nameLabel = NSTextField(labelWithString: entry.url.lastPathComponent)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = Theme.foreground
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let pathLabel = NSTextField(labelWithString: entry.relative)
        pathLabel.font = Theme.uiFontSmall
        pathLabel.textColor = Theme.statusText
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(icon)
        cell.addSubview(nameLabel)
        cell.addSubview(pathLabel)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),

            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            pathLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -12),
            pathLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])

        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        pathLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        pathLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return cell
    }

    func tableView(_ tv: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        QuickOpenRowView()
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

// MARK: - Custom row view for themed selection

private final class QuickOpenRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        if isSelected {
            Theme.selection.setFill()
            let path = NSBezierPath(rect: bounds)
            path.fill()

            Theme.accent.withAlphaComponent(0.8).setFill()
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: 3, height: bounds.height)).fill()
        }
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle { .emphasized }
}
