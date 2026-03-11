//
//  DBBackupSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge
import UniformTypeIdentifiers

struct DBBackupSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                backupHeader
                createBackupCard
                importSQLCard
                backupList
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await viewModel.loadBackups()
        }
        .sheet(isPresented: $viewModel.showImportSQL) {
            DBImportSQLView(viewModel: viewModel)
        }
    }

    private var backupHeader: some View {
        Text("Backup & Import")
            .font(AXTypography.title2)
            .fontWeight(.bold)
            .foregroundColor(.axTextPrimary)
    }

    private var createBackupCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.database.type.brandColor)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Create Backup")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("Export '\(viewModel.database.name)' to a SQL dump file on the server.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Button {
                    Task { await viewModel.createBackup() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if viewModel.isCreatingBackup {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Text(viewModel.isCreatingBackup ? "Creating..." : "Create Backup")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(viewModel.isCreatingBackup ? Color.axTextMuted.opacity(0.5) : viewModel.database.type.brandColor)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isCreatingBackup)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var importSQLCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.axAccentGreen)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Import SQL")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("Import a .sql file or paste SQL content into '\(viewModel.database.name)'.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Button { viewModel.showImportSQL = true } label: {
                    Text("Import SQL")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentGreen)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var backupList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Recent Backups")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            if viewModel.backups.isEmpty {
                Text("No backups found on the server.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                    .padding(AXSpacing.lg)
            } else {
                ForEach(viewModel.backups, id: \.id) { backup in
                    backupRow(backup)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func backupRow(_ backup: BackupInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 16))
                .foregroundColor(viewModel.database.type.brandColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(URL(fileURLWithPath: backup.id).lastPathComponent)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(backup.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Text(backup.size)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            // Download
            Button {
                Task { await viewModel.downloadBackup(backup.id) }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.database.type.brandColor)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isDownloadingBackup)

            // Delete
            Button {
                viewModel.confirmDeleteBackup(backup.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.axError)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AXSpacing.sm)
    }
}
