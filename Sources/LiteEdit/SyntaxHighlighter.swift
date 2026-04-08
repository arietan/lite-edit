import AppKit

final class SyntaxHighlighter {
    private let rules: [(NSRegularExpression, NSColor)]

    init(language: Document.Language) {
        rules = Self.buildRules(for: language)
    }

    func highlight(_ storage: NSTextStorage, in editedRange: NSRange) {
        let string = storage.string as NSString
        guard string.length > 0 else { return }

        let start = string.lineRange(for: NSRange(location: editedRange.location, length: 0)).location
        let end: Int = {
            let e = NSMaxRange(editedRange)
            let clamped = min(e, string.length)
            return NSMaxRange(string.lineRange(for: NSRange(location: max(clamped - 1, 0), length: 0)))
        }()
        let range = NSRange(location: start, length: end - start)
        guard range.length > 0 else { return }

        storage.addAttributes([
            .foregroundColor: Theme.foreground,
            .font: Theme.editorFont
        ], range: range)

        for (regex, color) in rules {
            regex.enumerateMatches(in: storage.string, options: [], range: range) { match, _, _ in
                guard let r = match?.range else { return }
                storage.addAttribute(.foregroundColor, value: color, range: r)
            }
        }
    }

    // MARK: - Rule builder

    private static func buildRules(for lang: Document.Language) -> [(NSRegularExpression, NSColor)] {
        let defs: [(String, NSColor)]
        switch lang {
        case .swift:
            defs = [
                ("//.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("\\b(import|class|struct|enum|protocol|extension|func|var|let|if|else|guard|switch|case|default|for|while|repeat|return|break|continue|throw|throws|try|catch|do|in|as|is|self|Self|super|init|deinit|static|override|private|public|internal|fileprivate|open|final|lazy|weak|unowned|mutating|async|await|actor|some|any|where|typealias|defer|indirect)\\b", Theme.keyword),
                ("\\b(String|Int|Double|Float|Bool|Array|Dictionary|Set|Optional|Result|Error|Void|Any|AnyObject|Never|Data|Date|URL|UUID)\\b", Theme.type),
                ("\\b(true|false|nil)\\b", Theme.number),
                ("\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", Theme.number),
                ("\\b([a-zA-Z_]\\w*)\\s*\\(", Theme.function),
                ("@\\w+", Theme.type),
            ]
        case .python:
            defs = [
                ("\"\"\"[\\s\\S]*?\"\"\"", Theme.string),
                ("'''[\\s\\S]*?'''", Theme.string),
                ("#.*$", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'(?:[^'\\\\]|\\\\.)*'", Theme.string),
                ("\\b(import|from|class|def|return|if|elif|else|for|while|break|continue|pass|raise|try|except|finally|with|as|yield|lambda|global|nonlocal|assert|del|in|not|and|or|is|async|await|match|case)\\b", Theme.keyword),
                ("\\b(True|False|None)\\b", Theme.number),
                ("\\b(int|float|str|bool|list|dict|set|tuple|range|print|len|super|type|object)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
                ("\\b([a-zA-Z_]\\w*)\\s*\\(", Theme.function),
                ("@\\w[\\w.]*", Theme.type),
            ]
        case .javascript, .typescript:
            defs = [
                ("//.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("`(?:[^`\\\\]|\\\\.)*`", Theme.string),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'(?:[^'\\\\]|\\\\.)*'", Theme.string),
                ("\\b(import|export|from|default|const|let|var|function|return|if|else|for|while|do|break|continue|switch|case|throw|try|catch|finally|new|delete|typeof|instanceof|in|of|class|extends|super|this|yield|async|await|static|get|set|interface|type|enum|implements)\\b", Theme.keyword),
                ("\\b(true|false|null|undefined|NaN|Infinity)\\b", Theme.number),
                ("\\b(Array|Object|String|Number|Boolean|Function|Promise|Map|Set|RegExp|Date|Error|JSON|Math|console)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", Theme.number),
                ("\\b([a-zA-Z_$][\\w$]*)\\s*\\(", Theme.function),
                ("=>", Theme.keyword),
            ]
        case .html:
            defs = [
                ("<!--[\\s\\S]*?-->", Theme.comment),
                ("\"[^\"]*\"", Theme.string),
                ("'[^']*'", Theme.string),
                ("</?[a-zA-Z][\\w-]*", Theme.keyword),
                ("/>|>", Theme.keyword),
                ("\\b[a-zA-Z-]+=", Theme.function),
            ]
        case .css:
            defs = [
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'(?:[^'\\\\]|\\\\.)*'", Theme.string),
                ("#[0-9a-fA-F]{3,8}\\b", Theme.number),
                ("\\b\\d+(\\.\\d+)?(px|em|rem|%|vh|vw|s|ms)?\\b", Theme.number),
                ("[.#][a-zA-Z_-][\\w-]*", Theme.function),
                ("@(media|import|keyframes|font-face|supports)\\b", Theme.keyword),
            ]
        case .json:
            defs = [
                ("\"(?:[^\"\\\\]|\\\\.)*\"\\s*:", Theme.function),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("\\b(true|false|null)\\b", Theme.keyword),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
            ]
        case .rust:
            defs = [
                ("//.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("\\b(fn|let|mut|const|static|struct|enum|impl|trait|type|use|mod|pub|crate|super|self|Self|where|as|in|for|while|loop|if|else|match|return|break|continue|move|ref|async|await|dyn|unsafe|extern)\\b", Theme.keyword),
                ("\\b(true|false)\\b", Theme.number),
                ("\\b(i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize|f32|f64|bool|char|str|String|Vec|Option|Result|Box|Rc|Arc|HashMap)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", Theme.number),
                ("\\b([a-zA-Z_]\\w*)\\s*[!(]", Theme.function),
            ]
        case .go:
            defs = [
                ("//.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("`[^`]*`", Theme.string),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("\\b(package|import|func|return|var|const|type|struct|interface|map|chan|go|defer|if|else|for|range|switch|case|default|break|continue|fallthrough|select|nil)\\b", Theme.keyword),
                ("\\b(true|false|iota)\\b", Theme.number),
                ("\\b(int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|byte|rune|string|bool|error|any)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
                ("\\b([a-zA-Z_]\\w*)\\s*\\(", Theme.function),
            ]
        case .markdown:
            defs = [
                ("^#{1,6}\\s+.*$", Theme.keyword),
                ("\\*\\*[^*]+\\*\\*", Theme.function),
                ("\\*[^*]+\\*", Theme.type),
                ("`[^`]+`", Theme.string),
                ("```[\\s\\S]*?```", Theme.string),
                ("^[\\-\\*]\\s", Theme.keyword),
                ("\\[([^\\]]+)\\]\\(([^)]+)\\)", Theme.type),
            ]
        case .shell:
            defs = [
                ("#.*$", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'[^']*'", Theme.string),
                ("\\b(if|then|else|elif|fi|for|while|do|done|case|esac|in|function|return|exit|local|export|source|alias)\\b", Theme.keyword),
                ("\\$\\{?[a-zA-Z_]\\w*\\}?", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
                ("\\b(echo|cd|ls|pwd|mkdir|rm|cp|mv|cat|grep|sed|awk|find|sort|chmod|curl|wget|git)\\b", Theme.function),
            ]
        case .yaml:
            defs = [
                ("#.*$", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'[^']*'", Theme.string),
                ("^[a-zA-Z_][\\w.-]*:", Theme.function),
                ("\\b(true|false|yes|no|null|~)\\b", Theme.keyword),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
            ]
        case .xml:
            defs = [
                ("<!--[\\s\\S]*?-->", Theme.comment),
                ("\"[^\"]*\"", Theme.string),
                ("'[^']*'", Theme.string),
                ("</?[a-zA-Z][\\w:._-]*", Theme.keyword),
                ("/>|>", Theme.keyword),
            ]
        case .sql:
            defs = [
                ("--.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("'(?:[^'\\\\]|\\\\.)*'", Theme.string),
                ("\\b(?i)(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|SET|DELETE|CREATE|DROP|ALTER|TABLE|JOIN|LEFT|RIGHT|INNER|ON|AS|AND|OR|NOT|IN|BETWEEN|LIKE|IS|NULL|EXISTS|HAVING|GROUP|BY|ORDER|ASC|DESC|LIMIT|OFFSET|UNION|DISTINCT|CASE|WHEN|THEN|ELSE|END|VALUES|COUNT|SUM|AVG|MIN|MAX)\\b", Theme.keyword),
                ("\\b(?i)(INT|INTEGER|BIGINT|VARCHAR|TEXT|BOOLEAN|DATE|TIMESTAMP|FLOAT|DECIMAL|SERIAL)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
            ]
        case .c, .cpp:
            defs = [
                ("//.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'(?:[^'\\\\]|\\\\.)*'", Theme.string),
                ("#\\s*(include|define|ifdef|ifndef|endif|if|else|elif|pragma)\\b.*$", Theme.type),
                ("\\b(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|inline|class|namespace|template|typename|virtual|public|private|protected|override|new|delete|this|try|catch|throw|using|nullptr|constexpr|noexcept)\\b", Theme.keyword),
                ("\\b(true|false|NULL|nullptr)\\b", Theme.number),
                ("\\b(size_t|int8_t|int16_t|int32_t|int64_t|uint8_t|uint16_t|uint32_t|uint64_t|bool|string|vector|map|set)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", Theme.number),
                ("\\b([a-zA-Z_]\\w*)\\s*\\(", Theme.function),
            ]
        case .java:
            defs = [
                ("//.*$", Theme.comment),
                ("/\\*[\\s\\S]*?\\*/", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("\\b(abstract|break|case|catch|class|continue|default|do|else|enum|extends|final|finally|for|if|implements|import|instanceof|interface|new|package|private|protected|public|return|static|super|switch|this|throw|throws|try|volatile|while|var|yield)\\b", Theme.keyword),
                ("\\b(true|false|null)\\b", Theme.number),
                ("\\b(boolean|byte|char|double|float|int|long|short|void|String|Integer|Long|Double|Object|List|Map|Set|Optional)\\b", Theme.type),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
                ("\\b([a-zA-Z_]\\w*)\\s*\\(", Theme.function),
                ("@[a-zA-Z_]\\w*", Theme.type),
            ]
        case .ruby:
            defs = [
                ("#.*$", Theme.comment),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'(?:[^'\\\\]|\\\\.)*'", Theme.string),
                ("\\b(alias|and|begin|break|case|class|def|do|else|elsif|end|ensure|false|for|if|in|module|next|nil|not|or|redo|rescue|retry|return|self|super|then|true|undef|unless|until|when|while|yield|require|include)\\b", Theme.keyword),
                (":[a-zA-Z_]\\w*", Theme.string),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
                ("@{1,2}[a-zA-Z_]\\w*", Theme.type),
            ]
        case .toml:
            defs = [
                ("#.*$", Theme.comment),
                ("\"\"\"[\\s\\S]*?\"\"\"", Theme.string),
                ("\"(?:[^\"\\\\]|\\\\.)*\"", Theme.string),
                ("'[^']*'", Theme.string),
                ("^\\s*\\[{1,2}[^\\]]*\\]{1,2}", Theme.keyword),
                ("^\\s*[a-zA-Z_][\\w.-]*\\s*=", Theme.function),
                ("\\b(true|false)\\b", Theme.number),
                ("\\b\\d+(\\.\\d+)?\\b", Theme.number),
            ]
        case .plainText:
            defs = []
        }

        return defs.compactMap { pattern, color in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { return nil }
            return (regex, color)
        }
    }
}
