import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.applicationIconImage = NSImage(named: "AppIcon")

let delegate = AppDelegate()
app.delegate = delegate
app.run()
