//
//  PgSQLLogsSection.swift
//  AevonX
//
//  Log viewer for PostgreSQL error and general logs.
//

import SwiftUI
import AevonXCoreBridge

struct PgSQLLogsSection: View {
    let serverId: String
    @State private var logEntries: [BridgeAppLogEntry] = []
    @State private var selectedLogType: String = "error"
    @State private var logLines: Int = 100
    @State private var isLoading = false
    private let bridge = ApplicationBridge.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                Picker("Log Type", selection: $selectedLogType) {
                    Text("Error").tag("error")
                    Text("General").tag("general")
                }
                .pickerStyle(.segmented).frame(width: 200)
                Spacer()
                HStack(spacing: 4) {
                    Text("Lines:").font(.system(size: 11)).foregroundColor(.axTextMuted)
                    Picker("", selection: $logLines) {
                        Text("50").tag(50); Text("100").tag(100); Text("200").tag(200); Text("500").tag(500)
                    }.frame(width: 70)
                }
                AXRefreshButton(isLoading: isLoading) { await fetchLogs() }
            }
            .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if logEntries.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "text.alignleft").font(.system(size: 28)).foregroundColor(.axTextMuted)
                    Text("No log entries found").font(AXTypography.caption).foregroundColor(.axTextMuted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) { ForEach(logEntries) { entry in logRow(entry) } }
                        .padding(AXSpacing.sm)
                }
            }
        }
        .task { await fetchLogs() }
        .onChange(of: selectedLogType) { Task { await fetchLogs() } }
    }

    private func logRow(_ entry: BridgeAppLogEntry) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Circle().fill(levelColor(entry.level)).frame(width: 5, height: 5).padding(.top, 6)
            if let ts = entry.timestamp {
                Text(ts).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted)
                    .frame(width: 140, alignment: .leading)
            }
            Text(entry.message).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextPrimary).lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 3)
        .background(Color.axSurface.opacity(0.3)).cornerRadius(2)
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "error", "fatal": return .axError
        case "warn", "warning": return .axWarning
        case "info", "log": return .axAccentBlue
        case "notice": return .teal
        default: return .axTextMuted
        }
    }

    private func fetchLogs() async {
        isLoading = true
        let json = await bridge.getLogs(serverID: serverId, appID: "pgsql", logType: selectedLogType, lines: Int32(logLines))
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppLogEntry]>.self, from: data),
           resp.success { logEntries = resp.data ?? [] }
        isLoading = false
    }
}
