//
//  FileCodeEditorView.swift
//  AevonX
//
//  Code editor: SwiftUI TextEditor (guaranteed text display) +
//  SyntaxBridge for syntax highlighting via NSTextView introspection.
//
//  ARCHITECTURE:
//    TextEditor is the reliable foundation — Apple's own implementation
//    always shows text correctly. SyntaxBridge is a zero-size NSViewRepresentable
//    placed in the TextEditor's .background() that crawls the view hierarchy
//    to find the underlying NSTextView and applies colored attributes to its
//    NSTextStorage on every text/language change. This gives us working text
//    editing AND syntax highlighting without NSViewRepresentable being the
//    primary editor (which consistently broke).
//

import SwiftUI
import AppKit
import ObjectiveC
import AevonXCoreBridge

// MARK: - Code Editor View (SwiftUI)

struct CodeEditorView: View {
    @Binding var text: String
    let language: FileLanguage
    let isReadOnly: Bool
    /// Called when the user presses ⌘S inside the editor.
    var onSave: (() -> Void)?

    private var lineCount: Int {
        max(1, text.components(separatedBy: "\n").count)
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Line count gutter ───────────────────────────────────────────
            LineGutterView(lineCount: lineCount)
                .frame(width: 50)
                .background(Color(hex: "#1A1A1A"))

            Rectangle()
                .fill(Color(hex: "#272727"))
                .frame(width: 1)

            // ── Editor ──────────────────────────────────────────────────────
            Group {
                if isReadOnly {
                    ScrollView(.vertical) {
                        Text(verbatim: text)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                    }
                } else {
                    TextEditor(text: $text)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        // SyntaxBridge sits behind the editor; its NSView
                        // introspects the hierarchy to find our NSTextView
                        .background(
                            SyntaxBridge(text: text, language: language, onSave: onSave)
                        )
                }
            }
            .background(Color(hex: "#121212"))
        }
        .background(Color(hex: "#121212"))
    }
}

// MARK: - Line Gutter

private struct LineGutterView: View {
    let lineCount: Int

    var body: some View {
        // Single Text with all line numbers joined by newlines — same
        // line height as the editor font, so alignment is close.
        Text((1...lineCount).map { "\($0)" }.joined(separator: "\n"))
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundColor(Color(hex: "#636366"))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 10)
            .padding(.trailing, 8)
            .padding(.leading, 4)
    }
}

// MARK: - Syntax Highlighting Bridge

/// Zero-size NSViewRepresentable that finds the TextEditor's NSTextView
/// via view-hierarchy traversal, applies syntax-colored attributes,
/// and swizzles `keyDown:` on the NSTextView's class to intercept ⌘S.
private struct SyntaxBridge: NSViewRepresentable {
    let text:     String
    let language: FileLanguage
    var onSave:   (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> HunterView {
        let v = HunterView()
        v.onFound = { [weak c = context.coordinator] tv in
            c?.textView = tv
            CmdSSwizzler.swizzleOnce(cls: type(of: tv))
        }
        return v
    }

    func updateNSView(_ nsView: HunterView, context: Context) {
        // Keep the save action reference on the HunterView
        nsView.onSave = onSave
        // Retry finding the textView on every update
        if context.coordinator.textView == nil {
            nsView.hunt()
        }
        // Store save closure on the NSTextView via associated object
        if let tv = context.coordinator.textView {
            CmdSSwizzler.setAction(on: tv, action: onSave)
        }
        guard let tv = context.coordinator.textView,
              let storage = tv.textStorage else { return }
        Highlighter.apply(text: text, language: language, to: storage)
    }

    // MARK: Coordinator
    final class Coordinator {
        weak var textView: NSTextView?
    }

    // MARK: HunterView — traverses hierarchy to find NSTextView
    final class HunterView: NSView {
        var onFound: ((NSTextView) -> Void)?
        var onSave: (() -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            hunt()
        }

        func hunt() {
            guard let found = findTextView(startingFrom: self) else { return }
            onFound?(found)
        }

        /// Walk up to a common ancestor, then search all subviews.
        private func findTextView(startingFrom view: NSView) -> NSTextView? {
            var cursor: NSView? = view.superview
            while let v = cursor {
                if let tv = deepSearch(v, exclude: view) { return tv }
                cursor = v.superview
            }
            return nil
        }

        private func deepSearch(_ view: NSView, exclude: NSView) -> NSTextView? {
            if view === exclude { return nil }
            if let tv = view as? NSTextView { return tv }
            for sub in view.subviews {
                if let found = deepSearch(sub, exclude: exclude) { return found }
            }
            return nil
        }
    }
}

// MARK: - ⌘S via Method Swizzle on keyDown:

/// File-level associated-object key (stable pointer).
private var axSaveActionKey: UInt8 = 0

/// Box to wrap a Swift closure as an ObjC associated object.
private final class AXSaveBox: NSObject {
    let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
}

/// Swizzles `keyDown:` on the NSTextView's actual class (whatever Apple
/// private subclass it is) to intercept ⌘S.  The bonk sound proves that
/// `keyDown:` IS reached, so this is the correct interception point.
private enum CmdSSwizzler {
    private static var swizzledClasses = Set<String>()
    /// Original IMP stored per class name.
    private static var origIMPs: [String: IMP] = [:]

    static func setAction(on textView: NSTextView, action: (() -> Void)?) {
        objc_setAssociatedObject(
            textView, &axSaveActionKey,
            action.map { AXSaveBox($0) },
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    static func swizzleOnce(cls: AnyClass) {
        let className = String(cString: class_getName(cls))
        guard !swizzledClasses.contains(className) else { return }
        swizzledClasses.insert(className)

        let sel = #selector(NSResponder.keyDown(with:))
        guard let original = class_getInstanceMethod(cls, sel) else { return }
        let origIMP = method_getImplementation(original)
        origIMPs[className] = origIMP

        let block: @convention(block) (NSObject, NSEvent) -> Void = { obj, event in
            // Check for ⌘S (command only, no shift/option/control)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .command, event.charactersIgnoringModifiers == "s" {
                if let box = objc_getAssociatedObject(obj, &axSaveActionKey) as? AXSaveBox {
                    box.action()
                    return // consumed — no bonk
                }
            }
            // Call original keyDown:
            if let imp = origIMPs[className] {
                typealias Fn = @convention(c) (NSObject, Selector, NSEvent) -> Void
                unsafeBitCast(imp, to: Fn.self)(obj, sel, event)
            }
        }

        method_setImplementation(original, imp_implementationWithBlock(block))
    }
}

// MARK: - Syntax Highlighter

private enum Highlighter {

    static func apply(text: String, language: FileLanguage, to storage: NSTextStorage) {
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }

        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        storage.beginEditing()
        // Base: white text
        storage.addAttribute(.foregroundColor, value: NSColor.white, range: full)
        storage.addAttribute(.font,            value: font,          range: full)

        // Universal tokens
        pat(#""[^"\\]*(?:\\.[^"\\]*)*""#,       .systemGreen,  text, storage, full)
        pat(#"'[^'\\]*(?:\\.[^'\\]*)*'"#,       .systemGreen,  text, storage, full)
        pat(#"\b\d+(\.\d+)?\b"#,                .systemOrange, text, storage, full)
        pat(#"//[^\n]*"#,                        .systemGray,   text, storage, full)
        pat(#"/\*[\s\S]*?\*/"#,                  .systemGray,   text, storage, full)
        pat(#"<!--[\s\S]*?-->"#,                 .systemGray,   text, storage, full)

        // Language
        switch language {
        case .swift:
            pat(swiftKW,                         .systemPurple, text, storage, full)
            pat(#"\b[A-Z][a-zA-Z0-9_]*\b"#,     .systemCyan,   text, storage, full)
        case .javascript, .typescript:
            pat(jsKW,                            .systemPurple, text, storage, full)
            pat(#"\b[A-Z][a-zA-Z0-9_]*\b"#,     .systemCyan,   text, storage, full)
            pat(#"`[^`]*`"#,                     .systemGreen,  text, storage, full)
        case .python:
            pat(pyKW,                            .systemPurple, text, storage, full)
            pat(#"@\w+"#,                        .systemCyan,   text, storage, full)
        case .php:
            pat(phpKW,                           .systemPurple, text, storage, full)
            pat(#"\$[a-zA-Z_][a-zA-Z0-9_]*"#,   .systemRed,    text, storage, full)
        case .html, .xml:
            pat(#"</?[a-zA-Z][a-zA-Z0-9]*"#,    .systemRed,    text, storage, full)
            pat(#"\b[a-zA-Z-]+(?==)"#,           .systemOrange, text, storage, full)
        case .css:
            pat(#"[.#:][a-zA-Z][a-zA-Z0-9_-]*"#, .systemOrange, text, storage, full)
            pat(#"\b[a-zA-Z-]+(?=\s*:)"#,       .systemCyan,   text, storage, full)
            pat(#"@[a-zA-Z-]+"#,                 .systemPurple, text, storage, full)
        case .shell:
            pat(shellKW,                         .systemPurple, text, storage, full)
            pat(#"\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?"#, .systemRed, text, storage, full)
        case .json:
            pat(#""[^"]*"(?=\s*:)"#,             .systemCyan,   text, storage, full)
            pat(#"\b(true|false|null)\b"#,       .systemPurple, text, storage, full)
        case .yaml:
            pat(#"^[a-zA-Z_][a-zA-Z0-9_.]*(?=\s*:)"#, .systemCyan, text, storage, full)
            pat(#"\b(true|false|yes|no|null)\b"#, .systemPurple, text, storage, full)
        case .sql:
            pat(sqlKW,                           .systemPurple, text, storage, full)
        case .go:
            pat(goKW,                            .systemPurple, text, storage, full)
            pat(#"\b[A-Z][a-zA-Z0-9_]*\b"#,     .systemCyan,   text, storage, full)
        case .rust:
            pat(rustKW,                          .systemPurple, text, storage, full)
        case .java, .kotlin:
            pat(javaKW,                          .systemPurple, text, storage, full)
            pat(#"@[a-zA-Z]+"#,                  .systemCyan,   text, storage, full)
        case .cLang, .cpp:
            pat(cKW,                             .systemPurple, text, storage, full)
        case .nginx, .apache:
            pat(nginxKW,                         .systemPurple, text, storage, full)
            pat(#"\$[a-zA-Z_][a-zA-Z0-9_]*"#,   .systemRed,    text, storage, full)
        case .ini, .toml:
            pat(#"^\[[^\]]+\]"#,                 .systemCyan,   text, storage, full)
            pat(#"^[a-zA-Z_][a-zA-Z0-9_.]*(?=\s*=)"#, .systemGreen, text, storage, full)
        default: break
        }
        storage.endEditing()
    }

    private static func pat(_ pattern: String, _ color: NSColor,
                            _ text: String, _ storage: NSTextStorage, _ range: NSRange) {
        guard let rx = try? NSRegularExpression(pattern: pattern,
                                                options: [.anchorsMatchLines]) else { return }
        for m in rx.matches(in: text, range: range) {
            let r = m.range
            if r.location != NSNotFound && NSMaxRange(r) <= storage.length {
                storage.addAttribute(.foregroundColor, value: color, range: r)
            }
        }
    }

    // MARK: Keyword Patterns

    private static let swiftKW  = #"\b(func|var|let|class|struct|enum|protocol|extension|import|return|if|else|guard|for|while|switch|case|break|continue|default|do|try|catch|throw|throws|async|await|self|super|init|deinit|true|false|nil|private|public|internal|fileprivate|open|static|override|mutating|weak|unowned|lazy|some|any|in|is|as|where|typealias|subscript|get|set|willSet|didSet|@Published|@State|@Binding|@ObservedObject|@StateObject|@EnvironmentObject|@MainActor|@escaping|@discardableResult|@available|@objc)\b"#
    private static let jsKW     = #"\b(function|var|let|const|class|return|if|else|for|while|do|switch|case|break|continue|default|try|catch|finally|throw|new|this|import|export|from|async|await|typeof|instanceof|in|of|true|false|null|undefined|void|delete|yield|super|static|extends|type|interface|enum)\b"#
    private static let pyKW     = #"\b(def|class|return|if|elif|else|for|while|import|from|try|except|finally|raise|with|as|in|not|and|or|is|lambda|yield|pass|break|continue|global|nonlocal|True|False|None|self|async|await)\b"#
    private static let phpKW    = #"\b(function|class|return|if|else|elseif|for|foreach|while|switch|case|break|continue|try|catch|throw|new|echo|print|public|private|protected|static|abstract|final|interface|trait|use|namespace|require|include|true|false|null|self|parent)\b"#
    private static let shellKW  = #"\b(if|then|else|elif|fi|for|do|done|while|until|case|esac|function|return|exit|echo|export|local|source|alias)\b"#
    private static let sqlKW    = #"\b(SELECT|FROM|WHERE|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|DROP|ALTER|TABLE|JOIN|LEFT|RIGHT|INNER|ON|AND|OR|NOT|NULL|IS|IN|LIKE|ORDER|BY|GROUP|HAVING|LIMIT|UNION|DISTINCT|AS|CASE|WHEN|THEN|ELSE|END|COUNT|SUM|AVG|MAX|MIN)\b"#
    private static let goKW     = #"\b(func|var|const|type|struct|interface|map|chan|return|if|else|for|range|switch|case|default|break|continue|go|defer|select|import|package|make|new|append|len|true|false|nil|error|string|int|bool|byte)\b"#
    private static let rustKW   = #"\b(fn|let|mut|const|type|struct|enum|impl|trait|return|if|else|for|while|loop|match|use|pub|self|super|crate|mod|async|await|true|false|Some|None|Ok|Err)\b"#
    private static let javaKW   = #"\b(class|interface|enum|extends|implements|return|if|else|for|while|do|switch|case|break|continue|try|catch|finally|throw|throws|new|this|super|import|package|public|private|protected|static|final|abstract|void|int|long|double|float|boolean|String|var|val|fun|when|object|companion|data|sealed|suspend)\b"#
    private static let cKW      = #"\b(int|char|float|double|void|bool|short|long|const|static|struct|enum|typedef|sizeof|return|if|else|for|while|do|switch|case|break|continue|class|public|private|protected|virtual|override|template|namespace|using|new|delete|nullptr|true|false|NULL|auto)\b"#
    private static let nginxKW  = #"\b(server|location|listen|root|index|include|error_page|return|rewrite|proxy_pass|proxy_set_header|upstream|events|http|worker_processes|keepalive_timeout|sendfile|gzip|ssl|ssl_certificate|add_header|access_log|error_log|try_files|deny|allow|fastcgi_pass|if|map)\b"#
}
