//
//  SymlinkSheet.swift
//  AevonX
//
//  Sheet view for creating a symbolic link
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Symlink Sheet

struct SymlinkSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var linkName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Create Symlink")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            if let source = viewModel.symlinkSourceFile {
                Text("Target: \(source.path)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Link Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                TextField("link_name", text: $linkName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit { createIfValid() }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showSymlinkSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Create") { createIfValid() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(linkName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 380)
        .background(Color.axBackground)
    }
    
    private func createIfValid() {
        guard let source = viewModel.symlinkSourceFile else { return }
        let name = linkName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createSymlink(target: source, linkName: name)
    }
}
