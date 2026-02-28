//
//  AuditLogSection.swift
//  AevonX
//
//  Audit Log section — auth/sudo/system logs with search & filter.
//  Uses shared AXLogTable component with flexible columns.
//

import SwiftUI
import AevonXCore

struct AuditLogSection: View {
    let serverId: String

    @State private var selectedTab = 0
    @State private var authLines: [String] = []
    @State private var sudoLines: [String] = []
    @State private var systemLines: [String] = []
    @State private var isLoading = true

    private let securityManager = SecurityManager.shared
    private let tabs = ["Auth Log", "Sudo Log", "System Log"]

    /// Columns for auth/sudo/system logs — simple: time + message
    private let logColumns: [AXLogColumn] = [
        AXLogColumn(id: "time", title: "Time", width: 140),
        AXLogColumn(id: "message", title: "Message", width: nil),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab switcher
            HStack(spacing: AXSpacing.sm) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
                    }) {
                        Text(tab)
                            .font(.system(size: 12, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? .axTextPrimary : .axTextMuted)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(selectedTab == index ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)

            Divider().background(Color.axBorder.opacity(0.3))

            switch selectedTab {
            case 0:
                AXLogTable(
                    title: "Auth Log",
                    icon: "shield.fill",
                    columns: logColumns,
                    rows: buildRows(authLines),
                    isLoading: isLoading,
                    accentColor: .axAccentBlue,
                    onRefresh: { await loadAuth() }
                )
            case 1:
                AXLogTable(
                    title: "Sudo Log",
                    icon: "person.badge.key.fill",
                    columns: logColumns,
                    rows: buildRows(sudoLines),
                    isLoading: isLoading,
                    accentColor: .axAccentPurple,
                    onRefresh: { await loadSudo() }
                )
            case 2:
                AXLogTable(
                    title: "System Log",
                    icon: "server.rack",
                    columns: logColumns,
                    rows: buildRows(systemLines),
                    isLoading: isLoading,
                    accentColor: .axAccentGreen,
                    onRefresh: { await loadSystem() }
                )
            default:
                EmptyView()
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Build Rows

    private func buildRows(_ lines: [String]) -> [AXLogRow] {
        lines.enumerated().map { index, line in
            AXLogRow(
                id: index,
                level: AXLogLevelDetector.detect(line),
                cells: [
                    "time": AXLogTimestamp.extract(line),
                    "message": line
                ],
                raw: line
            )
        }
    }

    // MARK: - Data Loading

    private func loadAll() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }
        await loadAuth()
        await loadSudo()
        await loadSystem()
    }

    private func loadAuth() async {
        let lines = await securityManager.authLog(lines: 200, serverId: serverId)
        await MainActor.run { authLines = lines }
    }

    private func loadSudo() async {
        let lines = await securityManager.sudoLog(lines: 100, serverId: serverId)
        await MainActor.run { sudoLines = lines }
    }

    private func loadSystem() async {
        let lines = await securityManager.sysLog(lines: 200, serverId: serverId)
        await MainActor.run { systemLines = lines }
    }
}
