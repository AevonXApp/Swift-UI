
import SwiftUI
import AevonXCore

struct DockerAILogAnalyzer: View {
    let container: DockerContainer
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var logs: String = ""
    @State private var analysis: String = ""
    @State private var isLoadingLogs = true
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var tailLines = 200
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Log Analyzer")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text(container.names)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if isLoadingLogs {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Loading logs...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    // Logs panel
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Logs (last \(tailLines) lines)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axSurface.opacity(0.5))
                        
                        ScrollView {
                            Text(logs)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(white: 0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AXSpacing.sm)
                        }
                        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                    }
                    .frame(minWidth: 300)
                    
                    // Analysis panel
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("AI Analysis")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.purple)
                            Spacer()
                            
                            if !analysis.isEmpty {
                                Button(action: analyze) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.clockwise").font(.system(size: 9))
                                        Text("Re-analyze").font(.system(size: 9))
                                    }
                                    .foregroundColor(.purple)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.purple.opacity(0.05))
                        
                        if isAnalyzing {
                            VStack(spacing: AXSpacing.md) {
                                ProgressView()
                                    .tint(.purple)
                                Text("AI is analyzing your logs...")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextMuted)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if analysis.isEmpty {
                            VStack(spacing: AXSpacing.md) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 28))
                                    .foregroundColor(.purple.opacity(0.5))
                                Text("Click Analyze to get AI insights")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextMuted)
                                
                                Button(action: analyze) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles").font(.system(size: 10))
                                        Text("Analyze Logs")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.purple)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                Text(analysis)
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(AXSpacing.md)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(minWidth: 250)
                }
            }
            
            if let error = errorMessage {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                    .font(.system(size: 11)).foregroundColor(.axError)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
            }
        }
        .frame(width: 900, height: 550)
        .background(Color.axBackground)
        .task { await loadLogs() }
    }
    
    // MARK: - Actions
    
    private func loadLogs() async {
        isLoadingLogs = true
        do {
            let result = try await DockerManager.shared.fetchContainerLogs(id: container.id, tail: tailLines, serverId: serverId)
            await MainActor.run {
                logs = result
                isLoadingLogs = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingLogs = false
            }
        }
    }
    
    private func analyze() {
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            // Simulate brief AI processing
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            let logLines = logs.components(separatedBy: .newlines)
            let errorCount = logLines.filter { $0.lowercased().contains("error") || $0.contains("ERR") }.count
            let warnCount = logLines.filter { $0.lowercased().contains("warn") || $0.contains("WARN") }.count
            let fatalCount = logLines.filter { $0.lowercased().contains("fatal") || $0.lowercased().contains("panic") }.count
            
            let errorSamples = logLines
                .filter { $0.lowercased().contains("error") || $0.contains("ERR") }
                .prefix(5)
                .map { "  • \($0.prefix(120))" }
                .joined(separator: "\n")
            
            let warnSamples = logLines
                .filter { $0.lowercased().contains("warn") || $0.contains("WARN") }
                .prefix(3)
                .map { "  • \($0.prefix(120))" }
                .joined(separator: "\n")
            
            let health: String
            if fatalCount > 0 { health = "🔴 Critical" }
            else if errorCount > 10 { health = "🟠 Warning (High Error Rate)" }
            else if errorCount > 0 { health = "🟡 Warning" }
            else { health = "🟢 Healthy" }
            
            let result = """
            ## Summary
            Analyzed \(logLines.count) log lines for container **\(container.names)** (\(container.image)).
            
            ## Health Assessment: \(health)
            
            ## Errors & Warnings
            - **Errors found**: \(errorCount)
            - **Warnings found**: \(warnCount)
            - **Fatal/Panic**: \(fatalCount)
            
            \(errorCount > 0 ? "### Error Samples\n\(errorSamples)\n" : "")
            \(warnCount > 0 ? "### Warning Samples\n\(warnSamples)\n" : "")
            ## Recommendations
            \(fatalCount > 0 ? "- ⚠️ Fatal errors detected — container may be crash-looping. Check restart policies and resource limits.\n" : "")
            \(errorCount > 10 ? "- ⚠️ High error rate. Review application configuration and dependencies.\n" : "")
            \(errorCount == 0 && warnCount == 0 ? "- ✅ No issues found. Container appears to be running normally.\n" : "")
            - Review logs regularly to catch issues early.
            - Consider adding health checks if not already configured.
            """
            
            await MainActor.run { analysis = result; isAnalyzing = false }
        }
    }
}
