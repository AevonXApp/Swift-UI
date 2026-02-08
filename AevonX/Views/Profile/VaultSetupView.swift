//
//  VaultSetupView.swift
//  AevonX
//
//  Encryption vault setup with "No Recovery" warning
//

import SwiftUI
import AevonXCore
import Combine

struct VaultSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VaultSetupViewModel()
    
    var body: some View {
        VStack(spacing: AXSpacing.xxl) {
            if viewModel.isComplete || viewModel.mode == .success {
                SuccessView(dismiss: { dismiss() })
            } else if viewModel.mode == .recover {
                RecoveryEntryView(viewModel: viewModel, dismiss: { dismiss() })
            } else {
                SetupGenerationView(viewModel: viewModel, dismiss: { dismiss() })
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackground)
    }
}

// MARK: - Setup Generation View
struct SetupGenerationView: View {
    @ObservedObject var viewModel: VaultSetupViewModel
    var dismiss: (() -> Void)
    
    var body: some View {
        VStack(spacing: AXSpacing.xxl) {
            Spacer()
            
            // Header
            VStack(spacing: AXSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.axAccentBlue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.axAccentBlue)
                }
                
                Text("Your Recovery Key")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text("This 256-bit key is the ONLY way to access your encrypted data. We do not store it.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            // Recovery Key Box
            VStack(spacing: AXSpacing.md) {
                Text(viewModel.recoveryKey)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(AXSpacing.xl)
                    .frame(maxWidth: 400)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                
                Button(action: {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.recoveryKey, forType: .string)
                    #endif
                    viewModel.hasCopiedKey = true
                }) {
                    HStack {
                        Image(systemName: viewModel.hasCopiedKey ? "checkmark" : "doc.on.doc")
                        Text(viewModel.hasCopiedKey ? "Copied" : "Copy to Clipboard")
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
            
            // Warning Banner
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.axError)
                        .font(.title3)
                    
                    Text("SECURE STORAGE REQUIRED")
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.axError)
                }
                
                Text("Store this key in a physical safe or a secure password manager. If you lose this key, your server credentials will be permanently lost. AevonX is a zero-knowledge platform and has NO way to recover it.")
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AXSpacing.lg)
            .background(Color.axError.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axError.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.md)
            .frame(maxWidth: 400)
            
            // Confirmation Checkbox
            HStack(spacing: AXSpacing.sm) {
                Button(action: { viewModel.hasAcknowledgedWarning.toggle() }) {
                    Image(systemName: viewModel.hasAcknowledgedWarning ? "checkmark.square.fill" : "square")
                        .foregroundColor(viewModel.hasAcknowledgedWarning ? .axAccentBlue : .axTextMuted)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("I have securely saved my Recovery Key")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            .frame(maxWidth: 400, alignment: .leading)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: AXSpacing.md) {
                Button(action: {
                    Task {
                        await viewModel.createVault()
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
                        Text("Finish Setup")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(viewModel.canCreateVault ? Color.axAccentBlue : Color.axTextMuted)
                            .cornerRadius(AXCornerRadius.md)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!viewModel.canCreateVault || viewModel.isLoading)
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
            }
            .frame(maxWidth: 400)
            
            Spacer()
        }
    }
}

// MARK: - Recovery Entry View
struct RecoveryEntryView: View {
    @ObservedObject var viewModel: VaultSetupViewModel
    var dismiss: (() -> Void)
    
    var body: some View {
        VStack(spacing: AXSpacing.xxl) {
            Spacer()
            
            // Header
            VStack(spacing: AXSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.axAccentBlue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 32))
                        .foregroundColor(.axAccentBlue)
                }
                
                Text("Enter Recovery Key")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text("Enter the 256-bit Recovery Key you saved when setting up your account.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            // Input Box
            VStack(spacing: AXSpacing.md) {
                TextEditor(text: $viewModel.enteredKey)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .padding(AXSpacing.md)
                    .frame(height: 100)
                    .frame(maxWidth: 400)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .frame(maxWidth: 400, alignment: .leading)
                }
            }
            
            // Security Reinsurance
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Label("Zero-Knowledge Security", systemImage: "shield.lefthalf.filled")
                    .font(AXTypography.subheadline)
                    .fontWeight(.bold)
                
                Text("Your key will be verified locally and matched against a one-way hash on our server. We never see your raw key.")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.md)
            .background(Color.axAccentBlue.opacity(0.05))
            .cornerRadius(AXCornerRadius.md)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: AXSpacing.md) {
                Button(action: {
                    Task {
                        await viewModel.verifyAndRestore()
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
                        Text("Verify & Unlock")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(viewModel.canCreateVault ? Color.axAccentBlue : Color.axTextMuted)
                            .cornerRadius(AXCornerRadius.md)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!viewModel.canCreateVault || viewModel.isLoading)
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
            }
            .frame(maxWidth: 400)
            
            Spacer()
        }
    }
}

// MARK: - Success View
struct SuccessView: View {
    var dismiss: (() -> Void)
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.axSuccess.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.axSuccess)
            }
            
            Text("Vault Secured")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            
            VStack(spacing: AXSpacing.md) {
                Text("Your Recovery Key is now securely stored in your device's Keychain.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                
                Text("Every time you open the app, it will use this key to unlock your server data automatically.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 400)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Great, let's go!")
                    .font(AXTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: 300)
            
            Spacer()
        }
    }
}

// MARK: - Password Strength View

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        calculateStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text("Password Strength:")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                Text(strength.label)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strength.color)
            }
            
            // Strength bars
            HStack(spacing: AXSpacing.xs) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .fill(index < strength.level ? strength.color : Color.axBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            // Requirements
            VStack(alignment: .leading, spacing: 4) {
                RequirementRow(text: "At least 12 characters", met: password.count >= 12)
                RequirementRow(text: "Contains uppercase letter", met: password.contains(where: { $0.isUppercase }))
                RequirementRow(text: "Contains lowercase letter", met: password.contains(where: { $0.isLowercase }))
                RequirementRow(text: "Contains number", met: password.contains(where: { $0.isNumber }))
                RequirementRow(text: "Contains special character", met: password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }))
            }
        }
    }
    
    private func calculateStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { score += 1 }
        
        switch score {
        case 0...2:
            return PasswordStrength(level: 1, label: "Weak", color: .axError)
        case 3...4:
            return PasswordStrength(level: 2, label: "Fair", color: .axWarning)
        case 5:
            return PasswordStrength(level: 3, label: "Good", color: .axInfo)
        default:
            return PasswordStrength(level: 4, label: "Strong", color: .axSuccess)
        }
    }
}

struct PasswordStrength {
    let level: Int
    let label: String
    let color: Color
}

struct RequirementRow: View {
    let text: String
    let met: Bool
    
    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .axSuccess : .axTextMuted)
                .font(.system(size: 10))
            
            Text(text)
                .font(AXTypography.caption)
                .foregroundColor(met ? .axTextSecondary : .axTextMuted)
        }
    }
}

// MARK: - ViewModel

@MainActor
class VaultSetupViewModel: ObservableObject {
    enum SetupMode {
        case generate   // For new accounts
        case recover    // For existing accounts on new devices
        case success    // After completion
    }
    
    @Published var mode: SetupMode = .generate
    @Published var recoveryKey = ""
    @Published var enteredKey = "" // For recovery mode
    @Published var hasAcknowledgedWarning = false
    @Published var hasCopiedKey = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isComplete = false
    
    var canCreateVault: Bool {
        if mode == .generate {
            return !recoveryKey.isEmpty && hasAcknowledgedWarning && hasCopiedKey
        } else if mode == .recover {
            return !enteredKey.isEmpty
        }
        return false
    }
    
    init() {
        Task {
            await determineMode()
        }
    }
    
    func determineMode() async {
        isLoading = true
        
        // 1. Check local Keychain first
        if await RecoveryKeyManager.shared.hasRecoveryKey() {
            if let existingKey = await RecoveryKeyManager.shared.getRecoveryKey() {
                self.recoveryKey = existingKey
                self.mode = .success
                self.isComplete = true
                isLoading = false
                return
            }
        }
        
        // 2. Local is empty, check server
        do {
            let status = try await VaultAPIService.shared.checkRecoveryKeyStatus()
            if status.hasRecoveryKey {
                // Server has a key, but local Keychain is empty -> Recovery Mode
                self.mode = .recover
            } else {
                // New user -> Generation Mode
                self.mode = .generate
                await generateKey()
            }
        } catch {
            // Fallback to generate if server check fails
            self.mode = .generate
            await generateKey()
        }
        isLoading = false
    }
    
    func generateKey() async {
        if let key = await RecoveryKeyManager.shared.generateRecoveryKey() {
            recoveryKey = key
        }
    }
    
    func verifyAndRestore() async {
        isLoading = true
        errorMessage = nil
        
        print("[VaultSetup] Starting Recovery Key verification and restoration")
        
        do {
            // 1. Fetch security parameters from server
            _ = try await VaultAPIService.shared.checkRecoveryKeyStatus()
            
            // 2. Derive verifier hash from entered key
            // Normalize: uppercase and remove leading/trailing whitespace
            let normalizedKey = enteredKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            
            guard let keyData = normalizedKey.data(using: .utf8) else {
                errorMessage = "Invalid key format. Please check your Recovery Key."
                isLoading = false
                return
            }
            
            // Fetch salt from server (needed for derivation)
            let keyStatus = try await VaultAPIService.shared.checkRecoveryKeyStatus()
            
            guard let saltString = keyStatus.salt, let salt = Data(base64Encoded: saltString) else {
                errorMessage = "Could not retrieve security parameters from server."
                isLoading = false
                return
            }
            
            // Derive verifier locally
            guard let verifierKey = await HKDFKeyDerivation.shared.deriveKey(
                from: keyData,
                salt: salt,
                info: "AevonX-Verifier-Key".data(using: .utf8)!,
                keyLength: 32
            ) else {
                errorMessage = "Failed to process key."
                isLoading = false
                return
            }
            
            guard let verifierHashData = await Argon2KeyDerivation.shared.deriveKey(
                from: verifierKey,
                salt: salt
            ) else {
                errorMessage = "Failed to generate security hash."
                isLoading = false
                return
            }
            
            let verifierHash = verifierHashData.base64EncodedString()
            
            // 3. Verify with server
            let verification = try await VaultAPIService.shared.verifyRecoveryKey(verifierHash: verifierHash)
            
            if verification.verified {
                // 4. If correct, save to Keychain
                _ = await RecoveryKeyManager.shared.saveExistingRecoveryKey(keyData, salt: salt)
                
                self.mode = .success
                self.isComplete = true
                print("[VaultSetup] SUCCESS - Recovery Key verified and restored to Keychain")
            } else {
                errorMessage = "Recovery Key is incorrect. Please try again."
            }
            
        } catch {
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("[VaultSetup] FAILED - \(error.localizedDescription)")
        }
        
        isLoading = false
    }

    func createVault() async {
        isLoading = true
        errorMessage = nil
        
        if mode == .recover {
            await verifyAndRestore()
            return
        }
        
        print("[VaultSetup] Starting Recovery Key registration")
        
        // Validate acknowledgment
        guard hasAcknowledgedWarning else {
            errorMessage = "You must acknowledge the warning to continue"
            isLoading = false
            return
        }
        
        guard hasCopiedKey else {
            errorMessage = "Please copy your Recovery Key before proceeding"
            isLoading = false
            return
        }
        
        do {
            // Get verifier hash for server
            guard let verifierHash = await RecoveryKeyManager.shared.getVerifierHash() else {
                errorMessage = "Failed to generate verifier hash"
                isLoading = false
                return
            }
            
            guard let keys = await RecoveryKeyManager.shared.deriveEncryptionKeys() else {
                errorMessage = "Failed to derive encryption keys"
                isLoading = false
                return
            }
            
            let saltBase64 = keys.salt.base64EncodedString()
            
            // Register with server
            _ = try await VaultAPIService.shared.registerRecoveryKey(
                verifierHash: verifierHash,
                salt: saltBase64
            )
            
            self.mode = .success
            isComplete = true
            print("[VaultSetup] SUCCESS - Recovery Key registered with server")
            
        } catch {
            errorMessage = "Failed to register vault: \(error.localizedDescription)"
            print("[VaultSetup] FAILED - \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
}

#Preview {
    VaultSetupView()
        .background(Color.axBackground)
}
