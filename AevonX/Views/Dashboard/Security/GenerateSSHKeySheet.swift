//
//  GenerateSSHKeySheet.swift
//  AevonX
//
//  Modal wizard launched from SSH Security → "Generate New Key".
//
//  Generates a key pair locally on the device, injects the public half into
//  the connected server's authorized_keys, verifies the inject, and then
//  saves the private half to the Keychain (Touch ID protected).
//
//  All command construction & parsing lives in `KeygenBridge`. This view is
//  pure UI — it never builds a shell string and never decodes JSON.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Stage state machine

enum SSHKeyGenStage {
    case configure
    case generating
    case injecting
    case verifying
    case savingKeychain
    case success(KeygenKeyPair)
    case failed(String)

    var progress: Double {
        switch self {
        case .configure:       return 0.0
        case .generating:      return 0.2
        case .injecting:       return 0.5
        case .verifying:       return 0.7
        case .savingKeychain:  return 0.9
        case .success:         return 1.0
        case .failed:          return 1.0
        }
    }

    var message: String {
        switch self {
        case .configure:       return "Configure"
        case .generating:      return "Generating key pair locally…"
        case .injecting:       return "Injecting public key into authorized_keys…"
        case .verifying:       return "Verifying the key landed on the server…"
        case .savingKeychain:  return "Storing private key in Keychain (Touch ID)…"
        case .success:         return "Done — the new key is active."
        case .failed(let why): return "Failed: \(why)"
        }
    }

    var isInFlight: Bool {
        switch self {
        case .generating, .injecting, .verifying, .savingKeychain: return true
        default: return false
        }
    }
}

// MARK: - Sheet

struct GenerateSSHKeySheet: View {
    let serverId: String
    let username: String
    let onCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var stage: SSHKeyGenStage = .configure
    @State private var keyType: KeygenType = .ed25519
    @State private var comment: String = ""
    @State private var passphrase: String = ""
    @State private var generatedFingerprint: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            header

            switch stage {
            case .configure:
                configureSection
            default:
                progressSection
            }

            Spacer(minLength: 0)

            footer
        }
        .padding(AXSpacing.xl)
        .frame(width: 520)
        .background(Color.axBackground)
        .onAppear {
            if comment.isEmpty {
                comment = defaultComment
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "key.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.axAccentBlue)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text("Generate SSH Key")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
                Text("On this device, then inject the public half to the server")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(stage.isInFlight)
        }
    }

    // MARK: Configure section

    private var configureSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {

            // Algorithm
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Algorithm")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                HStack(spacing: AXSpacing.sm) {
                    ForEach(KeygenType.allCases, id: \.self) { type in
                        algoButton(type)
                    }
                }
            }

            // Comment
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Comment")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                TextField("user@device", text: $comment)
                    .textFieldStyle(.plain)
                    .padding(AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axBackgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
            }

            // Passphrase (optional)
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack {
                    Text("Passphrase")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text("(optional)")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                SecureField("Encrypts the private key on disk", text: $passphrase)
                    .textFieldStyle(.plain)
                    .padding(AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axBackgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
            }

            // Security note
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.axSuccess)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text("Touch ID required at creation")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    Text("The private key is bound to your current biometric set and never leaves this device.")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSuccess.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axSuccess.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }

    private func algoButton(_ type: KeygenType) -> some View {
        let selected = keyType == type
        return Button {
            withAnimation(.spring(response: 0.3)) { keyType = type }
        } label: {
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(type.displayName)
                    .font(AXTypography.headline)
                    .foregroundColor(selected ? .white : .axTextPrimary)
                Text(type.subtitle)
                    .font(AXTypography.caption2)
                    .foregroundColor(selected ? .white.opacity(0.85) : .axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(selected ? Color.axAccentBlue : Color.axBackgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(selected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Progress section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                if case .success = stage {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.axSuccess)
                } else if case .failed = stage {
                    Image(systemName: "xmark.octagon.fill").foregroundColor(.axError)
                } else {
                    ProgressView().scaleEffect(0.7)
                }
                Text(stage.message)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text("\(Int(stage.progress * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axBackgroundTertiary)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressTint)
                        .frame(width: geo.size.width * stage.progress, height: 4)
                        .animation(.easeInOut(duration: 0.4), value: stage.progress)
                }
            }
            .frame(height: 4)

            if case .success(let pair) = stage {
                successDetails(pair)
            }
        }
    }

    private var progressTint: LinearGradient {
        let colors: [Color]
        switch stage {
        case .success: colors = [.axSuccess, .axSuccess.opacity(0.6)]
        case .failed:  colors = [.axError, .axError.opacity(0.6)]
        default:       colors = [.axAccentBlue, .axAccentBlue.opacity(0.6)]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private func successDetails(_ pair: KeygenKeyPair) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Text(pair.type.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axAccentPurple)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(Capsule().fill(Color.axAccentPurple.opacity(0.12)))
                Text(pair.fingerprint)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Text("The matching public key is now in `~/.ssh/authorized_keys`. Existing connections were not interrupted.")
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSuccess.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axSuccess.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: AXSpacing.md) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .disabled(stage.isInFlight)
            .opacity(stage.isInFlight ? 0.5 : 1.0)

            Spacer()

            primaryActionButton
        }
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        switch stage {
        case .configure:
            Button {
                Task { await runPipeline() }
            } label: {
                primaryLabel(text: "Generate & Inject", icon: "key.fill")
            }
            .buttonStyle(.plain)
            .disabled(comment.isEmpty)
            .opacity(comment.isEmpty ? 0.5 : 1.0)

        case .success:
            Button {
                onCompleted()
                dismiss()
            } label: {
                primaryLabel(text: "Done", icon: "checkmark.circle.fill")
            }
            .buttonStyle(.plain)

        case .failed:
            Button {
                stage = .configure
            } label: {
                primaryLabel(text: "Retry", icon: "arrow.clockwise")
            }
            .buttonStyle(.plain)

        default:
            primaryLabel(text: "Working…", icon: nil)
                .opacity(0.5)
        }
    }

    private func primaryLabel(text: String, icon: String?) -> some View {
        HStack(spacing: AXSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(AXTypography.headline)
        }
        .foregroundColor(.white)
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(
            LinearGradient(colors: [.axAccentBlue, .axAccentGreen], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: Pipeline

    /// Drives the full generate → inject → verify → save pipeline.
    /// Each transition is a real operation; no fake progress.
    private func runPipeline() async {
        // 1. Generate locally
        stage = .generating
        let pair: KeygenKeyPair
        do {
            pair = try await KeygenBridge.shared.generate(
                type: keyType,
                comment: comment,
                passphrase: passphrase
            )
        } catch {
            stage = .failed("Generation failed: \(error.localizedDescription)")
            return
        }
        generatedFingerprint = pair.fingerprint

        // 2. Inject via the existing connected SSH session (no password needed —
        //    the server is already trusted in this UI).
        stage = .injecting
        let injectCmd = KeygenBridge.shared.injectPublicKeyCmd(home: home, publicKey: pair.publicKey)
        let injectStdout = await SSHBridge.shared.executeAsync(serverID: serverId, command: injectCmd)
        let outcome = KeygenInjectOutcome.parse(injectStdout)
        guard outcome.isSuccess else {
            stage = .failed("Server rejected the inject: \(outcome)")
            return
        }

        // 3. Verify the key is present on the server
        stage = .verifying
        let verifyCmd = KeygenBridge.shared.verifyKeyInjectedCmd(home: home, publicKey: pair.publicKey)
        let verifyStdout = await SSHBridge.shared.executeAsync(serverID: serverId, command: verifyCmd)
        guard KeygenVerifyOutcome.parse(verifyStdout) == .present else {
            stage = .failed("Could not confirm the key was written.")
            return
        }

        // 4. Save private key to Keychain (Touch ID).
        stage = .savingKeychain
        do {
            _ = try await KeygenKeyStorage.shared.save(
                pair: pair,
                serverID: serverId,
                reason: "Save the new SSH key to your Keychain"
            )
        } catch {
            stage = .failed("Keychain save failed: \(error.localizedDescription)")
            return
        }

        stage = .success(pair)
    }

    // MARK: Helpers

    private var home: String {
        username == "root" ? "/root" : "/home/\(username)"
    }

    private var defaultComment: String {
        let host = ProcessInfo.processInfo.hostName.split(separator: ".").first.map(String.init) ?? "device"
        return "aevonx@\(host)"
    }
}
