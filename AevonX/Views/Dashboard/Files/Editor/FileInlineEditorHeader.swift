//
//  FileInlineEditorHeader.swift
//  AevonX
//
//  Header bar for the inline file editor
//  Shows file info, language badge, discard/save buttons
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Inline Editor Header

struct FileInlineEditorHeader: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Back to files
            Button(action: { viewModel.closeEditor() }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                    Text(L10n.Files.files)
                        .font(.system(size: 12))
                }
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().frame(height: 16)
            
            // File icon + name
            if let file = viewModel.editorFile {
                Image(systemName: file.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(fileColor(for: file))
            }
            
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
                    .font(.system(size: 10))
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
            
            // Discard
            Button(action: { viewModel.editorContent = viewModel.editorOriginalContent }) {
                Text(L10n.Files.discard)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 3)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isEditorDirty)
            .opacity(viewModel.isEditorDirty ? 1 : 0.4)
            
            // Save
            Button(action: { viewModel.saveFile() }) {
                HStack(spacing: AXSpacing.xxs) {
                    if viewModel.isSavingFile {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.5)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 10))
                    }
                    Text(L10n.Button.save)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 3)
                .background(viewModel.isEditorDirty ? Color.axAccentBlue : Color.axAccentBlue.opacity(0.4))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isEditorDirty || viewModel.isSavingFile)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundSecondary)
    }
}
