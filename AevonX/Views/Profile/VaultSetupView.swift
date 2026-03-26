//
//  VaultSetupView.swift
//  AevonX
//
//  Encryption vault setup with "No Recovery" warning
//

import SwiftUI
import AevonXCoreBridge
import Combine

struct VaultSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VaultSetupViewModel()
    
    /// When used as a blocking gate, these replace dismiss behavior
    var onComplete: (() -> Void)? = nil
    var onSignOut: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AXSpacing.xxl) {
            if viewModel.isComplete || viewModel.mode == .success {
                SuccessView(dismiss: { handleComplete() })
            } else if viewModel.mode == .recover {
                RecoveryEntryView(viewModel: viewModel, dismiss: { handleDismiss() }, signOut: onSignOut)
            } else {
                SetupGenerationView(viewModel: viewModel, dismiss: { handleDismiss() }, signOut: onSignOut)
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackground)
    }
    
    private func handleComplete() {
        if let onComplete { onComplete() } else { dismiss() }
    }
    
    private func handleDismiss() {
        if let onSignOut { onSignOut() } else { dismiss() }
    }
}

// MARK: - Setup Generation View
struct SetupGenerationView: View {
    @ObservedObject var viewModel: VaultSetupViewModel
    var dismiss: (() -> Void)
    var signOut: (() -> Void)? = nil
    
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
                
                Text(L10n.Recovery.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                Text(L10n.Vault.keyDescription)
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
                    
                    Text(L10n.Vault.secureStorageRequired)
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
                
                Text(L10n.Recovery.storedSecurely)
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
                        Text(L10n.Vault.finishSetup)
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
                    HStack(spacing: AXSpacing.xs) {
                        if signOut != nil {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        Text(signOut != nil ? L10n.Profile.signOut : L10n.Button.cancel)
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(signOut != nil ? .axError : .axTextSecondary)
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
    var signOut: (() -> Void)? = nil
    
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
                
                Text(L10n.Vault.enterRecoveryKey)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                Text(L10n.Vault.enterKeyInstruction)
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
                Label(L10n.Vault.zeroKnowledge, systemImage: "shield.lefthalf.filled")
                    .font(AXTypography.subheadline)
                    .fontWeight(.bold)
                
                Text(L10n.Vault.verifyLocally)
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
                        Text(L10n.Vault.verifyUnlock)
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
                    HStack(spacing: AXSpacing.xs) {
                        if signOut != nil {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        Text(signOut != nil ? L10n.Profile.signOut : L10n.Button.cancel)
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(signOut != nil ? .axError : .axTextSecondary)
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

    @State private var shieldScale: CGFloat = 0.5
    @State private var shieldOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var pulse: Bool = false
    @State private var orb1Offset: CGSize = .init(width: -60, height: -80)
    @State private var orb2Offset: CGSize = .init(width: 80, height: 60)

    var body: some View {
        ZStack {
            // Ambient gradient orbs
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.25), Color.clear],
                            center: .center, startRadius: 0, endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(orb1Offset)
                    .blur(radius: 30)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.axAccentBlue.opacity(0.2), Color.clear],
                            center: .center, startRadius: 0, endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(orb2Offset)
                    .blur(radius: 25)
            }
            .animation(
                .easeInOut(duration: 4).repeatForever(autoreverses: true),
                value: orb1Offset
            )

            VStack(spacing: 0) {
                Spacer()

                // Shield icon with pulse rings
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(Color.green.opacity(pulse ? 0 : 0.3), lineWidth: 2)
                        .frame(width: pulse ? 160 : 110, height: pulse ? 160 : 110)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)

                    // Middle ring
                    Circle()
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Main icon background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.25),
                                        Color.green.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 86, height: 86)
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.35), lineWidth: 1)
                            )

                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#4ade80"), Color(hex: "#22c55e")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.green.opacity(0.5), radius: 12, x: 0, y: 4)
                    }
                    .scaleEffect(shieldScale)
                    .opacity(shieldOpacity)
                }
                .padding(.bottom, 36)

                // Text content
                VStack(spacing: 12) {
                    Text(L10n.Vault.secured)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "#e2e8f0")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                    Text("Your encryption key is safely locked in your device's secure storage. Your server credentials are protected by zero-knowledge encryption.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 340)
                }
                .padding(.bottom, 32)
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                // Feature chips
                HStack(spacing: 10) {
                    SuccessChip(icon: "lock.fill", label: "End-to-End", color: .green)
                    SuccessChip(icon: "eye.slash.fill", label: "Zero-Knowledge", color: .axAccentBlue)
                    SuccessChip(icon: "icloud.slash.fill", label: "Local Key", color: Color(hex: "#a78bfa"))
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                .padding(.bottom, 40)

                // CTA Button
                Button(action: { dismiss() }) {
                    HStack(spacing: 10) {
                        Text(L10n.Vault.enterApp)
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#4ade80"), Color(hex: "#22d3ee")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.green.opacity(0.35), radius: 16, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()
            }
        }
        .onAppear {
            // Orb animation
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                orb1Offset = CGSize(width: -40, height: -50)
                orb2Offset = CGSize(width: 50, height: 40)
            }
            // Shield entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
                shieldScale = 1.0
                shieldOpacity = 1.0
            }
            // Ring fade
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }
            // Content slide up
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
            // Pulse start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                pulse = true
            }
        }
    }
}

// MARK: - Success Chip
private struct SuccessChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .clipShape(Capsule())
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
                Text(L10n.Auth.passwordStrength)
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
        
        // 1. Check if key already exists locally
        let hasKey = EncryptionKeyStore.shared.hasKey()
        
        if hasKey {
            self.mode = .success
            self.isComplete = true
            isLoading = false
            return
        }
        
        // 2. No local key — check server for key hash via Go HTTP
        let token = await AuthService.shared.getToken() ?? ""
        let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let resultJSON = await APIBridge.shared.checkRecoveryKeyStatusAsync(baseURL: baseURL, token: token)
        
        if let data = resultJSON.data(using: .utf8),
           let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           result["success"] as? Bool == true,
           let respData = result["data"] as? [String: Any],
           let hasKey = respData["has_recovery_key"] as? Bool {
            if hasKey {
                self.mode = .recover
            } else {
                self.mode = .generate
                await generateKey()
            }
        } else {
            // Fallback to recover — safer to ask for existing key
            self.mode = .recover
        }
        isLoading = false
    }
    
    func generateKey() async {
        recoveryKey = await EncryptionKeyStore.shared.generateKey()
    }
    
    func verifyAndRestore() async {
        isLoading = true
        errorMessage = nil
        
        let normalizedKey = enteredKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !normalizedKey.isEmpty else {
            errorMessage = "Please enter your encryption key."
            isLoading = false
            return
        }
        
        do {
            // Compute hash of entered key
            let keyHash = await EncryptionKeyStore.shared.hashKey(normalizedKey)
            
            // Verify against server hash via Go HTTP
            let token = await AuthService.shared.getToken() ?? ""
            let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let resultJSON = await APIBridge.shared.verifyRecoveryKeyAsync(baseURL: baseURL, token: token, verifierHash: keyHash)
            
            var verified = false
            if let data = resultJSON.data(using: .utf8),
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               result["success"] as? Bool == true,
               let respData = result["data"] as? [String: Any],
               let v = respData["verified"] as? Bool {
                verified = v
            }
            
            if verified {
                // Save to Keychain
                try await EncryptionKeyStore.shared.saveKey(normalizedKey)
                
                self.mode = .success
                self.isComplete = true
                print("[VaultSetup] SUCCESS - Key verified and saved to Keychain")
            } else {
                errorMessage = "Encryption key is incorrect. Please try again."
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
        
        guard hasAcknowledgedWarning else {
            errorMessage = "You must acknowledge the warning to continue"
            isLoading = false
            return
        }
        
        guard hasCopiedKey else {
            errorMessage = "Please copy your encryption key before proceeding"
            isLoading = false
            return
        }
        
        do {
            // 1. Save key to Keychain
            try await EncryptionKeyStore.shared.saveKey(recoveryKey)
            
            // 2. Register key hash with server via Go HTTP
            let keyHash = await EncryptionKeyStore.shared.hashKey(recoveryKey)
            let token = await AuthService.shared.getToken() ?? ""
            let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let resultJSON = await APIBridge.shared.registerRecoveryKeyAsync(
                baseURL: baseURL, token: token,
                verifierHash: keyHash, salt: ""
            )
            
            if let data = resultJSON.data(using: .utf8),
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               result["success"] as? Bool != true {
                let msg = (result["error"] as? [String: Any])?["message"] as? String ?? "Unknown error"
                throw NSError(domain: "VaultSetup", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            
            self.mode = .success
            isComplete = true
            print("[VaultSetup] SUCCESS - Key saved and registered")
            
        } catch {
            errorMessage = "Failed to setup encryption: \(error.localizedDescription)"
            print("[VaultSetup] FAILED - \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
}

#Preview {
    VaultSetupView()
        .background(Color.axBackground)
}
