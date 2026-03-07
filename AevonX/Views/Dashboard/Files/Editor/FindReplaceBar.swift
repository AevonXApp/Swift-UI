//
//  FindReplaceBar.swift
//  AevonX
//
//  Find & Replace bar for the code editor
//

import SwiftUI
import AevonXCore

// MARK: - Find & Replace Bar

struct FindReplaceBar: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var showReplace = false
    @State private var matchCount = 0
    @State private var currentMatch = 0
    @State private var caseSensitive = false
    @State private var wholeWord = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Find row
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
                
                TextField("Find...", text: $findText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .onChange(of: findText) { _, _ in updateMatchCount() }
                
                // Toggle options
                Button(action: { caseSensitive.toggle(); updateMatchCount() }) {
                    Text("Aa")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(caseSensitive ? .axAccentBlue : .axTextMuted)
                        .padding(3)
                        .background(caseSensitive ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Case Sensitive")
                
                Button(action: { wholeWord.toggle(); updateMatchCount() }) {
                    Text("W")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(wholeWord ? .axAccentBlue : .axTextMuted)
                        .padding(3)
                        .background(wholeWord ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                        .cornerRadius(3)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Whole Word")
                
                // Match info
                if !findText.isEmpty {
                    Text(matchCount > 0 ? "\(currentMatch)/\(matchCount)" : "No results")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(matchCount > 0 ? .axTextSecondary : .axWarning)
                        .frame(width: 55)
                }
                
                // Navigate
                Button(action: { navigateMatch(-1) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(matchCount == 0)
                
                Button(action: { navigateMatch(1) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(matchCount == 0)
                
                // Toggle replace
                Button(action: { showReplace.toggle() }) {
                    Image(systemName: showReplace ? "chevron.up.square" : "arrow.2.squarepath")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Toggle Replace")
                
                // Close
                Button(action: { viewModel.showFindReplace = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 5)
            .background(Color.axSurface)
            
            // Replace row
            if showReplace {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    
                    TextField("Replace...", text: $replaceText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                    
                    Button("Replace") { replaceCurrent() }
                        .font(.system(size: 11))
                        .disabled(matchCount == 0)
                    
                    Button("All") { replaceAll() }
                        .font(.system(size: 11))
                        .disabled(matchCount == 0)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 4)
                .background(Color.axSurface.opacity(0.8))
            }
            
            Divider().background(Color.axBorder.opacity(0.5))
        }
    }
    
    // MARK: - Match Logic
    
    private func updateMatchCount() {
        guard !findText.isEmpty else {
            matchCount = 0
            currentMatch = 0
            return
        }
        
        let content = viewModel.editorContent
        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        var count = 0
        var searchRange = content.startIndex..<content.endIndex
        
        while let range = content.range(of: findText, options: options, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<content.endIndex
        }
        
        matchCount = count
        if currentMatch == 0 && count > 0 { currentMatch = 1 }
        if currentMatch > count { currentMatch = count }
    }
    
    private func navigateMatch(_ direction: Int) {
        guard matchCount > 0 else { return }
        currentMatch += direction
        if currentMatch > matchCount { currentMatch = 1 }
        if currentMatch < 1 { currentMatch = matchCount }
    }
    
    private func replaceCurrent() {
        guard matchCount > 0, !findText.isEmpty else { return }
        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        
        if let range = viewModel.editorContent.range(of: findText, options: options) {
            viewModel.editorContent.replaceSubrange(range, with: replaceText)
            updateMatchCount()
        }
    }
    
    private func replaceAll() {
        guard matchCount > 0, !findText.isEmpty else { return }
        
        if caseSensitive {
            viewModel.editorContent = viewModel.editorContent.replacingOccurrences(of: findText, with: replaceText)
        } else {
            viewModel.editorContent = viewModel.editorContent.replacingOccurrences(
                of: findText, with: replaceText,
                options: .caseInsensitive
            )
        }
        updateMatchCount()
    }
}
