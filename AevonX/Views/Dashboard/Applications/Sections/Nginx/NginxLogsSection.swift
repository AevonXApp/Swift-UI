//
//  NginxLogsSection.swift
//  AevonX
//
//  Log viewer with access/error tabs.
//

import SwiftUI
import AevonXCoreBridge

struct NginxLogsSection: View {
    let serverId: String

    @State private var logEntries: [BridgeAppLogEntry] = []
    @State private var selectedLogType: String = "access"
    @State private var logLines: Int = 100
    @State private var isLoading = false

    private let bridge = ApplicationBridge.shared

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                // Log type picker
                Picker("Log Type", selection: $selectedLogType) {
                    Text(L10n.Apps.accessLog).tag("access")
                    Text(L10n.Apps.errorLog).tag("error")
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                Spacer()

                // Lines count
                HStack(spacing: 4) {
                    Text(L10n.Apps.lines)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: $logLines) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                    }
                    .frame(width: 70)
                }

                // Refresh
                AXRefreshButton(isLoading: isLoading) {
                    await fetchLogs()
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            // Log entries
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if logEntries.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 28))
                        .foregroundColor(.axTextMuted)
                    Text(L10n.Apps.noLogEntriesFound)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(logEntries) { entry in
                            logRow(entry)
                        }
                    }
                    .padding(AXSpacing.sm)
                }
            }
        }
        .task { await fetchLogs() }
        .onChange(of: selectedLogType) { _ in
            Task { await fetchLogs() }
        }
    }

    private func logRow(_ entry: BridgeAppLogEntry) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            // Level indicator
            Circle()
                .fill(levelColor(entry.level))
                .frame(width: 5, height: 5)
                .padding(.top, 6)

            // Timestamp
            if let ts = entry.timestamp {
                Text(ts)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 140, alignment: .leading)
            }

            // Status (access log)
            if let status = entry.status, status > 0 {
                Text("\(status)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor(status))
                    .frame(width: 30)
            }

            // Method + Path (access log)
            if let method = entry.method, let path = entry.path {
                Text(method)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 40, alignment: .leading)

                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            } else {
                // Error log message
                Text(entry.message)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 3)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(2)
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "error":   return .axError
        case "warn":    return .axWarning
        case "info":    return .axAccentBlue
        case "notice":  return .teal
        default:        return .axTextMuted
        }
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .axSuccess
        case 300..<400: return .axAccentBlue
        case 400..<500: return .axWarning
        case 500...:    return .axError
        default:        return .axTextMuted
        }
    }

    private func fetchLogs() async {
        isLoading = true
        let json = await bridge.getLogs(
            serverID: serverId,
            appID: "nginx",
            logType: selectedLogType,
            lines: Int32(logLines)
        )
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppLogEntry]>.self, from: data),
           resp.success {
            logEntries = resp.data ?? []
        }
        isLoading = false
    }
}
