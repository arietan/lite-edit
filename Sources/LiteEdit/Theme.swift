import AppKit

enum Theme {
    // Monokai-inspired palette
    static let background       = NSColor(srgbRed: 0.153, green: 0.157, blue: 0.133, alpha: 1) // #272822
    static let foreground       = NSColor(srgbRed: 0.973, green: 0.973, blue: 0.949, alpha: 1) // #F8F8F2
    static let comment          = NSColor(srgbRed: 0.459, green: 0.443, blue: 0.369, alpha: 1) // #75715E
    static let string           = NSColor(srgbRed: 0.902, green: 0.859, blue: 0.455, alpha: 1) // #E6DB74
    static let keyword          = NSColor(srgbRed: 0.976, green: 0.149, blue: 0.447, alpha: 1) // #F92672
    static let function         = NSColor(srgbRed: 0.651, green: 0.886, blue: 0.182, alpha: 1) // #A6E22E
    static let number           = NSColor(srgbRed: 0.682, green: 0.506, blue: 1.000, alpha: 1) // #AE81FF
    static let type             = NSColor(srgbRed: 0.400, green: 0.851, blue: 0.937, alpha: 1) // #66D9EF

    static let selection        = NSColor(srgbRed: 0.286, green: 0.282, blue: 0.235, alpha: 1)
    static let cursor           = NSColor(srgbRed: 0.973, green: 0.973, blue: 0.949, alpha: 1)

    static let gutterBg         = NSColor(srgbRed: 0.184, green: 0.184, blue: 0.165, alpha: 1)
    static let gutterText       = NSColor(srgbRed: 0.565, green: 0.565, blue: 0.541, alpha: 1)
    static let gutterActiveText = NSColor(srgbRed: 0.800, green: 0.800, blue: 0.780, alpha: 1)

    static let sidebarBg        = NSColor(srgbRed: 0.141, green: 0.145, blue: 0.122, alpha: 1)
    static let sidebarText      = NSColor(srgbRed: 0.800, green: 0.800, blue: 0.780, alpha: 1)

    static let tabBarBg         = NSColor(srgbRed: 0.130, green: 0.133, blue: 0.114, alpha: 1)
    static let tabActive        = background // seamless with editor
    static let tabInactive      = NSColor(srgbRed: 0.130, green: 0.133, blue: 0.114, alpha: 1)
    static let tabText          = NSColor(srgbRed: 0.550, green: 0.545, blue: 0.520, alpha: 1)
    static let tabTextActive    = NSColor(srgbRed: 0.973, green: 0.973, blue: 0.949, alpha: 1)
    static let border           = NSColor(srgbRed: 0.180, green: 0.184, blue: 0.161, alpha: 1)

    static let statusBg         = NSColor(srgbRed: 0.110, green: 0.114, blue: 0.098, alpha: 1)
    static let statusText       = NSColor(srgbRed: 0.565, green: 0.565, blue: 0.541, alpha: 1)
    static let accent           = NSColor(srgbRed: 0.976, green: 0.149, blue: 0.447, alpha: 1)

    static let findBarBg        = NSColor(srgbRed: 0.180, green: 0.184, blue: 0.161, alpha: 1)

    static let editorFont       = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let lineNumFont      = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    static let uiFont           = NSFont.systemFont(ofSize: 12, weight: .regular)
    static let uiFontSmall      = NSFont.systemFont(ofSize: 11, weight: .regular)
}
