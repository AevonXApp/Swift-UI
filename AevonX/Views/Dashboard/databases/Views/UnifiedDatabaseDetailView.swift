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
                .font(AXTypography.title2).fontWeight(.semibold)
                .foregroundColor(brandColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(databaseType.displayName)
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)

                Text("Engine Management")
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            // Service status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(serviceStatus == "active" ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(serviceStatus == "active" ? "Running" : "Stopped")
                    .font(AXTypography.subheadline)
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
                    .font(AXTypography.title2)
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
                            .font(AXTypography.subheadline)
                            .frame(width: 20)

                        Text(section.rawValue)
                            .font(AXTypography.callout).fontWeight(selectedSection == section ? .semibold : .regular)

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
                    .font(AXTypography.callout)
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
                    .font(AXTypography.callout).fontWeight(.semibold)
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
                    .font(AXTypography.callout).fontWeight(.semibold)
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
                .font(AXTypography.callout).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)

            if configContent.isEmpty {
                Text("No configuration loaded")
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextMuted)
                    .padding()
            } else {
                ScrollView {
                    Text(configContent)
                        .font(AXTypography.monoMd)
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
                .font(AXTypography.callout).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)

            Text("Log viewer for \(databaseType.displayName)")
                .font(AXTypography.callout)
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
                .font(AXTypography.callout).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)

            infoRow("Current Version", version)

            Text("Version management for \(databaseType.displayName)")
                .font(AXTypography.callout)
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
                    .font(AXTypography.caption)
                Text(title)
                    .font(AXTypography.subheadline)
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
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
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Text(value)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Data Loading

    private func loadEngineData() async {
        isLoading = true
        defer { isLoading = false }

        let bridge = DatabasesBridge.shared
        let engineKey = databaseType.rawValue

        // Version via bridge
        let versionCmd = bridge.getVersionCmd(engine: engineKey)
        let versionResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: versionCmd)
        let trimmed = versionResult.trimmingCharacters(in: .whitespacesAndNewlines)
        version = trimmed.isEmpty ? "—" : trimmed

        // Status via bridge
        let statusCmd = bridge.statusCmd(engine: engineKey)
        let statusResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: statusCmd)
        serviceStatus = statusResult.trimmingCharacters(in: .whitespacesAndNewlines).contains("active") ? "active" : "inactive"
    }

    private func controlService(_ action: String) async {
        let bridge = DatabasesBridge.shared
        let engineKey = databaseType.rawValue

        let cmd: String
        switch action {
        case "start":   cmd = bridge.startCmd(engine: engineKey)
        case "stop":    cmd = bridge.stopCmd(engine: engineKey)
        case "restart": cmd = bridge.restartCmd(engine: engineKey)
        default:        return
        }

        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)

        // Re-check status
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await loadEngineData()
    }
}
