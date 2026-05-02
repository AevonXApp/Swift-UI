//
//  NewFolderSheet.swift
//  AevonX
//
//  Sheet view for creating a new folder
//

import SwiftUI
import AevonXCoreBridge

// MARK: - New Folder Sheet

struct NewFolderSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var folderName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text(L10n.Files.newFolder)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(L10n.Files.folderName)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                TextField("folder-name", text: $folderName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit {
                        createIfValid()
                    }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button(L10n.Button.cancel) { viewModel.showNewFolderSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button(L10n.Button.create) { createIfValid() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 340)
        .background(Color.axBackground)
    }
    
    private func createIfValid() {
        let name = folderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createFolder(name: name)
        viewModel.showNewFolderSheet = false
    }
}
