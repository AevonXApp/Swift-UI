//
//  NewFileSheet.swift
//  AevonX
//
//  Sheet view for creating a new file
//

import SwiftUI
import AevonXCore

// MARK: - New File Sheet

struct NewFileSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var fileName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("New File")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("File Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                TextField("filename.txt", text: $fileName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit {
                        createIfValid()
                    }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showNewFileSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Create") { createIfValid() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 340)
        .background(Color.axBackground)
    }
    
    private func createIfValid() {
        let name = fileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createFile(name: name)
        viewModel.showNewFileSheet = false
    }
}
