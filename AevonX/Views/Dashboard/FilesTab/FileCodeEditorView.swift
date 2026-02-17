//
//  FileCodeEditorView.swift
//  AevonX
//
//  Syntax-highlighted code editor with Atom One Dark theme
//  Uses NSTextView for performance with large files
//

import SwiftUI
import AppKit
import AevonXCore

// MARK: - Atom One Dark Theme Colors

struct AtomOneDark {
    static let background = NSColor(red: 0.157, green: 0.173, blue: 0.204, alpha: 1) // #282C34
    static let foreground = NSColor(red: 0.671, green: 0.698, blue: 0.749, alpha: 1) // #ABB2BF
    static let comment    = NSColor(red: 0.361, green: 0.388, blue: 0.439, alpha: 1) // #5C6370
    static let keyword    = NSColor(red: 0.776, green: 0.471, blue: 0.867, alpha: 1) // #C678DD
    static let string     = NSColor(red: 0.596, green: 0.765, blue: 0.475, alpha: 1) // #98C379
    static let number     = NSColor(red: 0.824, green: 0.557, blue: 0.353, alpha: 1) // #D19A66
    static let function_  = NSColor(red: 0.380, green: 0.710, blue: 0.925, alpha: 1) // #61AFEF
    static let variable   = NSColor(red: 0.886, green: 0.404, blue: 0.420, alpha: 1) // #E06C75
    static let type       = NSColor(red: 0.902, green: 0.784, blue: 0.459, alpha: 1) // #E5C07B
    static let tag        = NSColor(red: 0.886, green: 0.404, blue: 0.420, alpha: 1) // #E06C75
    static let attribute  = NSColor(red: 0.824, green: 0.557, blue: 0.353, alpha: 1) // #D19A66
    static let operator_  = NSColor(red: 0.333, green: 0.847, blue: 0.831, alpha: 1) // #56B6C2
    static let lineNumber = NSColor(red: 0.361, green: 0.388, blue: 0.439, alpha: 0.6)
    static let gutterBg   = NSColor(red: 0.137, green: 0.153, blue: 0.184, alpha: 1)
    static let selection  = NSColor(red: 0.247, green: 0.271, blue: 0.325, alpha: 1) // #3E4451
    static let cursor     = NSColor(red: 0.322, green: 0.710, blue: 0.925, alpha: 1) // #528BFF
}

// MARK: - Code Editor (NSViewRepresentable)

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    let language: FileLanguage
    let isReadOnly: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        // -- Build the text system properly --
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        // Use a flexible-width container that tracks the text view
        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        // Create text view with the properly initialized container
        let textView = CodeTextView(frame: .zero, textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Appearance
        textView.appearance = NSAppearance(named: .darkAqua)
        textView.drawsBackground = true
        textView.backgroundColor = AtomOneDark.background
        textView.textColor = AtomOneDark.foreground
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.insertionPointColor = AtomOneDark.cursor
        textView.selectedTextAttributes = [
            .backgroundColor: AtomOneDark.selection,
            .foregroundColor: AtomOneDark.foreground
        ]
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // Editing behavior
        textView.isEditable = !isReadOnly
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        
        // Scroll view
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = AtomOneDark.background
        scrollView.autohidesScrollers = true
        scrollView.appearance = NSAppearance(named: .darkAqua)
        
        // Coordinator setup
        context.coordinator.textView = textView
        context.coordinator.language = language
        textView.delegate = context.coordinator
        
        // Set initial text with explicit attributes (fixes invisible text bug)
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: AtomOneDark.foreground,
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        ]
        let attributedText = NSAttributedString(string: text, attributes: attrs)
        textStorage.setAttributedString(attributedText)
        context.coordinator.applyFullHighlighting()
        
        // Line number gutter
        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = rulerView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              let textStorage = textView.textStorage else { return }
        
        // Update text if externally changed
        if textView.string != text {
            let preservedSelection = textView.selectedRange()
            
            // Set text with explicit attributes
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: AtomOneDark.foreground,
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            ]
            let attributedText = NSAttributedString(string: text, attributes: attrs)
            textStorage.setAttributedString(attributedText)
            context.coordinator.applyFullHighlighting()
            
            let safeLocation = min(preservedSelection.location, text.utf16.count)
            let safeLength = min(preservedSelection.length, text.utf16.count - safeLocation)
            textView.setSelectedRange(NSRange(location: safeLocation, length: safeLength))
        }
        
        // Update language if changed
        if context.coordinator.language != language {
            context.coordinator.language = language
            context.coordinator.applyFullHighlighting()
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: CodeEditorView
        weak var textView: NSTextView?
        var language: FileLanguage = .plainText
        private var isInternalUpdate = false
        
        init(parent: CodeEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = textView, !isInternalUpdate else { return }
            isInternalUpdate = true
            parent.text = textView.string
            
            // Debounced highlighting for performance during typing
            DispatchQueue.main.async { [weak self] in
                self?.applyFullHighlighting()
                self?.isInternalUpdate = false
            }
        }
        
        func applyFullHighlighting() {
            guard let textView = textView,
                  let storage = textView.textStorage else { return }
            
            let fullRange = NSRange(location: 0, length: storage.length)
            guard fullRange.length > 0 else { return }
            
            let content = storage.string
            
            storage.beginEditing()
            
            // Base styling
            storage.addAttribute(.foregroundColor, value: AtomOneDark.foreground, range: fullRange)
            storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
            
            // Syntax patterns
            let patterns = SyntaxPatterns.patterns(for: language)
            for pattern in patterns {
                applyPattern(pattern.regex, color: pattern.color, in: content, storage: storage)
            }
            
            storage.endEditing()
            
            // Update ruler
            if let ruler = textView.enclosingScrollView?.verticalRulerView as? LineNumberRulerView {
                ruler.needsDisplay = true
            }
        }
        
        private func applyPattern(_ pattern: String, color: NSColor, in text: String, storage: NSTextStorage) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
            let range = NSRange(location: 0, length: text.utf16.count)
            for match in regex.matches(in: text, range: range) {
                storage.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
    }
}

// MARK: - Custom Text View (Tab → Spaces)

class CodeTextView: NSTextView {
    override func insertTab(_ sender: Any?) {
        insertText("    ", replacementRange: selectedRange())
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    private weak var associatedTextView: NSTextView?
    
    init(textView: NSTextView) {
        self.associatedTextView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.ruleThickness = 44
        self.clientView = textView
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange),
            name: NSText.didChangeNotification, object: textView
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: textView.enclosingScrollView?.contentView
        )
    }
    
    required init(coder: NSCoder) { fatalError() }
    
    @objc private func textDidChange(_ n: Notification) { needsDisplay = true }
    @objc private func boundsDidChange(_ n: Notification) { needsDisplay = true }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = associatedTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }
        
        AtomOneDark.gutterBg.setFill()
        rect.fill()
        
        let visibleRect = scrollView!.contentView.bounds
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)
        
        let text = textView.string as NSString
        var lineNumber = 1
        
        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: min(visibleCharRange.location, text.length)),
                                 options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: AtomOneDark.lineNumber
        ]
        
        text.enumerateSubstrings(in: visibleCharRange, options: [.byLines, .substringNotRequired]) {
            _, substringRange, _, _ in
            
            let glyphRange = layoutManager.glyphRange(forCharacterRange: substringRange, actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
            lineRect.origin.y += textView.textContainerInset.height - visibleRect.origin.y
            
            let numStr = "\(lineNumber)" as NSString
            let size = numStr.size(withAttributes: attributes)
            let point = NSPoint(
                x: self.ruleThickness - size.width - 8,
                y: lineRect.origin.y + (lineRect.height - size.height) / 2
            )
            numStr.draw(at: point, withAttributes: attributes)
            lineNumber += 1
        }
    }
}

// MARK: - Syntax Patterns

struct SyntaxPatterns {
    struct Pattern {
        let regex: String
        let color: NSColor
    }
    
    static func patterns(for language: FileLanguage) -> [Pattern] {
        var p: [Pattern] = []
        
        // Comments
        switch language {
        case .html, .xml:
            p.append(Pattern(regex: "<!--[\\s\\S]*?-->", color: AtomOneDark.comment))
        case .css:
            p.append(Pattern(regex: "/\\*[\\s\\S]*?\\*/", color: AtomOneDark.comment))
        case .python, .ruby, .shell, .yaml, .ini, .toml, .nginx, .apache:
            p.append(Pattern(regex: "#.*$", color: AtomOneDark.comment))
        case .sql:
            p.append(Pattern(regex: "--.*$", color: AtomOneDark.comment))
            p.append(Pattern(regex: "/\\*[\\s\\S]*?\\*/", color: AtomOneDark.comment))
        default:
            p.append(Pattern(regex: "//.*$", color: AtomOneDark.comment))
            p.append(Pattern(regex: "/\\*[\\s\\S]*?\\*/", color: AtomOneDark.comment))
        }
        
        // Strings
        p.append(Pattern(regex: "\"(?:[^\"\\\\]|\\\\.)*\"", color: AtomOneDark.string))
        p.append(Pattern(regex: "'(?:[^'\\\\]|\\\\.)*'", color: AtomOneDark.string))
        p.append(Pattern(regex: "`(?:[^`\\\\]|\\\\.)*`", color: AtomOneDark.string))
        
        // Numbers
        p.append(Pattern(regex: "\\b\\d+\\.?\\d*\\b", color: AtomOneDark.number))
        
        // Language-specific keywords
        let keywords: [String]
        switch language {
        case .swift:
            keywords = ["func","var","let","class","struct","enum","protocol","import","return","if","else","guard","switch","case","default","for","while","repeat","break","continue","throw","throws","try","catch","async","await","public","private","internal","fileprivate","open","static","override","final","self","Self","nil","true","false","in","is","as","where","typealias","associatedtype","init","deinit","extension","subscript","lazy","weak","unowned","optional","required","convenience","mutating","nonmutating","inout","some","any"]
        case .javascript, .typescript:
            keywords = ["function","const","let","var","class","return","if","else","switch","case","default","for","while","do","break","continue","throw","try","catch","finally","new","delete","typeof","instanceof","in","of","import","export","from","async","await","yield","this","super","extends","implements","interface","type","enum","true","false","null","undefined","void","static","get","set","constructor"]
        case .python:
            keywords = ["def","class","return","if","elif","else","for","while","break","continue","pass","raise","try","except","finally","with","as","import","from","lambda","yield","global","nonlocal","assert","del","True","False","None","and","or","not","in","is","self","async","await"]
        case .php:
            keywords = ["function","class","return","if","else","elseif","switch","case","default","for","foreach","while","do","break","continue","throw","try","catch","finally","new","echo","print","public","private","protected","static","abstract","final","interface","extends","implements","use","namespace","require","include","true","false","null","array","isset","unset","var","const"]
        case .go:
            keywords = ["func","var","const","type","struct","interface","map","chan","return","if","else","switch","case","default","for","range","break","continue","go","defer","select","import","package","true","false","nil","make","new","append","len","cap"]
        case .rust:
            keywords = ["fn","let","mut","const","struct","enum","impl","trait","use","mod","pub","return","if","else","match","for","while","loop","break","continue","move","async","await","self","Self","super","crate","true","false","where","type","as","in","ref","unsafe","static","extern","dyn"]
        case .ruby:
            keywords = ["def","class","module","return","if","elsif","else","unless","case","when","for","while","until","do","end","begin","rescue","ensure","raise","yield","block_given","include","extend","require","attr_accessor","attr_reader","attr_writer","self","super","true","false","nil","and","or","not","in","puts","print"]
        case .html:
            keywords = []
        case .css:
            keywords = ["important","inherit","initial","unset","none","auto","block","inline","flex","grid"]
        case .shell:
            keywords = ["if","then","else","elif","fi","for","while","do","done","case","esac","function","return","exit","echo","export","source","local","readonly","declare","set","unset","shift","test","true","false","in"]
        case .sql:
            keywords = ["SELECT","FROM","WHERE","INSERT","INTO","VALUES","UPDATE","SET","DELETE","CREATE","TABLE","ALTER","DROP","INDEX","JOIN","LEFT","RIGHT","INNER","OUTER","ON","AND","OR","NOT","IN","IS","NULL","AS","ORDER","BY","GROUP","HAVING","LIMIT","OFFSET","UNION","ALL","DISTINCT","EXISTS","BETWEEN","LIKE","COUNT","SUM","AVG","MAX","MIN","PRIMARY","KEY","FOREIGN","REFERENCES","CASCADE","DEFAULT","UNIQUE","CHECK","CONSTRAINT"]
        default:
            keywords = []
        }
        
        if !keywords.isEmpty {
            let kw = keywords.joined(separator: "|")
            p.append(Pattern(regex: "\\b(\(kw))\\b", color: AtomOneDark.keyword))
        }
        
        // HTML/XML tags
        if language == .html || language == .xml || language == .php {
            p.append(Pattern(regex: "</?\\w+", color: AtomOneDark.tag))
            p.append(Pattern(regex: "/?>", color: AtomOneDark.tag))
            p.append(Pattern(regex: "\\b\\w+(?==)", color: AtomOneDark.attribute))
        }
        
        // Function calls
        if language != .html && language != .css && language != .xml {
            p.append(Pattern(regex: "\\b\\w+(?=\\()", color: AtomOneDark.function_))
        }
        
        // Types (capitalized words)
        if [.swift, .java, .kotlin, .typescript, .rust, .go].contains(language) {
            p.append(Pattern(regex: "\\b[A-Z][a-zA-Z0-9_]*\\b", color: AtomOneDark.type))
        }
        
        // Operators
        p.append(Pattern(regex: "[=+\\-*/<>!&|^~%?:]+", color: AtomOneDark.operator_))
        
        return p
    }
}
