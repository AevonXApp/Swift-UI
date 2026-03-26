//
//  EncryptionKeyDisplayView.swift
//  AevonX
//
//  Backup key view — authenticates with native Apple biometric, then shows key
//

import SwiftUI
import AevonXCoreBridge
import Combine

struct EncryptionKeyDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var encryptionKey: String?
    @State private var isLoading = true
    @State private var copied = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding([.top, .trailing], AXSpacing.lg)
            
            Spacer()
            
            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(L10n.Encryption.verifyingIdentity)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
            } else if let key = encryptionKey {
                keyView(key: key)
            } else {
                failedView
            }
            
            Spacer()
        }
        .frame(minWidth: 480, minHeight: 380)
        .background(Color.axBackground)
        .task {
            await authenticateAndLoadKey()
        }
    }
    
    // MARK: - Authenticate + Load
    
    private func authenticateAndLoadKey() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Native Apple biometric (Touch ID / Face ID system dialog)
            try await EncryptionKeyStore.shared.authenticateWithBiometric()
            
            // Step 2: If biometric passed, read key from Keychain
            let key = try await EncryptionKeyStore.shared.getKey()
            self.encryptionKey = key
        } catch EncryptionKeyStoreError.biometricAuthFailed {
            errorMessage = "Authentication cancelled."
        } catch EncryptionKeyStoreError.biometricNotAvailable {
            // No biometric on this device — just show the key directly
            do {
                let key = try await EncryptionKeyStore.shared.getKey()
                self.encryptionKey = key
            } catch {
                errorMessage = "No encryption key found."
            }
        } catch EncryptionKeyStoreError.keyNotFound {
            errorMessage = "No encryption key found."
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Key View
    
    private func keyView(key: String) -> some View {
        VStack(spacing: AXSpacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.axSuccess.opacity(0.1))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "key.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.axSuccess)
            }
            
            VStack(spacing: AXSpacing.xs) {
                Text(L10n.Encryption.yourKey)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(L10n.Encryption.saveSecurely)
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
            
            VStack(spacing: AXSpacing.md) {
                Text(key)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                    .padding(AXSpacing.lg)
                    .frame(maxWidth: 400)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(Color.axSuccess.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.lg)
                
                Button(action: { copyKey(key) }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy to Clipboard")
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(copied ? .axSuccess : .axAccentBlue)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(copied ? Color.axSuccess.opacity(0.1) : Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.axWarning)
                Text(L10n.Encryption.keyHiddenOnClose)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }
        }
    }
    
    // MARK: - Failed View
    
    private var failedView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.axError)
            
            Text(errorMessage ?? "Could not retrieve key")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)
            
            Button(action: { Task { await authenticateAndLoadKey() } }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text(L10n.Button.tryAgain)
                }
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helpers
    
    private func copyKey(_ key: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(key, forType: .string)
        #else
        UIPasteboard.general.string = key
        #endif
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { copied = false }
    }
}

#Preview {
    EncryptionKeyDisplayView()
        .background(Color.axBackground)
        .frame(width: 500, height: 400)
}
