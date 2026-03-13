//
//  PHPLogsSection.swift
//  AevonX
//
//  FPM error & slow log viewer.
//

import SwiftUI
import AevonXCoreBridge

struct PHPLogsSection: View {
    let serverId: String
    @State private var logType = "error"
    @State private var logLines: Int = 100
    @State private var entries: [BridgeAppLogEntry] = []
    @State private var isLoading = false

    private let bridge = ApplicationBridge.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                Picker("Log Type", selection: $logType) {
                    Text("Error Log").tag("error")
                    Text("Access Log").tag("access")
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                Spacer()

                HStack(spacing: 4) {
                    Text("Lines:").font(.system(size: 11)).foregroundColor(.axTextMuted)
                    Picker("", selection: $logLines) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                    }
                    .frame(width: 70)
                }

                AXRefreshButton(isLoading: isLoading) { await loadLogs() }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            if isLoading {
                VStack(spacing: 1) {
                    ForEach(0..<8, id: \.self) { _ in AXSkeletonRow() }
                }
                .padding(AXSpacing.md)
                Spacer()
            } else if entries.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "text.alignleft").font(.system(size: 28)).foregroundColor(.axTextMuted)
                    Text("No log entries found").font(AXTypography.caption).foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(entries) { entry in logRow(entry) }
                    }
                    .padding(AXSpacing.sm)
                }
            }
        }
        .task { await loadLogs() }
        .onChange(of: logType) { _ in Task { await loadLogs() } }
        .onChange(of: logLines) { _ in Task { await loadLogs() } }
    }

    private func logRow(_ entry: BridgeAppLogEntry) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Circle().fill(levelColor(entry.level)).frame(width: 5, height: 5).padding(.top, 6)
            if let ts = entry.timestamp {
                Text(ts).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted).frame(width: 140, alignment: .leading)
            }
            if let status = entry.status, status > 0 {
                Text("\(status)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(statusColor(status)).frame(width: 30)
            }
            if let method = entry.method, let path = entry.path {
                Text(method).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.axAccentBlue).frame(width: 40, alignment: .leading)
                Text(path).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextPrimary).lineLimit(1)
            } else {
                Text(entry.message).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextPrimary).lineLimit(2)
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
        case "error":  return .axError
        case "warn":   return .axWarning
        case "info":   return .axAccentBlue
        case "notice": return .teal
        default:       return .axTextMuted
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

    private func loadLogs() async {
        isLoading = true
        let json = await bridge.getLogs(serverID: serverId, appID: "php-fpm", logType: logType, lines: Int32(logLines))
        if let data = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppLogEntry]>.self, from: data),
           r.success { entries = r.data ?? [] }
        isLoading = false
    }
}
