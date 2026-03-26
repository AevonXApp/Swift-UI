//
//  DecryptionErrorView.swift
//  AevonX
//
//  View for handling decryption errors and encryption key input
//

import SwiftUI

struct DecryptionErrorView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @State private var keyInput = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.axWarning)
                
                Text(L10n.Encryption.decryptionError)
                    .font(.headline)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button {
                    viewModel.dismissEncryptionError()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Divider()
                .background(Color.axBorder)
            
            // Content
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Error description
                if let error = viewModel.encryptionError {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text(L10n.Encryption.errorDetails)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextSecondary)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.axTextPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(Color.axError.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axError.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Show key input
                    keyInputSection
                }
                
                // Failed servers count
                if !viewModel.failedServerIds.isEmpty {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.axTextMuted)
                        
                        Text(L10n.Encryption.affectedServers(viewModel.failedServerIds.count))
                            .font(.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
                
                // Help text
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text(L10n.Encryption.whatCanYouDo)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        helpItem(icon: "key.fill", text: L10n.Encryption.helpEnterKey)
                        helpItem(icon: "arrow.clockwise", text: L10n.Encryption.helpLogout)
                        helpItem(icon: "trash", text: L10n.Encryption.helpDeleteServers)
                    }
                }
            }
            .padding()
            
            Divider()
                .background(Color.axBorder)
            
            // Actions
            HStack(spacing: AXSpacing.md) {
                Button {
                    viewModel.dismissEncryptionError()
                } label: {
                    Text(L10n.Button.close)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    Task {
                        await submitKey()
                    }
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(L10n.Button.restoreKeys)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.isEmpty || isProcessing)
            }
            .padding()
            .background(Color.axSurface)
        }
        .frame(width: 450)
        .background(Color.axBackground)
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    private var keyInputSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.Encryption.enterKey)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "key.fill")
                    .foregroundColor(.axAccentBlue)
                
                SecureField(L10n.Encryption.keyPlaceholder, text: $keyInput)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .focused($isInputFocused)
                    .onSubmit {
                        Task {
                            await submitKey()
                        }
                    }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isInputFocused ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
            
            Text(L10n.Encryption.keyProvidedHelp)
                .font(.caption)
                .foregroundColor(.axTextMuted)
        }
    }
    
    private func helpItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.axAccentBlue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.axTextMuted)
        }
    }
    
    private func submitKey() async {
        guard !keyInput.isEmpty else { return }
        
        isProcessing = true
        await viewModel.retryDecryptionWithKey(keyInput)
        isProcessing = false
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.axBackground.ignoresSafeArea()
        
        DecryptionErrorView(viewModel: {
            let vm = ServerListViewModel()
            vm.encryptionError = "Some servers could not be decrypted."
            vm.showEncryptionKeyInput = true
            vm.failedServerIds = ["server1", "server2"]
            return vm
        }())
    }
}
