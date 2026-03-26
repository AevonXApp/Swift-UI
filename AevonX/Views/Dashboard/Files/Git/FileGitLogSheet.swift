//
//  FileGitLogSheet.swift
//  AevonX
//
//  Commit history list with checkout option.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitLogSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            content
        }
        .frame(minWidth: 550, minHeight: 450)
        .background(Color.axBackground)
    }

    private var header: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.axAccentPurple)
            Text(L10n.FileGit.Log.title)
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

    @ViewBuilder
    private var content: some View {
        if viewModel.gitCommits.isEmpty {
            VStack(spacing: AXSpacing.md) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32))
                    .foregroundColor(.axTextMuted)
                Text(L10n.FileGit.Log.empty)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.gitCommits) { commit in
                        commitRow(commit)
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
    }

    private func commitRow(_ commit: GitCommit) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Text(commit.shortHash)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.axAccentPurple)
                .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(commit.message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(2)
                HStack(spacing: AXSpacing.sm) {
                    Text(commit.author)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                    Text(commit.relativeDate)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            Button {
                Task {
                    _ = try? await GitService.shared.checkoutCommit(hash: commit.id, documentRoot: viewModel.currentPath, serverId: viewModel.serverId)
                    await viewModel.loadGitInfo()
                    await viewModel.loadGitLog()
                }
            } label: {
                Text(L10n.FileGit.Log.checkout)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}
