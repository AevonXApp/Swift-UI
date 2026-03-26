//
//  DirectoryBrowserView.swift
//  AevonX
//
//  A modal view for browsing remote directories and selecting a path.
//

import SwiftUI

struct DirectoryBrowserView: View {
    @ObservedObject var viewModel: WebsiteDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Directory")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text(viewModel.currentBrowsingPath)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Button(L10n.Button.cancel) {
                    dismiss()
                }
                .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider().background(Color.axBorder)
            
            // Toolbar (Navigation)
            HStack {
                Button(action: { viewModel.backToParent() }) {
                    Image(systemName: "arrow.up.folder")
                        .foregroundColor(viewModel.currentBrowsingPath == "/" ? .axTextMuted : .axTextPrimary)
                        .padding(AXSpacing.sm)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.currentBrowsingPath == "/")
                .help(L10n.Website.goUpLevel)
                
                Spacer()
                
                Button(L10n.Website.selectCurrent) {
                    viewModel.selectCurrentDirectory()
                    dismiss()
                }
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .padding(AXSpacing.md)
            .background(Color.axBackgroundTertiary)
            
            // Content
            List {
                if viewModel.isLoadingBrowsingItems {
                    HStack {
                        Spacer()
                        ProgressView(L10n.Status.loading)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if viewModel.browsingItems.isEmpty {
                    Text("No subdirectories found")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextMuted)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.browsingItems, id: \.self) { folder in
                        Button(action: { viewModel.navigateToPath(folder) }) {
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.axWarning)
                                Text(folder)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding(.vertical, AXSpacing.xxs)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
        .onAppear {
            viewModel.startBrowsing(initialPath: viewModel.website.documentRoot)
        }
    }
}
