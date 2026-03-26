//
//  FileGitBranchSheet.swift
//  AevonX
//
//  Branch management — list, switch, create, delete, merge.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitBranchSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss

    var localBranches: [GitBranch] {
        viewModel.gitBranches.filter { !$0.isRemote }
    }

    var remoteBranches: [GitBranch] {
        viewModel.gitBranches.filter { $0.isRemote }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    createBranchSection
                    localSection
                    remoteSection
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(minWidth: 420, minHeight: 350)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.axAccentPurple)
            Text(L10n.FileGit.Branch.title)
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

    // MARK: - Create

    private var createBranchSection: some View {
        HStack(spacing: AXSpacing.sm) {
            TextField(L10n.FileGit.Branch.newPlaceholder, text: $viewModel.gitNewBranchName)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))

            Button {
                Task {
                    await viewModel.gitCreateBranch()
                    await viewModel.loadGitFull()
                }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.FileGit.Branch.new)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(viewModel.gitNewBranchName.isEmpty ? Color.axTextMuted : Color.axAccentPurple)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gitNewBranchName.isEmpty)
        }
    }

    // MARK: - Local

    private var localSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.FileGit.Branch.local)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            VStack(spacing: 0) {
                ForEach(localBranches) { branch in
                    branchRow(branch)
                    if branch.id != localBranches.last?.id {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }

    // MARK: - Remote

    @ViewBuilder
    private var remoteSection: some View {
        if !remoteBranches.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text(L10n.FileGit.Branch.remote)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                VStack(spacing: 0) {
                    ForEach(remoteBranches) { branch in
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "cloud")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextMuted)
                            Text(branch.name)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.xs)
                    }
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
            }
        }
    }

    // MARK: - Branch Row

    private func branchRow(_ branch: GitBranch) -> some View {
        HStack(spacing: AXSpacing.sm) {
            if branch.isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.axAccentGreen)
            } else {
                Circle().fill(Color.axTextMuted.opacity(0.3)).frame(width: 11, height: 11)
            }

            Text(branch.name)
                .font(.system(size: 12, weight: branch.isCurrent ? .semibold : .regular, design: .monospaced))
                .foregroundColor(branch.isCurrent ? .axTextPrimary : .axTextSecondary)

            if branch.isCurrent {
                Text(L10n.FileGit.Branch.current)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axAccentGreen)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(Color.axAccentGreen.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            if !branch.isCurrent {
                Button {
                    Task {
                        await viewModel.gitSwitchBranch(branch.name)
                        await viewModel.loadGitFull()
                    }
                } label: {
                    Text(L10n.FileGit.Branch.switchBranch)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await viewModel.gitMergeBranch(branch.name)
                        await viewModel.loadGitFull()
                    }
                } label: {
                    Text(L10n.FileGit.Branch.merge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axAccentPurple)
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await viewModel.gitDeleteBranch(branch.name)
                        await viewModel.loadGitFull()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.axError.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
    }
}
