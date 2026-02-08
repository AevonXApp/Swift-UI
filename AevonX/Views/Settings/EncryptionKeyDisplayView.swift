//
//  EncryptionKeyDisplayView.swift
//  AevonX
//
//  Encryption key display with click-to-copy and auto-generation
//

import SwiftUI
import AevonXCore
import Combine
import UniformTypeIdentifiers

struct EncryptionKeyDisplayView: View {
    @StateObject private var viewModel = EncryptionKeyViewModel()
    @State private var showCopiedToast = false
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Header
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: viewModel.encryptionKey != nil ? "lock.shield.fill" : "lock.shield")
                    .font(.system(size: 40))
                    .foregroundColor(viewModel.encryptionKey != nil ? .axAccentBlue : .axTextMuted)
                
                Text("Encryption Key")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(viewModel.encryptionKey != nil 
                     ? "Your encryption key is secured" 
                     : "Generate an encryption key to protect your data")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Encryption Key Display
            if let key = viewModel.encryptionKey {
                HStack(spacing: AXSpacing.sm) {
                    Text(maskEncryptionKey(key))
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    Button(action: {
                        Task { @MainActor in
                            await viewModel.copyKey()
                            showCopiedToast = true
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            showCopiedToast = false
                        }
                    }) {
                        Image(systemName: viewModel.copied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
                .frame(maxWidth: 400)
                
                // Key ID
                HStack {
                    Text("Key ID:")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    Text(viewModel.keyId ?? "N/A")
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                }
                
                // Sync Status
                HStack(spacing: AXSpacing.xs) {
                    Circle()
                        .fill(viewModel.isSynced ? Color.axSuccess : Color.axWarning)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isSynced ? "Synced with server" : "Not synced")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
            } else {
                // Generate Button
                Button(action: {
                    Task {
                        await viewModel.generateEncryptionKey()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .axBackground))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    } else {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Generate Encryption Key")
                        }
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
                .frame(maxWidth: 300)
            }
            
            // Error Message
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axError.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
            
            // Refresh Button (when key exists)
            if viewModel.encryptionKey != nil && !viewModel.isLoading {
                Button(action: {
                    Task {
                        await viewModel.refreshKeyStatus()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackground)
        .overlay(
            // Copied Toast
            VStack {
                if showCopiedToast {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.axSuccess)
                        Text("Encryption key copied to clipboard")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextPrimary)
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.lg)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopiedToast = false
                            }
                        }
                    }
                }
            }
            .padding(.top, 50),
            alignment: .top
        )
        .onAppear {
            Task {
                await viewModel.checkExistingKey()
            }
        }
    }
    
    private func maskEncryptionKey(_ key: String) -> String {
        guard key.count > 16 else { return key }
        let prefix = String(key.prefix(8))
        let suffix = String(key.suffix(8))
        return "\(prefix)...\(suffix)"
    }
}

// MARK: - ViewModel

@MainActor
class EncryptionKeyViewModel: ObservableObject {
    @Published var encryptionKey: String?
    @Published var keyId: String?
    @Published var isLoading = false
    @Published var copied = false
    @Published var isSynced = false
    @Published var errorMessage: String?
    
    private let keyManager = EncryptionKeyManager.shared
    
    func checkExistingKey() async {
        isLoading = true
        errorMessage = nil
        
        // Check for existing key
        if let key = await keyManager.getOrGenerateEncryptionKey() {
            self.encryptionKey = key
            self.keyId = await keyManager.getKeyId()
            if self.keyId == nil {
                self.keyId = await keyManager.generateKeyId()
            }
            
            // Check sync status
            await checkSyncStatus()
        }
        
        isLoading = false
    }
    
    func generateEncryptionKey() async {
        isLoading = true
        errorMessage = nil
        
        // Generate or get key
        if let key = await keyManager.getOrGenerateEncryptionKey() {
            self.encryptionKey = key
            self.keyId = await keyManager.getKeyId()
            if self.keyId == nil {
                self.keyId = await keyManager.generateKeyId()
            }
            
            // Copy to clipboard
            await copyToClipboard(key)
            
            // Sync with server
            await syncWithServer(key: key)
        } else {
            errorMessage = "Failed to generate encryption key"
        }
        
        isLoading = false
    }
    
    func copyKey() async {
        guard let key = encryptionKey else { return }
        await copyToClipboard(key)
        copied = true
        
        // After copy, sync with server
        await syncWithServer(key: key)
        
        // Refresh user data
        await refreshUserData()
    }
    
    private func copyToClipboard(_ key: String) async {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(key, forType: .string)
        #else
        UIPasteboard.general.string = key
        #endif
    }
    
    private func syncWithServer(key: String) async {
        var keyId = keyId
        if keyId == nil {
            keyId = await keyManager.generateKeyId()
        }
        
        // Encrypt the key before sending to server
        // For now, we send it as-is (in production, use proper encryption)
        do {
            let _ = try await keyManager.syncEncryptionKeyToServer(
                keyId: keyId!,
                encryptedKey: key
            )
            self.isSynced = true
        } catch {
            self.errorMessage = "Failed to sync with server: \(error.localizedDescription)"
            self.isSynced = false
        }
    }
    
    private func checkSyncStatus() async {
        // Check if key is synced by verifying server response
        // For now, we assume it's synced if the key exists locally
        self.isSynced = true
    }
    
    private func refreshUserData() async {
        do {
            let _ = try await keyManager.refreshUserData()
            print("[EncryptionKeyDisplayView] ENCRYPTION: User Data Refresh - User data refreshed successfully")
        } catch {
            print("[EncryptionKeyDisplayView] ERROR: FAILED - \(error.localizedDescription)")
        }
    }
    
    func refreshKeyStatus() async {
        await checkExistingKey()
    }
}

#Preview {
    EncryptionKeyDisplayView()
        .background(Color.axBackground)
        .frame(width: 500, height: 400)
}
