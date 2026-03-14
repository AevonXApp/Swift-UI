//
//  FileTransferPanel.swift
//  AevonX
//
//  Transfer progress bar showing active upload/download progress
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Transfer Progress Panel

struct FileTransferPanel: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach(viewModel.activeTransfers) { transfer in
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: transfer.state == .completed ? "checkmark.circle.fill" :
                            transfer.state == .failed ? "xmark.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 12))
                        .foregroundColor(transfer.state == .completed ? .axSuccess :
                                            transfer.state == .failed ? .axError : .axAccentBlue)
                    
                    Text(transfer.fileName)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    if transfer.state == .transferring {
                        ProgressView(value: transfer.percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .axAccentBlue))
                            .frame(width: 100)
                    }
                    
                    Text(transfer.progressText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                    
                    if transfer.state == .transferring {
                        Button(action: { viewModel.cancelTransfer(transfer) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axBackgroundSecondary)
    }
}
