//
//  AdvancedLogView.swift
//  AevonX
//
//  Premium log viewer with syntax highlighting and filtering.
//

import SwiftUI
import AevonXCore

struct AdvancedLogView: View {
    let logs: String
    let onRefresh: () -> Void
    var isLoading: Bool = false
    
    @State private var searchText: String = ""
    @State private var autoScroll: Bool = true
    
    var filteredLines: [String] {
        let allLines = logs.components(separatedBy: .newlines)
        if searchText.isEmpty {
            return allLines
        }
        return allLines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextTertiary)
                        .font(.system(size: 12))
                    
                    TextField("Filter logs (e.g. 'error', 'GET')...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                
                Spacer()
                
                Toggle(isOn: $autoScroll) {
                    Text("Auto-scroll")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                .scaleEffect(0.8)
                
                Button(action: onRefresh) {
                    HStack(spacing: AXSpacing.xs) {
                        if isLoading {
                            ProgressView().scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundSecondary)
            
            Divider().background(Color.axBorder)
            
            // Log Content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(filteredLines.enumerated()), id: \.offset) { index, line in
                            LogLineView(line: line)
                                .id(index)
                        }
                        
                        // Bottom anchor for autoscroll
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black.opacity(0.95))
                .onChange(of: logs) { _, _ in
                    if autoScroll {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Log Line View

struct LogLineView: View {
    let line: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Text(line)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(lineColor)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var lineColor: Color {
        let upperLine = line.uppercased()
        if upperLine.contains("ERROR") || upperLine.contains("CRITICAL") || upperLine.contains("FATAL") || upperLine.contains("FAIL") {
            return .axError
        } else if upperLine.contains("WARN") || upperLine.contains("WARNING") {
            return .axWarning
        } else if upperLine.contains("INFO") {
            return .axAccentBlue
        } else if upperLine.contains("DEBUG") {
            return .axTextTertiary
        } else if upperLine.contains("HTTP") || upperLine.contains("GET ") || upperLine.contains("POST ") {
            return .axAccentGreen
        } else if line.starts(with: "===") {
            return .axTextPrimary
        }
        return .axTextSecondary
    }
}

// MARK: - Previews

#Preview {
    AdvancedLogView(logs: """
    === nginx-access.log ===
    127.0.0.1 - - [10/Oct/2023:13:55:36 +0000] "GET /index.php HTTP/1.1" 200 612 "-" "Mozilla/5.0"
    192.168.1.1 - - [10/Oct/2023:13:56:01 +0000] "POST /api/login HTTP/1.1" 401 150 "-" "Postman"
    
    === nginx-error.log ===
    2023/10/10 13:55:36 [error] 1234#0: *1 FastCGI sent in stderr: "PHP message: PHP Fatal error: Uncaught Error: Call to undefined function..."
    2023/10/10 13:57:12 [warn] 1234#0: *2 low memory limit reached
    """, onRefresh: {})
    .frame(width: 600, height: 400)
    .background(Color.axBackground)
}
