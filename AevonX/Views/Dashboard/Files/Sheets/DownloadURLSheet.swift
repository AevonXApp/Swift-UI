//
//  DownloadURLSheet.swift
//  AevonX
//
//  Sheet view for downloading a file from a remote URL
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Download from URL Sheet

struct DownloadFromURLSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var urlString = ""
    @State private var fileName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Download from URL")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("URL")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    TextField("https://example.com/file.tar.gz", text: $urlString)
                        .textFieldStyle(AXTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("File Name (optional)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    TextField("Leave empty to auto-detect", text: $fileName)
                        .textFieldStyle(AXTextFieldStyle())
                }
                
                Text("Destination: \(viewModel.currentPath)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            
            HStack(spacing: AXSpacing.md) {
                Button(L10n.Button.cancel) { viewModel.showDownloadURLSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                
                Button(action: {
                    viewModel.downloadFromURL(
                        urlString: urlString,
                        fileName: fileName.isEmpty ? nil : fileName
                    )
                }) {
                    HStack(spacing: AXSpacing.xxs) {
                        if viewModel.isDownloadingFromURL {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 12))
                        }
                        Text(L10n.Files.download)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(urlString.isEmpty ? Color.axAccentBlue.opacity(0.4) : Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isDownloadingFromURL)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 420)
        .background(Color.axBackground)
    }
}
