//
//  FileGitCommitSheet.swift
//  AevonX
//
//  Commit sheet — shows changed files, message input, stage all & commit.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitCommitSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    changedFilesList
                    commitMessageField
                }
                .padding(AXSpacing.xl)
            }
            Divider().background(Color.axDivider)
            footer
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.axAccentGreen)
            Text(L10n.FileGit.Commit.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Changed Files

    @ViewBuilder
    private var changedFilesList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.FileGit.Commit.changedFiles)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            if viewModel.gitFileChanges.isEmpty {
                Text(L10n.FileGit.Commit.noChanges)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                    .padding(.vertical, AXSpacing.md)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.gitFileChanges) { change in
                        fileChangeRow(change)
                        if change.id != viewModel.gitFileChanges.last?.id {
                            Divider().background(Color.axBorder.opacity(0.3))
                        }
                    }
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
            }
        }
    }

    private func fileChangeRow(_ change: GitFileChange) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(statusLetter(change.status))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(statusColor(change.status))
                .frame(width: 20)
            Text(change.path)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
    }

    // MARK: - Commit Message

    private var commitMessageField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.FileGit.Commit.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            TextEditor(text: $viewModel.gitCommitMessage)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(AXSpacing.sm)
                .frame(minHeight: 80)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.gitCommitMessage.isEmpty {
                        Text(L10n.FileGit.Commit.placeholder)
                            .font(.system(size: 13))
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.md)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(L10n.Button.cancel) { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.axTextSecondary)

            Spacer()

            Button {
                Task {
                    await viewModel.gitCommitAll()
                    dismiss()
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if viewModel.gitOperationRunning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(L10n.FileGit.Commit.stageAll)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.sm)
                .background(viewModel.gitCommitMessage.isEmpty || viewModel.gitFileChanges.isEmpty ? Color.axTextMuted : Color.axAccentGreen)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gitCommitMessage.isEmpty || viewModel.gitFileChanges.isEmpty || viewModel.gitOperationRunning)
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Helpers

    private func statusLetter(_ status: GitFileStatus) -> String {
        status.rawValue
    }

    private func statusColor(_ status: GitFileStatus) -> Color {
        switch status {
        case .modified: return .axWarning
        case .added: return .axSuccess
        case .deleted: return .axError
        case .renamed: return .axAccentBlue
        case .untracked: return .axTextMuted
        case .copied: return .axAccentPurple
        }
    }
}
