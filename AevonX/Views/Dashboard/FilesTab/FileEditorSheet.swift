//
//  FileEditorSheet.swift
//  AevonX
//
//  Full-screen file editor with syntax highlighting and save/discard
//

import SwiftUI
import AevonXCore

// MARK: - File Editor Sheet

struct FileEditorSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor Header
            editorHeader
            
            Divider().background(Color.axBorder)
            
            // Editor Content
            ZStack {
                Color(nsColor: AtomOneDark.background)
                    .ignoresSafeArea()
                
                if viewModel.isLoadingFile {
                    loadingView
                } else if !viewModel.editorContent.isEmpty || !viewModel.isLoadingFile {
                    CodeEditorView(
                        text: $viewModel.editorContent,
                        language: viewModel.editorFile?.language ?? .plainText,
                        isReadOnly: false
                    )
                    .id("editor-\(viewModel.editorFile?.path ?? "")-\(viewModel.isLoadingFile)")
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(nsColor: AtomOneDark.background))
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    
    private var editorHeader: some View {
        HStack(spacing: AXSpacing.md) {
            // File icon
            if let file = viewModel.editorFile {
                Image(systemName: file.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(.axAccentBlue)
            }
            
            // File name
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AXSpacing.xs) {
                    Text(viewModel.editorFile?.name ?? "Untitled")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    
                    if viewModel.isEditorDirty {
                        Circle()
                            .fill(Color.axWarning)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(viewModel.editorFile?.path ?? "")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Language badge
            if let file = viewModel.editorFile {
                Text(file.language.displayName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
            }
            
            // Discard button
            Button(action: {
                viewModel.editorContent = viewModel.editorOriginalContent
            }) {
                Text("Discard")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isEditorDirty)
            .opacity(viewModel.isEditorDirty ? 1 : 0.4)
            
            // Save button
            Button(action: { viewModel.saveFile() }) {
                HStack(spacing: AXSpacing.xs) {
                    if viewModel.isSavingFile {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12))
                    }
                    Text("Save")
                }
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                .background(viewModel.isEditorDirty ? Color.axAccentBlue : Color.axAccentBlue.opacity(0.4))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isEditorDirty || viewModel.isSavingFile)
            
            // Close button
            Button(action: { viewModel.closeEditor() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 24, height: 24)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundSecondary)
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
            Text("Loading file...")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
