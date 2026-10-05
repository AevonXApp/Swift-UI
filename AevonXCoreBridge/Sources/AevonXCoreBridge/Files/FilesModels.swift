//
//  FilesModels.swift
//  AevonXCoreBridge
//
//  Core model types for SSH file management.
//  Migrated from AevonXCore to enable Go-backed file operations.
//

import Foundation

// MARK: - Remote File Item

/// Represents a file or directory on the remote server
public struct RemoteFileItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let isSymlink: Bool
    public let symlinkTarget: String?
    public let size: Int64
    public let permissions: FilePermissions
    public let owner: String
    public let group: String
    public let modifiedDate: Date
    public let isHidden: Bool

    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        isSymlink: Bool = false,
        symlinkTarget: String? = nil,
        size: Int64,
        permissions: FilePermissions,
        owner: String,
        group: String,
        modifiedDate: Date,
        isHidden: Bool = false
    ) {
        self.id = path
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.isSymlink = isSymlink
        self.symlinkTarget = symlinkTarget
        self.size = size
        self.permissions = permissions
        self.owner = owner
        self.group = group
        self.modifiedDate = modifiedDate
        self.isHidden = isHidden
    }

    /// File extension (lowercase, no dot)
    public var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    /// Human-readable file size
    public var formattedSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Detect the programming language from file extension
    public var language: FileLanguage {
        FileLanguage.detect(from: fileExtension)
    }

    /// SF Symbol icon name for the file type
    public var iconName: String {
        if isDirectory { return "folder.fill" }
        if isSymlink { return "link" }
        switch fileExtension {
        case "html", "htm": return "doc.text.magnifyingglass"
        case "css", "scss", "sass", "less": return "paintbrush"
        case "js", "ts", "jsx", "tsx": return "doc.plaintext"
        case "json": return "doc.text"
        case "md", "markdown": return "doc.richtext"
        case "sh", "bash", "zsh", "fish": return "terminal"
        case "log": return "doc.text.below.ecg"
        case "conf", "ini", "env", "yaml", "yml", "toml": return "gearshape"
        case "php": return "p.circle"
        case "py": return "p.circle.fill"
        case "go": return "g.circle"
        case "swift": return "swift"
        case "rb": return "r.circle"
        case "rs": return "r.circle.fill"
        case "java", "kt": return "j.circle"
        case "c", "cpp", "h", "hpp": return "c.circle"
        case "sql": return "cylinder"
        case "xml", "plist": return "chevron.left.forwardslash.chevron.right"
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "ico": return "photo"
        case "zip", "tar", "gz", "bz2", "xz", "7z": return "doc.zipper"
        case "pdf": return "doc.text.fill"
        case "key", "pem", "crt", "cer": return "lock.shield"
        default: return "doc"
        }
    }
}

// MARK: - File Language Detection

/// Supported programming languages for syntax highlighting
public enum FileLanguage: String, Sendable {
    case swift, python, javascript, typescript, html, css, php, ruby, go
    case rust, java, kotlin, cLang, cpp, shell, sql, json, yaml, xml
    case markdown, dockerfile, nginx, apache, ini, toml, log, plainText

    /// Detect language from file extension
    public static func detect(from ext: String) -> FileLanguage {
        switch ext {
        case "swift": return .swift
        case "py", "pyw": return .python
        case "js", "mjs", "cjs": return .javascript
        case "ts", "tsx": return .typescript
        case "html", "htm": return .html
        case "css", "scss", "sass", "less": return .css
        case "php": return .php
        case "rb": return .ruby
        case "go": return .go
        case "rs": return .rust
        case "java": return .java
        case "kt", "kts": return .kotlin
        case "c", "h": return .cLang
        case "cpp", "hpp", "cc", "cxx": return .cpp
        case "sh", "bash", "zsh", "fish": return .shell
        case "sql": return .sql
        case "json": return .json
        case "yaml", "yml": return .yaml
        case "xml", "plist", "svg": return .xml
        case "md", "markdown": return .markdown
        case "conf": return .nginx
        case "ini", "env": return .ini
        case "toml": return .toml
        case "log": return .log
        default: return .plainText
        }
    }

    /// Display name
    public var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .html: return "HTML"
        case .css: return "CSS"
        case .php: return "PHP"
        case .ruby: return "Ruby"
        case .go: return "Go"
        case .rust: return "Rust"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .cLang: return "C"
        case .cpp: return "C++"
        case .shell: return "Shell"
        case .sql: return "SQL"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .xml: return "XML"
        case .markdown: return "Markdown"
        case .dockerfile: return "Dockerfile"
        case .nginx: return "Nginx"
        case .apache: return "Apache"
        case .ini: return "INI"
        case .toml: return "TOML"
        case .log: return "Log"
        case .plainText: return "Plain Text"
        }
    }
}

// MARK: - File Permissions

/// Represents Unix file permissions with both numeric and symbolic formats
public struct FilePermissions: Hashable, Sendable {
    /// Numeric mode (e.g. 755, 644)
    public let numeric: Int

    /// Symbolic string (e.g. "-rwxr-xr-x")
    public let symbolic: String

    /// File type prefix character
    public let typeChar: Character

    public init(numeric: Int, symbolic: String) {
        self.numeric = numeric
        self.symbolic = symbolic
        self.typeChar = symbolic.first ?? "-"
    }

    /// Initialize from numeric mode and type
    public init(numeric: Int, isDirectory: Bool = false, isSymlink: Bool = false) {
        self.numeric = numeric
        self.typeChar = isDirectory ? "d" : (isSymlink ? "l" : "-")
        self.symbolic = Self.numericToSymbolic(numeric, typeChar: self.typeChar)
    }

    /// Parse permissions from `ls -la` symbolic string (e.g. "drwxr-xr-x")
    public static func fromSymbolic(_ str: String) -> FilePermissions {
        let numeric = symbolicToNumeric(str)
        return FilePermissions(numeric: numeric, symbolic: str)
    }

    /// Parse permissions from stat numeric output (e.g. "755")
    public static func fromNumeric(_ value: Int, isDirectory: Bool = false, isSymlink: Bool = false) -> FilePermissions {
        return FilePermissions(numeric: value, isDirectory: isDirectory, isSymlink: isSymlink)
    }

    // MARK: - Permission Queries

    public var ownerRead: Bool { (numeric / 100) & 4 != 0 }
    public var ownerWrite: Bool { (numeric / 100) & 2 != 0 }
    public var ownerExecute: Bool { (numeric / 100) & 1 != 0 }

    public var groupRead: Bool { ((numeric / 10) % 10) & 4 != 0 }
    public var groupWrite: Bool { ((numeric / 10) % 10) & 2 != 0 }
    public var groupExecute: Bool { ((numeric / 10) % 10) & 1 != 0 }

    public var othersRead: Bool { (numeric % 10) & 4 != 0 }
    public var othersWrite: Bool { (numeric % 10) & 2 != 0 }
    public var othersExecute: Bool { (numeric % 10) & 1 != 0 }

    /// Human-readable description (e.g. "Read & Write", "Read Only", "Full Access")
    public var humanDescription: String {
        let owner = (numeric / 100)
        switch owner {
        case 7: return "Full Access (rwx)"
        case 6: return "Read & Write (rw-)"
        case 5: return "Read & Execute (r-x)"
        case 4: return "Read Only (r--)"
        case 3: return "Write & Execute (-wx)"
        case 2: return "Write Only (-w-)"
        case 1: return "Execute Only (--x)"
        default: return "No Access (---)"
        }
    }

    /// Create new permissions with a specific bit toggled
    public func toggling(owner: Int? = nil, group: Int? = nil, others: Int? = nil) -> FilePermissions {
        let o = owner ?? (numeric / 100)
        let g = group ?? ((numeric / 10) % 10)
        let t = others ?? (numeric % 10)
        let newNumeric = o * 100 + g * 10 + t
        return FilePermissions(numeric: newNumeric, isDirectory: typeChar == "d", isSymlink: typeChar == "l")
    }

    /// Formatted numeric string (e.g. "0755")
    public var numericString: String {
        String(format: "%03d", numeric)
    }

    // MARK: - Conversion Helpers

    private static func symbolicToNumeric(_ str: String) -> Int {
        guard str.count >= 10 else { return 644 }
        let chars = Array(str)

        func triplet(_ r: Character, _ w: Character, _ x: Character) -> Int {
            var val = 0
            if r == "r" { val += 4 }
            if w == "w" { val += 2 }
            if x == "x" || x == "s" || x == "t" { val += 1 }
            return val
        }

        let owner = triplet(chars[1], chars[2], chars[3])
        let group = triplet(chars[4], chars[5], chars[6])
        let others = triplet(chars[7], chars[8], chars[9])

        return owner * 100 + group * 10 + others
    }

    private static func numericToSymbolic(_ num: Int, typeChar: Character) -> String {
        func triplet(_ val: Int) -> String {
            let r = (val & 4) != 0 ? "r" : "-"
            let w = (val & 2) != 0 ? "w" : "-"
            let x = (val & 1) != 0 ? "x" : "-"
            return r + w + x
        }

        let owner = triplet(num / 100)
        let group = triplet((num / 10) % 10)
        let others = triplet(num % 10)

        return String(typeChar) + owner + group + others
    }
}
