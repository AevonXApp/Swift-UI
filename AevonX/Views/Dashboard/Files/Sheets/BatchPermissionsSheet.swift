//
//  BatchPermissionsSheet.swift
//  AevonX
//
//  Batch permissions editing — apply same permissions to multiple files at once
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Batch Permissions Sheet

struct BatchPermissionsSheet: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var numericPerms = "644"
    @State private var applyRecursively = false
    @State private var isApplying = false
    @State private var resultMessage: String?
    
    var selectedFiles: [RemoteFileItem] {
        let selected = viewModel.files.filter { viewModel.selectedFiles.contains($0.id) }
        return selected.isEmpty ? viewModel.files : selected
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.axAccentBlue)
                
                Text("Batch Permissions")
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.axBackgroundSecondary)
            
            Divider().background(Color.axBorder)
            
            VStack(spacing: AXSpacing.md) {
                // Target info
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.axAccentBlue)
                    Text("\(selectedFiles.count) items selected")
                        .font(.system(size: 13))
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AXSpacing.md)
                
                // Permission input
                HStack(spacing: AXSpacing.md) {
                    Text("Permissions:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("644", text: $numericPerms)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 80)
                        .padding(6)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    
                    // Quick presets
                    ForEach(["644", "755", "600", "777"], id: \.self) { preset in
                        Button(preset) { numericPerms = preset }
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(numericPerms == preset ? Color.axAccentBlue.opacity(0.2) : Color.axSurface)
                            .foregroundColor(numericPerms == preset ? .axAccentBlue : .axTextSecondary)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Recursive toggle
                Toggle(isOn: $applyRecursively) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("Apply recursively to directories")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.axTextSecondary)
                }
                .padding(.horizontal)
                
                // Result message
                if let msg = resultMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(msg.contains("✓") ? .axSuccess : .axError)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // File list preview
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(selectedFiles.prefix(20), id: \.id) { file in
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: file.iconName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 14)
                                Text(file.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text(file.permissions.numericString)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 3)
                        }
                        if selectedFiles.count > 20 {
                            Text("... and \(selectedFiles.count - 20) more")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextMuted)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            
            Divider().background(Color.axBorder)
            
            // Actions
            HStack {
                Button(L10n.Button.cancel) { dismiss() }
                    .buttonStyle(AXSecondaryButtonStyle())
                
                Spacer()
                
                if isApplying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                        .scaleEffect(0.7)
                }
                
                Button("Apply Permissions") { applyPermissions() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(numericPerms.count != 3 || isApplying)
            }
            .padding()
        }
        .frame(width: 550, height: 420)
        .background(Color.axBackground)
    }
    
    private func applyPermissions() {
        isApplying = true
        resultMessage = nil
        
        Task {
            var successCount = 0
            var failCount = 0
            let recursive = applyRecursively ? "-R " : ""
            
            let filesBridge = FilesBridge.shared
            for file in selectedFiles {
                    let mode = applyRecursively ? "-R \(numericPerms)" : numericPerms
                    let cmd = filesBridge.changePermissionsCmd(path: file.path, mode: mode)
                    let json = await SSHBridge.shared.executeAsyncJSON(serverID: viewModel.serverId, command: cmd)
                    let result = SSHResult.parse(json)
                    if result.isSuccess { successCount += 1 } else { failCount += 1 }
            }
            
            if failCount == 0 {
                resultMessage = "✓ Applied \(numericPerms) to \(successCount) items"
            } else {
                resultMessage = "⚠ \(successCount) succeeded, \(failCount) failed"
            }
            
            isApplying = false
            await viewModel.loadFiles()
        }
    }
}
