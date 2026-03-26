//
//  FileGitStashSheet.swift
//  AevonX
//
//  Stash management — save, list, pop, drop.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitStashSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    saveSection
                    listSection
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(minWidth: 450, minHeight: 350)
        .background(Color.axBackground)
    }

    private var header: some View {
        HStack {
            Image(systemName: "tray.and.arrow.down")
                .foregroundColor(.axAccentBlue)
            Text(L10n.FileGit.Stash.title)
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

    private var saveSection: some View {
        HStack(spacing: AXSpacing.sm) {
            TextField(L10n.FileGit.Stash.messagePlaceholder, text: $viewModel.gitStashMessage)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))

            Button {
                Task {
                    await viewModel.gitStashSave()
                    await viewModel.loadGitFull()
                }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text(L10n.FileGit.Stash.save)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var listSection: some View {
        if viewModel.gitStashes.isEmpty {
            Text(L10n.FileGit.Stash.empty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
                .padding(.vertical, AXSpacing.lg)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.gitStashes) { stash in
                    HStack(spacing: AXSpacing.sm) {
                        Text(stash.index)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axAccentPurple)
                            .frame(width: 70, alignment: .leading)
                        Text(stash.message)
                            .font(.system(size: 12))
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            Task {
                                await viewModel.gitStashDrop(stash.index)
                                await viewModel.loadGitFull()
                            }
                        } label: {
                            Text(L10n.FileGit.Stash.drop)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.axError)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)

                    if stash.id != viewModel.gitStashes.last?.id {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)

            Button {
                Task {
                    await viewModel.gitStashPop()
                    await viewModel.loadGitFull()
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "tray.and.arrow.up")
                    Text(L10n.FileGit.Stash.pop)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axAccentGreen)
            }
            .buttonStyle(.plain)
        }
    }
}
