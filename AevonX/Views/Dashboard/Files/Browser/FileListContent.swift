//
//  FileListContent.swift
//  AevonX
//
//  Main file list content area with loading, error, empty, and file rows
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File List Content

struct FileListContent: View {
    @ObservedObject var viewModel: FileManagerViewModel
    let onFileRightClick: (RemoteFileItem, CGPoint) -> Void
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.files.isEmpty {
                loadingState
            } else if let error = viewModel.errorMessage, viewModel.files.isEmpty {
                errorState(error)
            } else if viewModel.displayFiles.isEmpty {
                emptyState
            } else {
                fileList
            }
        }
        .background(Color.axBackground)
    }
    
    // MARK: - States
    
    private var loadingState: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
            Text(L10n.Status.loading)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorState(_ error: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(.axWarning)
            Text(error)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            Button(L10n.Button.retry) { viewModel.refresh() }
                .buttonStyle(AXSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyState: some View {
        AXPlaceholder(
            icon: "folder",
            title: "Empty Directory",
            subtitle: "This directory has no files.",
            iconColor: .axTextMuted
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.displayFiles) { file in
                    FileRow(
                        file: file,
                        viewModel: viewModel,
                        onRightClick: { position in
                            onFileRightClick(file, position)
                        }
                    )
                    Divider().background(Color.axBorder.opacity(0.3))
                }
            }
        }
    }
}
