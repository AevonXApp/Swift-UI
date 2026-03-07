//
//  FileRow.swift
//  AevonX
//
//  Individual file/directory row in the file list
//  Displays checkbox, icon, name, size, permissions, owner, and date
//

import SwiftUI
import AevonXCore

// MARK: - File Row

struct FileRow: View {
    let file: RemoteFileItem
    @ObservedObject var viewModel: FileManagerViewModel
    let onRightClick: (CGPoint) -> Void
    
    private var isSelected: Bool {
        viewModel.selectedFiles.contains(file.id)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Selection checkbox
            Button(action: {
                if isSelected {
                    viewModel.selectedFiles.remove(file.id)
                } else {
                    viewModel.selectedFiles.insert(file.id)
                    viewModel.lastSelectedFile = file
                }
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted.opacity(0.4))
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 24)
            .padding(.trailing, 4)
            
            // Name column
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: file.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(file.isDirectory ? .axAccentBlue : fileColor(for: file))
                    .frame(width: 18)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(file.name)
                        .font(.system(size: 12, weight: file.isDirectory ? .medium : .regular))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    if file.isSymlink, let target = file.symlinkTarget {
                        Text("→ \(target)")
                            .font(.system(size: 9))
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            // Size
            Text(file.formattedSize)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .frame(width: 80, alignment: .trailing)
            
            // Permissions — numeric
            Text(file.permissions.numericString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(permissionColor(file.permissions))
                .frame(width: 50, alignment: .center)
            
            // Owner
            Text(file.owner)
                .font(.system(size: 11))
                .foregroundColor(.axTextSecondary)
                .frame(width: 70, alignment: .center)
                .lineLimit(1)
            
            // Modified date
            Text(formatFileDate(file.modifiedDate))
                .font(.system(size: 11))
                .foregroundColor(.axTextTertiary)
                .frame(width: 130, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(isSelected ? Color.axAccentBlue.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { viewModel.handleFileDoubleTap(file) }
        .onTapGesture(count: 1) { viewModel.selectSingleFile(file) }
        .overlay(
            RightClickHandler { position in
                onRightClick(position)
            }
        )
    }
}
