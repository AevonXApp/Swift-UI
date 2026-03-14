//
//  FileStatusBar.swift
//  AevonX
//
//  Status bar at the bottom of the file browser showing item count,
//  selection info, errors, loading state, and current path
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Status Bar

struct FileStatusBar: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Item count
            Text("\(viewModel.displayFiles.count) items")
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
            
            if !viewModel.selectedFiles.isEmpty {
                Text("• \(viewModel.selectedFiles.count) selected")
                    .font(.system(size: 10))
                    .foregroundColor(.axAccentBlue)
            }
            
            Spacer()
            
            // Error message
            if let error = viewModel.errorMessage {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
                .foregroundColor(.axWarning)
            }
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                    .scaleEffect(0.5)
            }
            
            // Current path
            Text(viewModel.currentPath)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, 4)
        .background(Color.axBackgroundSecondary)
    }
}
