//
//  PluginLogViewerComponent.swift
//  AevonX
//
//  Streaming/static log output viewer with auto-scroll,
//  search, and severity-based coloring.
//

import SwiftUI
import AevonXCore

public struct PluginLogViewerComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var logLines: [LogLine] = []
    @State private var searchText = ""
    @State private var autoScroll = true
    @State private var refreshTimer: Timer?

    struct LogLine: Identifiable {
        let id = UUID()
        let text: String
        let severity: Severity

        enum Severity { case info, warning, error, debug }

        var color: Color {
            switch severity {
            case .error:   return .axError
            case .warning: return .axWarning
            case .debug:   return .axTextMuted
            case .info:    return .axTextSecondary
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    TextField("Search logs...", text: $searchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 4)
                .frame(width: 180)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))

                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.to.line.compact" : "arrow.down.to.line")
                        .font(.system(size: 11))
                        .foregroundColor(autoScroll ? .axAccentBlue : .axTextMuted)
                }
                .buttonStyle(.plain)
                .help("Auto-scroll")

                Button(action: { Task { await loadLogs() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)

                Button(action: { logLines = [] }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)

                Text("\(filteredLines.count) lines")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)

            Divider().opacity(0.3)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredLines) { line in
                            HStack(spacing: AXSpacing.sm) {
                                Text(line.text)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(line.color)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, 2)
                            .background(line.severity == .error ? Color.axError.opacity(0.05) : Color.clear)
                            .id(line.id)
                        }
                    }
                }
                .onChange(of: logLines.count) { _, _ in
                    if autoScroll, let last = filteredLines.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .background(Color.axBackground)

            if vm.isLoading {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView().scaleEffect(0.6)
                    Text("Loading logs...")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .padding(.vertical, AXSpacing.xs)
            }
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .task { await loadLogs() }
        .onAppear { startAutoRefresh() }
        .onDisappear { refreshTimer?.invalidate() }
    }

    private var filteredLines: [LogLine] {
        guard !searchText.isEmpty else { return logLines }
        return logLines.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    private func loadLogs() async {
        guard let ds = plugin.dataSource else { return }
        let command = HookPluginCommand(type: ds.type ?? .coreCmd, action: ds.action, payload: ds.payload, timeout: 15)
        await vm.execute(command: command, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

        if let output = vm.resultOutput {
            logLines = output.components(separatedBy: "\n").filter { !$0.isEmpty }.map { line in
                let severity: LogLine.Severity
                let lower = line.lowercased()
                if lower.contains("error") || lower.contains("fatal") || lower.contains("critical") {
                    severity = .error
                } else if lower.contains("warn") {
                    severity = .warning
                } else if lower.contains("debug") || lower.contains("trace") {
                    severity = .debug
                } else {
                    severity = .info
                }
                return LogLine(text: line, severity: severity)
            }
        }
    }

    private func startAutoRefresh() {
        guard let interval = plugin.dataSource?.refreshInterval, interval > 0 else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { await loadLogs() }
        }
    }
}
