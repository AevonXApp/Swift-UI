//
//  NodeJSLogsSection.swift
//  AevonX
//
//  Enhanced log viewer for PM2 processes with process selection,
//  line count control, flush, and error highlighting.
//

import SwiftUI
import AevonXCoreBridge

struct NodeJSLogsSection: View {
    let serverId: String
    let hasPM2: Bool
    let processes: [PM2Process]

    @State private var selectedProcess: String = ""
    @State private var logLines: [String] = []
    @State private var lineCount: Int = 100
    @State private var isLoading = false
    @State private var autoRefresh = false
    @State private var refreshTimer: Timer?

    private let processService = NodeJSProcessService()
    private let lineCounts = [50, 100, 200, 500]

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if !hasPM2 || processes.isEmpty {
                AXPlaceholder(
                    icon: "doc.text",
                    title: "No Logs Available",
                    subtitle: "PM2 process logs will appear here when processes are running"
                )
            } else {
                controlsCard
                logViewerCard
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
        }
    }

    // MARK: - Controls

    private var controlsCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Section icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#06B6D4").opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#06B6D4"))
                }
                // Process picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Process")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: $selectedProcess) {
                        Text("Select…").tag("")
                        ForEach(processes) { p in
                            Text(p.name).tag(p.name)
                        }
                    }
                    .frame(width: 160)
                    .onChange(of: selectedProcess) { _, _ in
                        Task { await loadLogs() }
                    }
                }

                // Line count
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lines")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: $lineCount) {
                        ForEach(lineCounts, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .frame(width: 80)
                    .onChange(of: lineCount) { _, _ in
                        Task { await loadLogs() }
                    }
                }

                Spacer()

                // Auto-refresh toggle
                HStack(spacing: 4) {
                    Text("Auto")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                    Toggle("", isOn: $autoRefresh)
                        .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                        .frame(width: 36)
                        .onChange(of: autoRefresh) { _, newValue in
                            if newValue {
                                startAutoRefresh()
                            } else {
                                refreshTimer?.invalidate()
                            }
                        }
                }

                // Actions
                Button {
                    Task { await loadLogs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 28, height: 28)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await flushLogs() }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.axError)
                        .frame(width: 28, height: 28)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Log Viewer

    private var logViewerCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.axTextSecondary.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.axTextSecondary)
                        }
                        Text(selectedProcess.isEmpty ? "Logs" : "\(selectedProcess) Logs")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text("\(logLines.count) lines")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }

                if logLines.isEmpty && !isLoading {
                    Text(selectedProcess.isEmpty ? "Select a process to view logs" : "No logs available")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(Array(logLines.enumerated()), id: \.offset) { index, line in
                                HStack(alignment: .top, spacing: AXSpacing.sm) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                        .frame(width: 36, alignment: .trailing)

                                    Text(line)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(logLineColor(line))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                }
                                .padding(.vertical, 1)
                                .padding(.horizontal, 4)
                                .background(
                                    isErrorLine(line) ? Color.axError.opacity(0.05) : Color.clear
                                )
                            }
                        }
                    }
                    .frame(minHeight: 300, maxHeight: 500)
                    .padding(AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func logLineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("err") || lower.contains("fatal") {
            return .axError
        } else if lower.contains("warn") {
            return .axWarning
        } else if lower.contains("info") {
            return .axAccentBlue
        } else if lower.contains("debug") {
            return .axTextMuted
        }
        return .axTextSecondary
    }

    private func isErrorLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("error") || lower.contains("fatal") || lower.contains("exception")
    }

    // MARK: - Actions

    private func loadLogs() async {
        guard !selectedProcess.isEmpty else { return }
        isLoading = true
        do {
            let logs = try await processService.getProcessLogs(name: selectedProcess, lines: lineCount, serverId: serverId)
            logLines = logs.components(separatedBy: .newlines).filter { !$0.isEmpty }
        } catch {
            logLines = ["Failed to load logs: \(error.localizedDescription)"]
        }
        isLoading = false
    }

    private func flushLogs() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; pm2 flush \"\(selectedProcess)\" 2>&1",
            serverId: serverId
        )
        GlobalToastManager.shared.showSuccess("Logs flushed for \(selectedProcess)")
        logLines = []
    }

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { await loadLogs() }
        }
    }
}
