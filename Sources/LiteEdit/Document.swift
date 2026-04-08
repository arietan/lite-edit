import Foundation

final class Document {
    var fileURL: URL?
    var content: String
    var isModified: Bool = false
    var language: Language
    var cursorPosition: Int = 0
    private var savedContent: String

    init(fileURL: URL? = nil, content: String = "", language: Language = .plainText) {
        self.fileURL = fileURL
        self.content = content
        self.language = language
        self.savedContent = content
    }

    var displayName: String { fileURL?.lastPathComponent ?? "Untitled" }
    var title: String { isModified ? "\(displayName) •" : displayName }

    func markModified() {
        isModified = content != savedContent
    }

    func markSaved() {
        savedContent = content
        isModified = false
    }

    static func open(url: URL) throws -> Document {
        let text = try String(contentsOf: url, encoding: .utf8)
        return Document(fileURL: url, content: text, language: detectLanguage(for: url))
    }

    func save() throws {
        guard let url = fileURL else { return }
        try content.write(to: url, atomically: true, encoding: .utf8)
        markSaved()
    }

    func save(to url: URL) throws {
        fileURL = url
        language = Document.detectLanguage(for: url)
        try save()
    }

    // MARK: - Language

    enum Language: String, CaseIterable {
        case swift, python, javascript, typescript, html, css, json, markdown
        case rust, go, c, cpp, java, ruby, shell, xml, yaml, sql, toml, plainText

        var displayName: String {
            switch self {
            case .swift:      return "Swift"
            case .python:     return "Python"
            case .javascript: return "JavaScript"
            case .typescript: return "TypeScript"
            case .html:       return "HTML"
            case .css:        return "CSS"
            case .json:       return "JSON"
            case .markdown:   return "Markdown"
            case .rust:       return "Rust"
            case .go:         return "Go"
            case .c:          return "C"
            case .cpp:        return "C++"
            case .java:       return "Java"
            case .ruby:       return "Ruby"
            case .shell:      return "Shell"
            case .xml:        return "XML"
            case .yaml:       return "YAML"
            case .sql:        return "SQL"
            case .toml:       return "TOML"
            case .plainText:  return "Plain Text"
            }
        }
    }

    static func detectLanguage(for url: URL) -> Language {
        switch url.pathExtension.lowercased() {
        case "swift":                          return .swift
        case "py", "pyw":                      return .python
        case "js", "jsx", "mjs", "cjs":       return .javascript
        case "ts", "tsx":                      return .typescript
        case "html", "htm":                    return .html
        case "css", "scss", "less":            return .css
        case "json":                           return .json
        case "md", "markdown":                 return .markdown
        case "rs":                             return .rust
        case "go":                             return .go
        case "c", "h":                         return .c
        case "cpp", "hpp", "cc", "cxx", "hxx": return .cpp
        case "java":                           return .java
        case "rb":                             return .ruby
        case "sh", "bash", "zsh", "fish":      return .shell
        case "xml", "plist":                   return .xml
        case "yml", "yaml":                    return .yaml
        case "sql":                            return .sql
        case "toml":                           return .toml
        default:                               return .plainText
        }
    }
}
