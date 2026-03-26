//
//  FileGitToolbar.swift
//  AevonX
//
//  Git status bar + action buttons shown when .git detected.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitToolbar: View {
    @ObservedObject var viewModel: FileManagerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                branchInfo
                statusCounters
                Spacer()
                lastCommitInfo
                Divider().frame(height: 20)
                actionButtons
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(
                Color.axSurface.overlay(
                    LinearGradient(
                        colors: [Color.axAccentPurple.opacity(0.03), Color.clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            )

            if viewModel.gitOperationRunning, let msg = viewModel.gitOperationMessage {
                operationBar(msg)
            }
        }
    }

    // MARK: - Branch

    private var branchInfo: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.axAccentPurple)
            Text(viewModel.gitInfo.currentBranch.isEmpty ? "HEAD" : viewModel.gitInfo.currentBranch)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxxs)
        .background(Color.axAccentPurple.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Status Counters

    private var statusCounters: some View {
        HStack(spacing: AXSpacing.sm) {
            if viewModel.gitInfo.aheadCount > 0 {
                counterBadge("↑\(viewModel.gitInfo.aheadCount)", color: .axAccentGreen)
            }
            if viewModel.gitInfo.behindCount > 0 {
                counterBadge("↓\(viewModel.gitInfo.behindCount)", color: .axWarning)
            }
            if viewModel.gitInfo.modifiedFiles > 0 {
                counterBadge("M\(viewModel.gitInfo.modifiedFiles)", color: .axWarning)
            }
            if viewModel.gitInfo.untrackedFiles > 0 {
                counterBadge("?\(viewModel.gitInfo.untrackedFiles)", color: .axTextMuted)
            }
        }
    }

    private func counterBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Last Commit

    private var lastCommitInfo: some View {
        Group {
            if !viewModel.gitInfo.lastCommitMessage.isEmpty {
                HStack(spacing: AXSpacing.xxxs) {
                    Text(L10n.FileGit.lastCommit)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text("\"\(viewModel.gitInfo.lastCommitMessage.prefix(40))\"")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                    if !viewModel.gitInfo.lastCommitDate.isEmpty {
                        Text("(\(viewModel.gitInfo.lastCommitDate))")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AXSpacing.xxs) {
            gitButton(L10n.FileGit.pull, icon: "arrow.down", color: .axAccentGreen) {
                Task { await viewModel.gitPull() }
            }
            gitButton(L10n.FileGit.push, icon: "arrow.up", color: .axAccentBlue) {
                Task { await viewModel.gitPush() }
            }
            gitButton(L10n.FileGit.fetch, icon: "arrow.clockwise", color: .axTextSecondary) {
                Task { await viewModel.gitFetch() }
            }

            Divider().frame(height: 18)

            gitButton(L10n.FileGit.commit, icon: "checkmark.circle", color: .axAccentGreen) {
                Task { await viewModel.loadGitInfo() }
                viewModel.showGitCommitSheet = true
            }
            gitButton(L10n.FileGit.branchBtn, icon: "arrow.triangle.branch", color: .axAccentPurple) {
                Task { await viewModel.loadGitFull() }
                viewModel.showGitBranchPopover = true
            }

            moreMenu
        }
        .disabled(viewModel.gitOperationRunning)
    }

    private func gitButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xxxs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.08))
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        Menu {
            Section(L10n.FileGit.More.stash) {
                Button(L10n.FileGit.Stash.save) {
                    viewModel.showGitStashSheet = true
                }
                Button(L10n.FileGit.Stash.pop) {
                    Task { await viewModel.gitStashPop() }
                }
                Button(L10n.FileGit.Stash.list) {
                    Task { await viewModel.loadGitFull() }
                    viewModel.showGitStashSheet = true
                }
            }

            Section(L10n.FileGit.More.tags) {
                Button(L10n.FileGit.Tags.title) {
                    Task { await viewModel.loadGitFull() }
                    viewModel.showGitTagsSheet = true
                }
            }

            Section(L10n.FileGit.More.remotes) {
                Button(L10n.FileGit.Remotes.title) {
                    Task { await viewModel.loadGitFull() }
                    viewModel.showGitRemotesSheet = true
                }
            }

            Section(L10n.FileGit.More.history) {
                Button(L10n.FileGit.Log.title) {
                    Task { await viewModel.loadGitLog() }
                    viewModel.showGitLogSheet = true
                }
            }

            Divider()

            Section(L10n.FileGit.More.dangerZone) {
                Button(L10n.FileGit.More.resetHard, role: .destructive) {
                    viewModel.gitDangerAction = .resetHard
                    viewModel.showGitDangerConfirm = true
                }
                Button(L10n.FileGit.More.discardAll, role: .destructive) {
                    viewModel.gitDangerAction = .discardAll
                    viewModel.showGitDangerConfirm = true
                }
                Button(L10n.FileGit.More.disconnect, role: .destructive) {
                    viewModel.gitDangerAction = .disconnect
                    viewModel.showGitDangerConfirm = true
                }
            }
        } label: {
            HStack(spacing: AXSpacing.xxxs) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .semibold))
                Text(L10n.FileGit.more)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxxs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Operation Bar

    private func operationBar(_ message: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ProgressView().controlSize(.small)
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xxxs)
        .background(Color.axAccentBlue.opacity(0.06))
    }
}
