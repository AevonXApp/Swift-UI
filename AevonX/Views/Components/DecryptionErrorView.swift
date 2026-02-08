//
//  DecryptionErrorView.swift
//  AevonX
//
//  View for handling decryption errors and recovery key input
//

import SwiftUI

struct DecryptionErrorView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @State private var recoveryKeyInput = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.axWarning)
                
                Text("Decryption Error")
                    .font(.headline)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button {
                    viewModel.dismissDecryptionError()
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
                if let error = viewModel.decryptionError {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("Error Details:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextSecondary)
                        
                        Text(error.localizedDescription)
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
                    
                    // Show recovery key input if needed
                    if error.requiresRecoveryKey {
                        recoveryKeyInputSection
                    }
                }
                
                // Failed servers count
                if !viewModel.failedServerIds.isEmpty {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.axTextMuted)
                        
                        Text("Affected servers: \(viewModel.failedServerIds.count)")
                            .font(.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
                
                // Help text
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("What can you do?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        helpItem(icon: "key.fill", text: "Enter your Recovery Key if you have one")
                        helpItem(icon: "arrow.clockwise", text: "Try logging out and logging back in")
                        helpItem(icon: "trash", text: "Delete affected servers and re-add them")
                    }
                }
            }
            .padding()
            
            Divider()
                .background(Color.axBorder)
            
            // Actions
            HStack(spacing: AXSpacing.md) {
                Button {
                    viewModel.dismissDecryptionError()
                } label: {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if viewModel.decryptionError?.requiresRecoveryKey == true {
                    Button {
                        Task {
                            await submitRecoveryKey()
                        }
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Restore Keys")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(recoveryKeyInput.isEmpty || isProcessing)
                }
            }
            .padding()
            .background(Color.axSurface)
        }
        .frame(width: 450)
        .background(Color.axBackground)
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    private var recoveryKeyInputSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Enter Recovery Key:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "key.fill")
                    .foregroundColor(.axAccentBlue)
                
                SecureField("XXXX-XXXX-XXXX-XXXX-XXXX-XXXX", text: $recoveryKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .focused($isInputFocused)
                    .onSubmit {
                        Task {
                            await submitRecoveryKey()
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
            
            Text("The recovery key was provided when you set up encryption")
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
    
    private func submitRecoveryKey() async {
        guard !recoveryKeyInput.isEmpty else { return }
        
        isProcessing = true
        await viewModel.retryDecryptionWithRecoveryKey(recoveryKeyInput)
        isProcessing = false
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.axBackground.ignoresSafeArea()
        
        DecryptionErrorView(viewModel: {
            let vm = ServerListViewModel()
            vm.decryptionError = .authenticationFailure
            vm.showDecryptionError = true
            vm.failedServerIds = ["server1", "server2"]
            return vm
        }())
    }
}
