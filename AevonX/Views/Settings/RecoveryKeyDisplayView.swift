//
//  RecoveryKeyDisplayView.swift
//  AevonX
//
//  Displays the Recovery Key to the user with proper security warnings
//  The Recovery Key is shown ONLY ONCE during account creation
//

import SwiftUI
import AevonXCoreBridge
import Combine

struct RecoveryKeyDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecoveryKeyDisplayViewModel()
    @State private var showKey = false
    @State private var hasConfirmedStorage = false
    @State private var showWarning = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Header with icon
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.axAccentBlue.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.axAccentBlue)
                    }
                    
                    Text(L10n.Recovery.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.axTextPrimary)
                    
                    Text(L10n.Recovery.writeDownNow)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AXSpacing.xxl)
                
                // Critical Warning
                if showWarning {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.axError)
                                .font(.title2)
                            
                            Text(L10n.Recovery.criticalWarning)
                                .font(AXTypography.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.axError)
                        }
                        
                        Text(L10n.Recovery.lossWarning)
                            .font(AXTypography.callout)
                            .foregroundColor(.axTextSecondary)
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axError.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axError.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .frame(maxWidth: 400)
                }
                
                // Recovery Key Display
                VStack(spacing: AXSpacing.md) {
                    if viewModel.recoveryKey != nil {
                        // Key display box
                        VStack(spacing: AXSpacing.sm) {
                            if showKey {
                                Text(viewModel.recoveryKey!)
                                    .font(.system(size: 18, design: .monospaced))
                                    .foregroundColor(.axAccentBlue)
                                    .lineLimit(nil)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axAccentBlue.opacity(0.5), lineWidth: 2)
                                    )
                            } else {
                                // Masked key display
                                HStack(spacing: AXSpacing.sm) {
                                    Text("••••••••••••••••••••••••••••••••")
                                        .font(.system(size: 18, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                            }
                            
                            // Toggle visibility button
                            Button(action: { showKey.toggle() }) {
                                HStack {
                                    Image(systemName: showKey ? "eye.slash" : "eye")
                                    Text(showKey ? "Hide Key" : "Show Key")
                                }
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Copy button
                        Button(action: {
                            Task {
                                await viewModel.copyKeyToClipboard()
                            }
                        }) {
                            HStack {
                                Image(systemName: viewModel.copied ? "checkmark" : "doc.on.doc")
                                Text(viewModel.copied ? "Copied!" : "Copy to Clipboard")
                            }
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: .infinity)
                            .padding(AXSpacing.md)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.copied)
                    } else {
                        // Generate key button
                        Button(action: {
                            Task {
                                await viewModel.generateRecoveryKey()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .axBackground))
                                    .frame(maxWidth: .infinity)
                                    .padding(AXSpacing.md)
                                    .background(Color.axAccentBlue)
                                    .cornerRadius(AXCornerRadius.md)
                            } else {
                                HStack {
                                    Image(systemName: "key.fill")
                                    Text(L10n.Recovery.generate)
                                }
                                .font(AXTypography.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.axBackground)
                                .frame(maxWidth: .infinity)
                                .padding(AXSpacing.md)
                                .background(Color.axAccentBlue)
                                .cornerRadius(AXCornerRadius.md)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isLoading)
                    }
                }
                .frame(maxWidth: 400)
                
                // Confirmation checkbox
                VStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.sm) {
                        Button(action: { hasConfirmedStorage.toggle() }) {
                            Image(systemName: hasConfirmedStorage ? "checkmark.square.fill" : "square")
                                .foregroundColor(hasConfirmedStorage ? .axAccentBlue : .axTextMuted)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Recovery.storedSecurely)
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextPrimary)
                            
                            Text(L10n.Recovery.understandLoss)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                    .frame(maxWidth: 400, alignment: .leading)
                    
                    // Dismiss warning button
                    Button(action: { showWarning = false }) {
                        Text(L10n.Recovery.readWarning)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    if viewModel.recoveryKey != nil && hasConfirmedStorage {
                        // Save that user has acknowledged the key
                        viewModel.markKeyAsAcknowledged()
                        dismiss()
                    }
                }) {
                    Text(L10n.Button.continue)
                        .font(AXTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(viewModel.recoveryKey != nil && hasConfirmedStorage ? Color.axAccentBlue : Color.axTextMuted)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.recoveryKey == nil || !hasConfirmedStorage)
                .frame(maxWidth: 400)
                .padding(.bottom, AXSpacing.xl)
            }
            .padding(.horizontal, AXSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
        .onAppear {
            Task {
                await viewModel.checkExistingKey()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class RecoveryKeyDisplayViewModel: ObservableObject {
    @Published var recoveryKey: String?
    @Published var isLoading = false
    @Published var copied = false
    @Published var acknowledged = false
    @Published var errorMessage: String?
    
    func checkExistingKey() async {
        let hasKey = EncryptionKeyStore.shared.hasKey()
        if hasKey {
            // Key exists but we don't show it in plaintext after setup
            self.acknowledged = true
        }
    }
    
    func generateRecoveryKey() async {
        isLoading = true
        errorMessage = nil
        
        let key = await EncryptionKeyStore.shared.generateKey()
        self.recoveryKey = key
        debugLog("[RecoveryKeyDisplayView] ENCRYPTION: SUCCESS - Encryption key generated")
        
        isLoading = false
    }
    
    func copyKeyToClipboard() async {
        guard let key = recoveryKey else { return }
        
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(key, forType: .string)
        #else
        UIPasteboard.general.string = key
        #endif
        
        copied = true
        debugLog("[RecoveryKeyDisplayView] INFO: Encryption key copied to clipboard")
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        copied = false
    }
    
    func markKeyAsAcknowledged() {
        acknowledged = true
    }
}

#Preview {
    RecoveryKeyDisplayView()
        .background(Color.axBackground)
}
