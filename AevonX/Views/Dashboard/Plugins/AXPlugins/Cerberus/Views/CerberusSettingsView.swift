//
//  CerberusSettingsView.swift
//  AevonX
//
//  Settings tab — config backups, virtual patches, log export,
//  and raw config viewer for AXCerberus WAF.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusSettingsView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var selectedSection: CerberusSettingsSection = .backups
    @State private var vpatchToDelete: String?
    @State private var backupToRestore: String?

    var body: some View {
        VStack(spacing: 0) {
            settingsHeader
            Divider().background(Color.axDivider)
            sectionPicker
            Divider().background(Color.axDivider)
            sectionContent
        }
        .task {
            async let b: () = viewModel.loadConfigBackups()
            async let v: () = viewModel.loadVPatches()
            async let c: () = viewModel.loadModuleConfig()
            _ = await (b, v, c)
        }
        .confirmationDialog(
            L10n.Cerberus.Dialog.deleteVPatch,
            isPresented: Binding(get: { vpatchToDelete != nil }, set: { if !$0 { vpatchToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.Cerberus.Dialog.delete, role: .destructive) {
                if let id = vpatchToDelete {
                    Task { await viewModel.removeVPatch(id) }
                }
            }
        }
        .confirmationDialog(
            L10n.Cerberus.Dialog.restoreBackup,
            isPresented: Binding(get: { backupToRestore != nil }, set: { if !$0 { backupToRestore = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.Cerberus.Settings.restore, role: .destructive) {
                if let name = backupToRestore {
                    Task { await viewModel.restoreConfigBackup(name: name) }
                }
            }
        }
    }
}

// MARK: - Section Enum

private enum CerberusSettingsSection: String, CaseIterable {
    case backups, virtualPatches, logExport, rawConfig

    var label: String {
        switch self {
        case .backups:        return L10n.Cerberus.Settings.sectionBackups
        case .virtualPatches: return L10n.Cerberus.Settings.sectionVPatches
        case .logExport:      return L10n.Cerberus.Settings.sectionExport
        case .rawConfig:      return L10n.Cerberus.Settings.sectionRawConfig
        }
    }

    var icon: String {
        switch self {
        case .backups:        return "arrow.counterclockwise.circle"
        case .virtualPatches: return "bandage"
        case .logExport:      return "square.and.arrow.up"
        case .rawConfig:      return "doc.plaintext"
        }
    }
}

// MARK: - Header

private extension CerberusSettingsView {

    var settingsHeader: some View {
        HStack(spacing: AXSpacing.xl) {
            settingsHeaderIcon
            settingsHeaderText
            Spacer()
            settingsHeaderBadge
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }

    var settingsHeaderIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 26
                    )
                )
                .frame(width: 48, height: 48)
            Circle()
                .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: "gearshape.2.fill")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axAccentBlue)
        }
    }

    var settingsHeaderText: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(L10n.Cerberus.Settings.title)
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(L10n.Cerberus.Settings.subtitle)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var settingsHeaderBadge: some View {
        HStack(spacing: AXSpacing.md) {
            if viewModel.configOperationInProgress {
                ProgressView().scaleEffect(0.8)
            }
            AXBadge(
                text: "\(viewModel.configBackups.count) backups",
                color: .axAccentGreen, style: .soft
            )
        }
    }

    var sectionPicker: some View {
        HStack(spacing: AXSpacing.sm) {
            ForEach(CerberusSettingsSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSection = section }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: section.icon)
                            .font(.system(size: 11))
                        Text(section.label)
                            .font(AXTypography.caption)
                            .fontWeight(selectedSection == section ? .semibold : .regular)
                    }
                    .foregroundStyle(selectedSection == section ? Color.axAccentBlue : Color.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(selectedSection == section ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }
}

// MARK: - Section Content

private extension CerberusSettingsView {

    @ViewBuilder
    var sectionContent: some View {
        Group {
            switch selectedSection {
            case .backups:        backupsSection
            case .virtualPatches: vpatchesSection
            case .logExport:      logExportSection
            case .rawConfig:      rawConfigSection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedSection)
    }
}

// MARK: - Config Backups

private extension CerberusSettingsView {

    var backupsSection: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                backupsActions
                backupsList
            }
            .padding(AXSpacing.xl)
        }
    }

    var backupsActions: some View {
        AXCard(accentColor: .axAccentGreen) {
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(L10n.Cerberus.Settings.backupsTitle)
                        .font(AXTypography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(L10n.Cerberus.Settings.backupsDesc)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                }
                Spacer()
                AXPrimaryButton(
                    title: L10n.Cerberus.Settings.createBackup,
                    icon: "plus.circle.fill",
                    action: { Task { await viewModel.createConfigBackup() } },
                    isLoading: viewModel.configOperationInProgress
                )
            }
        }
    }

    var backupsList: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text(L10n.Cerberus.Settings.savedBackups)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextPrimary)

                if viewModel.configBackups.isEmpty {
                    emptyState(icon: "arrow.counterclockwise.circle", text: L10n.Cerberus.Settings.noBackups)
                } else {
                    ForEach(viewModel.configBackups) { backup in
                        backupRow(backup)
                        if backup.id != viewModel.configBackups.last?.id {
                            Divider().background(Color.axDivider.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    func backupRow(_ backup: WAFConfigBackup) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axAccentGreen.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "doc.zipper")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axAccentGreen)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(backup.name)
                    .font(AXTypography.monoSm)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text(formatBackupDate(backup.modTime))
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                    Text(formatBytes(backup.size))
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
            }
            Spacer()
            Button {
                backupToRestore = backup.name
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                    Text(L10n.Cerberus.Settings.restore)
                        .font(AXTypography.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.axWarning)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axWarning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.configOperationInProgress)
        }
    }
}

// MARK: - Virtual Patches

private extension CerberusSettingsView {

    var vpatchesSection: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                vpatchesHeader
                vpatchesList
            }
            .padding(AXSpacing.xl)
        }
    }

    var vpatchesHeader: some View {
        AXCard(accentColor: .axError) {
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(L10n.Cerberus.Settings.vpatchesTitle)
                        .font(AXTypography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(L10n.Cerberus.Settings.vpatchesDesc)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                }
                Spacer()
                AXBadge(
                    text: L10n.Cerberus.Badge.active(viewModel.vPatches.filter(\.enabled).count, viewModel.vPatches.count),
                    color: .axAccentGreen, style: .soft
                )
            }
        }
    }

    var vpatchesList: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text(L10n.Cerberus.Settings.activePatches)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextPrimary)

                if viewModel.vPatches.isEmpty {
                    emptyState(icon: "bandage", text: L10n.Cerberus.Settings.noVPatches)
                } else {
                    ForEach(viewModel.vPatches) { patch in
                        vpatchRow(patch)
                        if patch.id != viewModel.vPatches.last?.id {
                            Divider().background(Color.axDivider.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    func vpatchRow(_ patch: WAFVirtualPatch) -> some View {
        HStack(spacing: AXSpacing.md) {
            vpatchRowIcon(patch)
            vpatchRowInfo(patch)
            Spacer()
            vpatchRowActions(patch)
        }
    }

    func vpatchRowIcon(_ patch: WAFVirtualPatch) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill((patch.enabled ? severityColor(patch.severity) : Color.axTextMuted).opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: "bandage")
                .font(AXTypography.caption)
                .foregroundStyle(patch.enabled ? severityColor(patch.severity) : Color.axTextMuted)
        }
    }

    func vpatchRowInfo(_ patch: WAFVirtualPatch) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            HStack(spacing: AXSpacing.xs) {
                if !patch.cve.isEmpty {
                    Text(patch.cve)
                        .font(AXTypography.monoSm)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                }
                AXBadge(text: L10n.Cerberus.Alerts.filterLabel(for: patch.severity), color: severityColor(patch.severity), style: .soft)
                if !patch.enabled {
                    AXBadge(text: L10n.Status.disabled, color: .axTextMuted, style: .soft)
                }
            }
            Text(patch.description)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
                .lineLimit(1)
            HStack(spacing: AXSpacing.sm) {
                Text(patch.pathPattern)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextMuted)
                Text("→ \(patch.action)")
                    .font(AXTypography.caption2)
                    .foregroundStyle(Color.axTextMuted)
            }
        }
    }

    func vpatchRowActions(_ patch: WAFVirtualPatch) -> some View {
        Button {
            vpatchToDelete = patch.patchID
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 11))
                .foregroundStyle(Color.axError)
                .frame(width: 28, height: 28)
                .background(Color.axError.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.configOperationInProgress)
    }
}

// MARK: - Log Export

private extension CerberusSettingsView {

    var logExportSection: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                logExportCard(
                    title: L10n.Cerberus.Settings.exportAccess,
                    desc: L10n.Cerberus.Settings.exportAccessDesc,
                    icon: "arrow.up.arrow.down",
                    color: .axAccentBlue,
                    logType: "access"
                )
                logExportCard(
                    title: L10n.Cerberus.Settings.exportBlock,
                    desc: L10n.Cerberus.Settings.exportBlockDesc,
                    icon: "hand.raised.fill",
                    color: .axError,
                    logType: "block"
                )
            }
            .padding(AXSpacing.xl)
        }
    }

    func logExportCard(title: String, desc: String, icon: String, color: Color, logType: String) -> some View {
        AXCard(accentColor: color) {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(AXTypography.subheadline)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(title)
                        .font(AXTypography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(desc)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                }
                Spacer()
                AXPrimaryButton(
                    title: L10n.Cerberus.Settings.export,
                    icon: "square.and.arrow.up",
                    action: { Task { await viewModel.exportLogData(logType: logType) } },
                    isLoading: viewModel.configOperationInProgress
                )
            }
        }
    }
}

// MARK: - Raw Config

private extension CerberusSettingsView {

    var rawConfigSection: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                rawConfigHeader
                rawConfigTable
            }
            .padding(AXSpacing.xl)
        }
    }

    var rawConfigHeader: some View {
        AXCard(accentColor: .axAccentPurple) {
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(L10n.Cerberus.Settings.rawConfigTitle)
                        .font(AXTypography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(L10n.Cerberus.Settings.rawConfigDesc)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                }
                Spacer()
                AXBadge(
                    text: "\(rawConfigPairs.count) keys",
                    color: .axAccentPurple, style: .soft
                )
            }
        }
    }

    var rawConfigTable: some View {
        AXCard {
            VStack(spacing: 0) {
                if rawConfigPairs.isEmpty {
                    emptyState(icon: "doc.plaintext", text: L10n.Cerberus.Settings.noConfig)
                } else {
                    rawConfigTableHeader
                    Divider().background(Color.axDivider)
                    ForEach(rawConfigPairs, id: \.key) { pair in
                        rawConfigRow(pair)
                    }
                }
            }
        }
    }

    var rawConfigTableHeader: some View {
        HStack {
            Text(L10n.Cerberus.Settings.configKey)
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextMuted)
                .frame(width: 220, alignment: .leading)
            Divider().frame(height: 14)
            Text(L10n.Cerberus.Settings.configValue)
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextMuted)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface.opacity(0.5))
    }

    func rawConfigRow(_ pair: ConfigPair) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(pair.key)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axAccentBlue)
                    .frame(width: 220, alignment: .leading)
                Divider().frame(height: 14)
                configValueView(pair.value)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            Divider().background(Color.axDivider.opacity(0.3))
        }
    }

    @ViewBuilder
    func configValueView(_ value: String) -> some View {
        let lower = value.lowercased()
        if lower == "true" {
            HStack(spacing: AXSpacing.xxxs) {
                Circle().fill(Color.axAccentGreen).frame(width: 6, height: 6)
                Text(value)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axAccentGreen)
            }
        } else if lower == "false" {
            HStack(spacing: AXSpacing.xxxs) {
                Circle().fill(Color.axTextMuted).frame(width: 6, height: 6)
                Text(value)
                    .font(AXTypography.monoXs)
                    .foregroundStyle(Color.axTextMuted)
            }
        } else if Double(value) != nil {
            Text(value)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axWarning)
        } else {
            Text(value)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextSecondary)
        }
    }
}

// MARK: - Helpers

private extension CerberusSettingsView {

    struct ConfigPair {
        let key: String
        let value: String
    }

    var rawConfigPairs: [ConfigPair] {
        guard let config = viewModel.moduleConfig else { return [] }
        return config.keys.sorted().compactMap { key in
            guard let val = config[key] else { return nil }
            return ConfigPair(key: key, value: "\(val)")
        }
    }

    func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .axError
        case "high":     return .axError
        case "medium":   return .axWarning
        case "low":      return .axAccentGreen
        default:         return .axTextMuted
        }
    }

    private static let isoFmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFmtBasic = ISO8601DateFormatter()
    private static let backupDateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    func formatBackupDate(_ iso: String) -> String {
        guard let date = Self.isoFmt.date(from: iso) ?? Self.isoFmtBasic.date(from: iso) else { return iso }
        return Self.backupDateFmt.string(from: date)
    }

    func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.axTextMuted)
            Text(text)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxl)
    }
}
