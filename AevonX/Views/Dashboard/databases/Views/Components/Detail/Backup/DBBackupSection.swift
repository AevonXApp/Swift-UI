//
//  DBBackupSection.swift
//  AevonX
//
//  Premium backup & import section with glassmorphism cards,
//  enhanced backup listing, and progress indicators.
//

import SwiftUI
import AevonXCoreBridge
import UniformTypeIdentifiers

struct DBBackupSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    @State private var appear = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                sectionHeader
                backupStatsRow
                actionCards
                backupListCard
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await viewModel.loadBackups()
        }
        .sheet(isPresented: $viewModel.showImportSQL) {
            DBImportSQLView(viewModel: viewModel)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) { appear = true }
        }
    }

    // MARK: - Backup Stats Row (NEW)

    private var backupStatsRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
            backupStatCard(
                icon: "doc.zipper",
                label: "Total Backups",
                value: "\(viewModel.backups.count)",
                color: .axAccentBlue
            )
            backupStatCard(
                icon: "internaldrive",
                label: "Total Size",
                value: viewModel.backups.isEmpty ? "—" : viewModel.backups.reduce("") { _, b in b.size },
                color: .axAccentGreen
            )
            backupStatCard(
                icon: "clock",
                label: "Latest",
                value: viewModel.backups.first?.date?.formatted(date: .abbreviated, time: .omitted) ?? "Never",
                color: .axWarning
            )
            backupStatCard(
                icon: "calendar",
                label: "DB Size",
                value: AXFormatter.formatSizeMB(viewModel.database.size),
                color: .purple
            )
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.03), value: appear)
    }

    private func backupStatCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(AXTypography.subheadline)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(AXTypography.callout).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "externaldrive.badge.timemachine")
                .font(AXTypography.title3)
                .foregroundColor(.axAccentBlue)
            Text("Backup & Import")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
        }
    }

    // MARK: - Action Cards Grid

    private var actionCards: some View {
        HStack(spacing: AXSpacing.lg) {
            // Create Backup Card
            actionCard(
                icon: "arrow.down.doc.fill",
                iconColor: .axAccentBlue,
                title: "Create Backup",
                subtitle: "Export '\(viewModel.database.name)' to a SQL dump file",
                buttonTitle: viewModel.isCreatingBackup ? "Creating..." : "Create Backup",
                buttonColor: .axAccentBlue,
                isLoading: viewModel.isCreatingBackup,
                isDisabled: viewModel.isCreatingBackup
            ) {
                Task { await viewModel.createBackup() }
            }

            // Import SQL Card
            actionCard(
                icon: "square.and.arrow.down.fill",
                iconColor: .axAccentGreen,
                title: "Import SQL",
                subtitle: "Import .sql file or paste SQL content",
                buttonTitle: "Import SQL",
                buttonColor: .axAccentGreen,
                isLoading: false,
                isDisabled: false
            ) {
                viewModel.showImportSQL = true
            }

            // Restore from Backup Card
            actionCard(
                icon: "arrow.uturn.backward.circle.fill",
                iconColor: .axWarning,
                title: "Restore Backup",
                subtitle: "Restore database from a previous backup file",
                buttonTitle: viewModel.backups.isEmpty ? "No Backups" : "Restore",
                buttonColor: .axWarning,
                isLoading: false,
                isDisabled: viewModel.backups.isEmpty
            ) {
                if let latest = viewModel.backups.first {
                    viewModel.activeAlert = .confirmRestoreBackup(latest.id)
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.05), value: appear)
    }

    private func actionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        buttonTitle: String,
        buttonColor: Color,
        isLoading: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(AXTypography.headline)
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(title)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(2)
                }
            }

            Button(action: action) {
                HStack(spacing: AXSpacing.xs) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 14, height: 14)
                    }
                    Text(buttonTitle)
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AXSpacing.sm)
                .background(isDisabled ? Color.axTextMuted.opacity(0.3) : buttonColor)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Backup List Card

    private var backupListCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                    Text("Recent Backups")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    if !viewModel.backups.isEmpty {
                        Text("\(viewModel.backups.count)")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.full)
                    }
                }

                Spacer()

                Button {
                    Task { await viewModel.loadBackups() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)

            Divider().background(Color.axBorder)

            if viewModel.backups.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "tray")
                        .font(AXTypography.largeTitle)
                        .foregroundColor(.axTextMuted.opacity(0.4))
                    Text("No backups found")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                    Text("Create your first backup to get started")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(AXSpacing.xxl)
            } else {
                ForEach(Array(viewModel.backups.enumerated()), id: \.element.id) { index, backup in
                    backupRow(backup, index: index)
                    if index < viewModel.backups.count - 1 {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.1), value: appear)
    }

    private func backupRow(_ backup: BackupInfo, index: Int) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axAccentBlue.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "doc.zipper")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(URL(fileURLWithPath: backup.id).lastPathComponent)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(backup.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Text(backup.size)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 2)
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)

            // Actions
            HStack(spacing: AXSpacing.xs) {
                Button {
                    Task { await viewModel.downloadBackup(backup.id) }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 28, height: 28)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDownloadingBackup)

                // Backup actions — AXActionMenu
                AXActionMenu(sections: [
                    AXMenuSection("Actions", items: [
                        AXMenuItem("Download", icon: "arrow.down.circle", color: .axAccentBlue) {
                            Task { await viewModel.downloadBackup(backup.id) }
                        },
                        AXMenuItem("Copy Path", icon: "doc.on.doc", color: .cyan) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(backup.id, forType: .string)
                            GlobalToastManager.shared.showSuccess("Backup path copied")
                        },
                    ]),
                    AXMenuSection(items: [
                        AXMenuItem("Delete Backup", icon: "trash", isDestructive: true) {
                            viewModel.confirmDeleteBackup(backup.id)
                        },
                    ]),
                ], triggerIcon: "ellipsis", triggerSize: 22)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm + 2)
        .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
    }
}
