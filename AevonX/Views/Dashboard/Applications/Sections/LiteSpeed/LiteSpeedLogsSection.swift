//
//  LiteSpeedLogsSection.swift
//  AevonX
//
//  Access & error log viewer for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedLogsSection: View {
    let serverId: String

    @State private var logEntries: [BridgeAppLogEntry] = []
    @State private var isLoading = false
    @State private var selectedLogType = "access"
    @State private var lineCount = 100

    private let bridge = ApplicationBridge.shared
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                Picker("Log Type", selection: $selectedLogType) {
                    Text(L10n.Apps.accessLog).tag("access")
                    Text(L10n.Apps.errorLog).tag("error")
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Spacer()

                Picker("Lines", selection: $lineCount) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("500").tag(500)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                AXRefreshButton(isLoading: isLoading) {
                    await loadLogs()
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.3))

            Divider().background(Color.axBorder.opacity(0.2))

            // Log entries
            if isLoading {
                VStack { Spacer(); ProgressView("Loading logs..."); Spacer() }
            } else if logEntries.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Spacer()
                    Image(systemName: "text.alignleft").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
                    Text(L10n.Apps.noLogEntries).font(AXTypography.callout).foregroundColor(.axTextMuted)
                    Spacer()
                }.frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(logEntries.enumerated()), id: \.offset) { _, entry in
                            HStack(alignment: .top, spacing: AXSpacing.sm) {
                                Circle()
                                    .fill(logLevelColor(entry.level))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 5)

                                if let ts = entry.timestamp, !ts.isEmpty {
                                    Text(ts)
                                        .font(AXTypography.monoXs)
                                        .foregroundColor(.axTextMuted)
                                        .frame(width: 140, alignment: .leading)
                                }

                                Text(entry.message)
                                    .font(AXTypography.monoSm)
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(3)
                                    .textSelection(.enabled)

                                Spacer()
                            }
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 4)
                            .background(Color.axSurface.opacity(0.15))
                        }
                    }
                    .padding(.vertical, AXSpacing.sm)
                }
            }
        }
        .task { await loadLogs() }
        .onChange(of: selectedLogType) { Task { await loadLogs() } }
        .onChange(of: lineCount) { Task { await loadLogs() } }
    }

    private func loadLogs() async {
        isLoading = true
        let json = await bridge.getLogs(serverID: serverId, appID: "litespeed", logType: selectedLogType, lines: Int32(lineCount))
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppLogEntry]>.self, from: data),
           resp.success {
            logEntries = resp.data ?? []
        }
        isLoading = false
    }

    private func logLevelColor(_ level: String?) -> Color {
        switch level?.lowercased() {
        case "error", "crit", "alert", "emerg": return .axError
        case "warn", "warning": return .axWarning
        case "info", "notice": return .axAccentBlue
        default: return .axTextMuted
        }
    }
}
