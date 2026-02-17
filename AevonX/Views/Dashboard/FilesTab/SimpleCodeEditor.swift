//
//  SimpleCodeEditor.swift
//  AevonX
//
//  Simple working text editor with syntax highlighting
//

import SwiftUI
import AppKit
import AevonXCore

// MARK: - Atom One Dark Colors

struct AtomColors {
    static let background = NSColor(red: 0.157, green: 0.173, blue: 0.204, alpha: 1)
    static let foreground = NSColor(red: 0.871, green: 0.898, blue: 0.949, alpha: 1)
    static let comment    = NSColor(red: 0.361, green: 0.388, blue: 0.439, alpha: 1)
    static let keyword    = NSColor(red: 0.776, green: 0.471, blue: 0.867, alpha: 1)
    static let string     = NSColor(red: 0.596, green: 0.765, blue: 0.475, alpha: 1)
    static let number     = NSColor(red: 0.824, green: 0.557, blue: 0.353, alpha: 1)
    static let function_  = NSColor(red: 0.380, green: 0.710, blue: 0.925, alpha: 1)
    static let operator_  = NSColor(red: 0.333, green: 0.847, blue: 0.831, alpha: 1)
}

// MARK: - Simple Code Editor

struct SimpleCodeEditor: View {
    @Binding var text: String
    let language: FileLanguage
    
    var body: some View {
        SimpleEditorWrapper(text: $text, language: language)
    }
}

// MARK: - NSView Wrapper

struct SimpleEditorWrapper: NSViewRepresentable {
    @Binding var text: String
    let language: FileLanguage
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        let scrollView = NSScrollView()
        
        // Basic setup
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = AtomColors.foreground
        textView.backgroundColor = AtomColors.background
        textView.drawsBackground = true
        textView.insertionPointColor = NSColor(red: 0.322, green: 0.710, blue: 0.925, alpha: 1)
        textView.delegate = context.coordinator
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.autoresizingMask = [.width, .height]
        
        // Set text
        textView.string = text
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.backgroundColor = AtomColors.background
        
        context.coordinator.textView = textView
        context.coordinator.language = language
        context.coordinator.highlightSyntax()
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        if textView.string != text {
            textView.string = text
            textView.textColor = AtomColors.foreground
            context.coordinator.highlightSyntax()
        }
        
        if context.coordinator.language != language {
            context.coordinator.language = language
            context.coordinator.highlightSyntax()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, language: language)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?
        var language: FileLanguage
        
        init(text: Binding<String>, language: FileLanguage) {
            _text = text
            self.language = language
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            text = textView.string
            
            // Delayed highlighting for performance
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(highlightSyntax), object: nil)
            perform(#selector(highlightSyntax), with: nil, afterDelay: 0.1)
        }
        
        @objc func highlightSyntax() {
            guard let textView = textView,
                  let storage = textView.textStorage else { return }
            
            let fullRange = NSRange(location: 0, length: storage.length)
            guard fullRange.length > 0 else { return }
            
            let content = storage.string
            
            storage.beginEditing()
            
            // Reset to base color
            storage.addAttribute(.foregroundColor, value: AtomColors.foreground, range: fullRange)
            storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
            
            // Apply syntax colors
            applyPatterns(to: storage, content: content)
            
            storage.endEditing()
        }
        
        private func applyPatterns(to storage: NSTextStorage, content: String) {
            let patterns = getPatterns()
            
            for (pattern, color) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { continue }
                let range = NSRange(location: 0, length: content.utf16.count)
                
                regex.enumerateMatches(in: content, range: range) { match, _, _ in
                    guard let match = match else { return }
                    storage.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            }
        }
        
        private func getPatterns() -> [(String, NSColor)] {
            var patterns: [(String, NSColor)] = []
            
            // Comments
            switch language {
            case .php, .javascript, .typescript, .swift, .java, .kotlin, .go, .rust, .cpp:
                patterns.append(("//.*$", AtomColors.comment))
                patterns.append(("/\\*[\\s\\S]*?\\*/", AtomColors.comment))
            case .python, .ruby, .shell, .yaml:
                patterns.append(("#.*$", AtomColors.comment))
            case .html, .xml:
                patterns.append(("<!--[\\s\\S]*?-->", AtomColors.comment))
            case .css:
                patterns.append(("/\\*[\\s\\S]*?\\*/", AtomColors.comment))
            default:
                break
            }
            
            // Strings
            patterns.append(("\"(?:[^\"\\\\]|\\\\.)*\"", AtomColors.string))
            patterns.append(("'(?:[^'\\\\]|\\\\.)*'", AtomColors.string))
            
            // Numbers
            patterns.append(("\\b\\d+\\.?\\d*\\b", AtomColors.number))
            
            // Keywords
            let keywords = getKeywords()
            if !keywords.isEmpty {
                let joined = keywords.joined(separator: "|")
                patterns.append(("\\b(\(joined))\\b", AtomColors.keyword))
            }
            
            // Functions
            patterns.append(("\\b\\w+(?=\\()", AtomColors.function_))
            
            // Operators
            patterns.append(("[=+\\-*/<>!&|^~%]+", AtomColors.operator_))
            
            return patterns
        }
        
        private func getKeywords() -> [String] {
            switch language {
            case .swift:
                return ["func","var","let","class","struct","enum","import","return","if","else","guard","switch","case","for","while","break","continue","throw","try","catch","async","await","public","private","static","override","self","nil","true","false"]
            case .javascript, .typescript:
                return ["function","const","let","var","class","return","if","else","switch","case","for","while","break","continue","throw","try","catch","async","await","this","new","true","false","null","undefined"]
            case .python:
                return ["def","class","return","if","elif","else","for","while","break","continue","pass","raise","try","except","with","import","from","lambda","True","False","None","and","or","not","self"]
            case .php:
                return ["function","class","return","if","else","switch","case","for","foreach","while","break","continue","throw","try","catch","new","echo","public","private","protected","static","true","false","null"]
            case .html:
                return []
            case .css:
                return ["important","inherit","none","auto","block","inline","flex","grid"]
            case .shell:
                return ["if","then","else","fi","for","while","do","done","case","esac","function","exit","echo","true","false"]
            default:
                return []
            }
        }
    }
}
