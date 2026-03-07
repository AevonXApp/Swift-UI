//
//  CompressSheet.swift
//  AevonX
//
//  Sheet view for compressing selected files into an archive
//

import SwiftUI
import AevonXCore

// MARK: - Compress Sheet

struct CompressSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var archiveName = ""
    @State private var selectedFormat: SFTPFileManager.ArchiveFormat = .zip
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "archivebox")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Compress Files")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            Text("\(viewModel.selectedFiles.count) item(s) selected")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Archive Name")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    TextField("archive", text: $archiveName)
                        .textFieldStyle(AXTextFieldStyle())
                        .onSubmit { compressIfValid() }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Format")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    Picker("", selection: $selectedFormat) {
                        ForEach(SFTPFileManager.ArchiveFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Text("Output: \(archiveName.isEmpty ? "archive" : archiveName).\(selectedFormat.fileExtension)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showCompressSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                
                Button(action: { compressIfValid() }) {
                    HStack(spacing: AXSpacing.xxs) {
                        if viewModel.isCompressing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.5)
                        }
                        Text("Compress")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(archiveName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isCompressing)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 380)
        .background(Color.axBackground)
    }
    
    private func compressIfValid() {
        let name = archiveName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.compressSelected(archiveName: name, format: selectedFormat)
    }
}
