//
//  UnifiedDatabaseDetailView.swift
//  AevonX
//
//  Database engine management view — shows service control, configuration,
//  logs, and version management for any DatabaseType engine.
//

import SwiftUI
import AevonXCoreBridge

struct UnifiedDatabaseDetailView: View {
    let databaseType: DatabaseType
    let serverId: String
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: EngineSection = .overview
    @State private var isLoading = true
    @State private var serviceStatus: String = "unknown"
    @State private var configContent: String = ""
    @State private var version: String = "—"

    enum EngineSection: String, CaseIterable, Identifiable {
        case overview   = "Overview"
        case config     = "Configuration"
        case logs       = "Logs"
        case versions   = "Versions"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview:  return "gauge.with.dots.needle.33percent"
            case .config:    return "gearshape"
            case .logs:      return "doc.text"
            case .versions:  return "shippingbox"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 0) {
                // Sidebar
                sidebar
                    .frame(width: 200)

                Divider().background(Color.white.opacity(0.1))

                // Content
                ScrollView {
                    contentForSection
                        .padding(24)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.axBackground)
        .task {
            await loadEngineData()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: databaseType.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(brandColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(databaseType.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text("Engine Management")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            // Service status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(serviceStatus == "active" ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(serviceStatus == "active" ? "Running" : "Stopped")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(serviceStatus == "active" ? .green : .axTextMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill((serviceStatus == "active" ? Color.green : Color.gray).opacity(0.1))
            )

            Button(action: { onBack?() ?? dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.axSurface)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(EngineSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: section.icon)
                            .font(.system(size: 12))
                            .frame(width: 20)

                        Text(section.rawValue)
                            .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))

                        Spacer()
                    }
                    .foregroundColor(selectedSection == section ? .white : .axTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedSection == section ? brandColor.opacity(0.2) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.axSurface.opacity(0.5))
    }

    // MARK: - Content Router

    @ViewBuilder
    private var contentForSection: some View {
        if isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading \(databaseType.displayName) data…")
                    .font(.system(size: 13))
                    .foregroundColor(.axTextMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch selectedSection {
            case .overview:  overviewSection
            case .config:    configSection
            case .logs:      logsSection
            case .versions:  versionsSection
            }
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Service Control
            VStack(alignment: .leading, spacing: 12) {
                Label("Service Control", systemImage: "power")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: 12) {
                    serviceButton("Start", icon: "play.fill", color: .green) {
                        await controlService("start")
                    }
                    serviceButton("Stop", icon: "stop.fill", color: .red) {
                        await controlService("stop")
                    }
                    serviceButton("Restart", icon: "arrow.clockwise", color: .orange) {
                        await controlService("restart")
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.axSurface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
            )

            // Info Grid
            VStack(alignment: .leading, spacing: 12) {
                Label("Engine Info", systemImage: "info.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                infoRow("Engine", databaseType.displayName)
                infoRow("Version", version)
                infoRow("Type", databaseType.isRelational ? "Relational (SQL)" : "NoSQL")
                infoRow("Status", serviceStatus == "active" ? "Running" : "Stopped")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.axSurface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
            )
        }
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Configuration", systemImage: "gearshape")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            if configContent.isEmpty {
                Text("No configuration loaded")
                    .font(.system(size: 13))
                    .foregroundColor(.axTextMuted)
                    .padding()
            } else {
                ScrollView {
                    Text(configContent)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                )
                .frame(maxHeight: 400)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Logs

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Service Logs", systemImage: "doc.text")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            Text("Log viewer for \(databaseType.displayName)")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Versions

    private var versionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Version Management", systemImage: "shippingbox")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            infoRow("Current Version", version)

            Text("Version management for \(databaseType.displayName)")
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Helpers

    private var brandColor: Color {
        databaseType.brandColor
    }

    private func serviceButton(_ title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Data Loading

    private func loadEngineData() async {
        isLoading = true
        defer { isLoading = false }

        // Load version via SSH
        let sid = serverId
        let versionCmd: String
        switch databaseType {
        case .mysql, .mariadb: versionCmd = "mysql --version 2>/dev/null | awk '{print $3}'"
        case .postgresql:      versionCmd = "psql --version 2>/dev/null | awk '{print $3}'"
        case .redis:           versionCmd = "redis-server --version 2>/dev/null | awk '{print $3}' | tr -d 'v='"
        case .mongodb:         versionCmd = "mongod --version 2>/dev/null | head -1 | awk '{print $3}' | tr -d 'v'"
        case .elasticsearch:   versionCmd = "curl -s localhost:9200 2>/dev/null | grep number | head -1 | awk -F'\"' '{print $4}'"
        default:               versionCmd = "echo unknown"
        }

        let versionResult = await SSHBridge.shared.executeAsync(serverID: sid, command: versionCmd)
        let trimmed = versionResult.trimmingCharacters(in: .whitespacesAndNewlines)
        version = trimmed.isEmpty ? "—" : trimmed

        // Check service status
        let statusCmd: String
        switch databaseType {
        case .mysql:           statusCmd = "systemctl is-active mysql 2>/dev/null || systemctl is-active mysqld 2>/dev/null"
        case .mariadb:         statusCmd = "systemctl is-active mariadb 2>/dev/null"
        case .postgresql:      statusCmd = "systemctl is-active postgresql 2>/dev/null"
        case .redis:           statusCmd = "systemctl is-active redis-server 2>/dev/null || systemctl is-active redis 2>/dev/null"
        case .mongodb:         statusCmd = "systemctl is-active mongod 2>/dev/null"
        case .elasticsearch:   statusCmd = "systemctl is-active elasticsearch 2>/dev/null"
        default:               statusCmd = "echo unknown"
        }

        let statusResult = await SSHBridge.shared.executeAsync(serverID: sid, command: statusCmd)
        serviceStatus = statusResult.trimmingCharacters(in: .whitespacesAndNewlines).contains("active") ? "active" : "inactive"
    }

    private func controlService(_ action: String) async {
        let serviceName: String
        switch databaseType {
        case .mysql:           serviceName = "mysql"
        case .mariadb:         serviceName = "mariadb"
        case .postgresql:      serviceName = "postgresql"
        case .redis:           serviceName = "redis-server"
        case .mongodb:         serviceName = "mongod"
        case .elasticsearch:   serviceName = "elasticsearch"
        default:               return
        }

        let cmd = "sudo systemctl \(action) \(serviceName) 2>&1"
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)

        // Re-check status
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await loadEngineData()
    }
}
