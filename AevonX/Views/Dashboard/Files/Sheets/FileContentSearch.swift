//
//  FileContentSearch.swift
//  AevonX
//
//  Content search (grep) sheet — search inside file contents
//  Uses `grep -rnl` on the server
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Content Search Sheet

struct FileContentSearchSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var query = ""
    @State private var results: [(path: String, line: Int, content: String)] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var caseSensitive = false
    @State private var searchRegex = false
    @State private var maxResults = 50
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.axAccentBlue)
                
                Text("Search in File Contents")
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.axBackgroundSecondary)
            
            Divider().background(Color.axBorder)
            
            // Search bar
            VStack(spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextMuted)
                    
                    TextField("Search query...", text: $query)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                    
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                            .scaleEffect(0.6)
                    }
                    
                    Button("Search") { performSearch() }
                        .buttonStyle(AXPrimaryButtonStyle())
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                
                HStack(spacing: AXSpacing.md) {
                    Toggle("Case Sensitive", isOn: $caseSensitive)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                    
                    Toggle("Regex", isOn: $searchRegex)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                    
                    Spacer()
                    
                    Text("in \(viewModel.currentPath)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }
            }
            .padding()
            
            Divider().background(Color.axBorder)
            
            // Results
            if let error = errorMessage {
                Text(error)
                    .font(AXTypography.caption)
                    .foregroundColor(.axWarning)
                    .padding()
            }
            
            if results.isEmpty && !isSearching {
                AXPlaceholder(
                    icon: "doc.text.magnifyingglass",
                    title: "Search File Contents",
                    subtitle: "Uses grep to search inside files on the server",
                    iconColor: .axTextMuted
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axAccentBlue)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(result.path)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: AXSpacing.xs) {
                                        Text("L\(result.line)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.axAccentBlue)
                                        
                                        Text(result.content.trimmingCharacters(in: .whitespaces))
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.axTextSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                // Open file
                                Button(action: {
                                    dismiss()
                                    let fakeFile = RemoteFileItem(
                                        name: (result.path as NSString).lastPathComponent,
                                        path: result.path,
                                        isDirectory: false,
                                        size: 0,
                                        permissions: FilePermissions(numeric: 644),
                                        owner: "", group: "", modifiedDate: Date()
                                    )
                                    viewModel.openFileEditor(fakeFile)
                                }) {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.axAccentBlue)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            
                            Divider().background(Color.axBorder.opacity(0.3))
                        }
                    }
                }
            }
            
            // Footer
            if !results.isEmpty {
                Divider().background(Color.axBorder)
                HStack {
                    Text("\(results.count) results")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.axBackgroundSecondary)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
    }
    
    // MARK: - Perform Search
    
    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        results = []
        
        Task {
            do {
                let cmd = FilesBridge.shared.searchContentCmd(
                    query: trimmed,
                    path: viewModel.currentPath,
                    caseSensitive: caseSensitive,
                    useRegex: searchRegex,
                    maxResults: maxResults
                )

                let json = await SSHBridge.shared.executeAsyncJSON(serverID: viewModel.serverId, command: cmd)
                let result = SSHResult.parse(json)
                
                if result.isSuccess {
                    let lines = result.stdout.components(separatedBy: "\n").filter { !$0.isEmpty }
                    var parsed: [(path: String, line: Int, content: String)] = []
                    
                    for line in lines.prefix(maxResults) {
                        // Format: /path/to/file:lineNum:content
                        let parts = line.split(separator: ":", maxSplits: 2)
                        if parts.count >= 3 {
                            let path = String(parts[0])
                            let lineNum = Int(parts[1]) ?? 0
                            let content = String(parts[2])
                            parsed.append((path: path, line: lineNum, content: content))
                        }
                    }
                    
                    results = parsed
                } else if !result.stderr.isEmpty {
                    errorMessage = result.stderr
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }
}
