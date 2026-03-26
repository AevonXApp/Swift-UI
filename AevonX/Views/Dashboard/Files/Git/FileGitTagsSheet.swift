//
//  FileGitTagsSheet.swift
//  AevonX
//
//  Tag list with checkout option.
//

import SwiftUI
import AevonXCoreBridge

struct FileGitTagsSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            content
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color.axBackground)
    }

    private var header: some View {
        HStack {
            Image(systemName: "tag")
                .foregroundColor(.axAccentBlue)
            Text(L10n.FileGit.Tags.title)
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
        if viewModel.gitTags.isEmpty {
            VStack(spacing: AXSpacing.md) {
                Image(systemName: "tag")
                    .font(.system(size: 32))
                    .foregroundColor(.axTextMuted)
                Text(L10n.FileGit.Tags.empty)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.gitTags) { tag in
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.axAccentBlue)
                            Text(tag.name)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                            if !tag.message.isEmpty {
                                Text(tag.message)
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextMuted)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button {
                                Task {
                                    await viewModel.gitCheckoutTag(tag.name)
                                    dismiss()
                                }
                            } label: {
                                Text(L10n.FileGit.Tags.checkout)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)

                        if tag.id != viewModel.gitTags.last?.id {
                            Divider().background(Color.axBorder.opacity(0.3))
                        }
                    }
                }
                .padding(.vertical, AXSpacing.sm)
            }
        }
    }
}
