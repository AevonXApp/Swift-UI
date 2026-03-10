//
//  BackupSection.swift
//  AevonX
//
//  Per-site backup and restore section
//

import SwiftUI
import AevonXCoreBridge

struct BackupSection: View {
    @ObservedObject var viewModel: BackupViewModel
    @State private var selectedType: SiteBackupType = .full
    @State private var confirmDelete: SiteBackupInfo?
    @State private var confirmRestore: SiteBackupInfo?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Backup & Restore", icon: "archivebox.fill")

                // Create Backup
                AXConfigCard(icon: "plus.circle.fill", title: "Create Backup", subtitle: "Create a new backup of this website") {
                    VStack(spacing: AXSpacing.md) {
                        Picker("Backup Type", selection: $selectedType) {
                            ForEach(SiteBackupType.allCases) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedType.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.axTextPrimary)
                                Text(backupDescription(selectedType))
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextTertiary)
                            }
                            Spacer()
                            Button(action: { Task { await viewModel.createBackup(type: selectedType) } }) {
                                HStack(spacing: 4) {
                                    if viewModel.isCreatingBackup {
                                        ProgressView().scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "arrow.down.circle")
                                    }
                                    Text("Create Now")
                                }
                                .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(viewModel.isCreatingBackup)
                        }

                        if !viewModel.backupProgress.isEmpty {
                            HStack(spacing: AXSpacing.sm) {
                                ProgressView().scaleEffect(0.7)
                                Text(viewModel.backupProgress)
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextSecondary)
                            }
                        }
                    }
                }

                // Backup List
                AXConfigCard(icon: "list.bullet", title: "Backups (\(viewModel.backups.count))", subtitle: "Existing backups for this website") {
                    if viewModel.backups.isEmpty {
                        AXPlaceholder(icon: "archivebox", title: "No backups found. Create your first backup above.")
                    } else {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(viewModel.backups) { backup in
                                HStack {
                                    Image(systemName: backup.type.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(backup.type.color)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(backup.filename)
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(.axTextPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: AXSpacing.sm) {
                                            Text(backup.size)
                                                .font(.system(size: 10))
                                                .foregroundColor(.axTextTertiary)
                                            Text("•")
                                                .font(.system(size: 10))
                                                .foregroundColor(.axTextMuted)
                                            Text(backup.relativeDate)
                                                .font(.system(size: 10))
                                                .foregroundColor(.axTextTertiary)
                                        }
                                    }
                                    Spacer()
                                    Button("Restore") { confirmRestore = backup }
                                        .buttonStyle(.bordered)
                                        .controlSize(.mini)
                                    Button(action: { confirmDelete = backup }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.axError)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(AXSpacing.sm)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }

                // Cleanup
                HStack {
                    Spacer()
                    Button(action: { Task { await viewModel.deleteOldBackups(olderThanDays: 30) } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash.circle")
                            Text("Delete backups older than 30 days")
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .tint(.axWarning)
                    .controlSize(.small)
                }

                // Error
                if let error = viewModel.errorMessage {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.axError)
                        Text(error).font(.system(size: 12)).foregroundColor(.axError)
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axError.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadBackups() } }
        .alert("Restore Backup?", isPresented: .init(get: { confirmRestore != nil }, set: { if !$0 { confirmRestore = nil } })) {
            Button("Restore", role: .destructive) {
                if let b = confirmRestore { Task { await viewModel.restoreBackup(b) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will overwrite current files. A safety backup will be created first.")
        }
        .alert("Delete Backup?", isPresented: .init(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let b = confirmDelete { Task { await viewModel.deleteBackup(b) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This backup file will be permanently removed.")
        }
    }

    private func backupDescription(_ type: SiteBackupType) -> String {
        switch type {
        case .full: return "Files + database + nginx config"
        case .filesOnly: return "Website files only (document root)"
        case .databaseOnly: return "Linked database dump only"
        case .incremental: return "Changes since last backup"
        }
    }
}
