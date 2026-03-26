//
//  FileGitRemotesSheet.swift
//  AevonX
//
//  Remote management — list, add, remove.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitRemotesSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    addSection
                    listSection
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(minWidth: 480, minHeight: 320)
        .background(Color.axBackground)
    }

    private var header: some View {
        HStack {
            Image(systemName: "network")
                .foregroundColor(.axAccentGreen)
            Text(L10n.FileGit.Remotes.title)
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

    private var addSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.FileGit.Remotes.add)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.sm) {
                TextField(L10n.FileGit.Remotes.name, text: $viewModel.gitNewRemoteName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(AXSpacing.sm)
                    .frame(width: 120)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))

                TextField(L10n.FileGit.Remotes.url, text: $viewModel.gitNewRemoteURL)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))

                Button {
                    Task {
                        await viewModel.gitAddRemote()
                        await viewModel.loadGitFull()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.axAccentGreen)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.gitNewRemoteName.isEmpty || viewModel.gitNewRemoteURL.isEmpty)
            }
        }
    }

    @ViewBuilder
    private var listSection: some View {
        if viewModel.gitRemotes.isEmpty {
            Text("No remotes configured")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.gitRemotes) { remote in
                    HStack(spacing: AXSpacing.sm) {
                        Text(remote.name)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 60, alignment: .leading)
                        Text(remote.url)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(1)
                        Text(remote.type)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axSurface)
                            .clipShape(Capsule())
                        Spacer()
                        Button {
                            Task {
                                await viewModel.gitRemoveRemote(remote.name)
                                await viewModel.loadGitFull()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(.axError.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)

                    if remote.id != viewModel.gitRemotes.last?.id {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }
}
