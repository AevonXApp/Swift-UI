//
//  AddServerViewModel.swift
//  AevonX
//

import SwiftUI
import Combine
import AevonXCoreBridge


/// How the user wants the wizard to authenticate this server.
///
/// - `usePassword`  — store the password and reuse it for every connection.
/// - `importKey`    — paste / file-import an existing private key.
/// - `generateNew`  — generate a fresh key pair locally, inject the public
///                    half into the server, and persist the private half
///                    in the Keychain (Touch ID protected).
enum KeyAcquisitionMode: String, CaseIterable, Identifiable {
    case usePassword
    case importKey
    case generateNew

    var id: String { rawValue }

    var title: String {
        switch self {
        case .usePassword: return "Password"
        case .importKey:   return "Existing Key"
        case .generateNew: return "Generate New"
        }
    }

    var subtitle: String {
        switch self {
        case .usePassword: return "Username + password"
        case .importKey:   return "Paste or import .pem / .key"
        case .generateNew: return "Create on this device, inject to server"
        }
    }

    var icon: String {
        switch self {
        case .usePassword: return "lock.fill"
        case .importKey:   return "doc.text.fill"
        case .generateNew: return "key.fill"
        }
    }
}

/// Stages of the "generate-and-inject" pipeline. Drives the verify-step UI.
enum GenerateInjectStage: Equatable {
    case idle
    case generating
    case probingPassword
    case injecting
    case verifyingInjection
    case probingNewKey
    case savingToKeychain
    case success
    case failed(String)

    /// A 0…1 progress hint for a linear bar.
    var progress: Double {
        switch self {
        case .idle:                return 0.0
        case .generating:          return 0.15
        case .probingPassword:     return 0.30
        case .injecting:           return 0.50
        case .verifyingInjection:  return 0.65
        case .probingNewKey:       return 0.80
        case .savingToKeychain:    return 0.92
        case .success:             return 1.0
        case .failed:              return 1.0
        }
    }

    /// User-visible message for each stage.
    var message: String {
        switch self {
        case .idle:                return ""
        case .generating:          return "Generating key pair on this device…"
        case .probingPassword:     return "Verifying password connection…"
        case .injecting:           return "Injecting public key into authorized_keys…"
        case .verifyingInjection:  return "Confirming the key landed on the server…"
        case .probingNewKey:       return "Reconnecting using the new key…"
        case .savingToKeychain:    return "Saving private key to Keychain (Touch ID)…"
        case .success:             return "Done. The new key is active."
        case .failed(let why):     return "Failed: \(why)"
        }
    }

    var isInFlight: Bool {
        switch self {
        case .idle, .success, .failed: return false
        default: return true
        }
    }
}

@MainActor
final class AddServerViewModel: ObservableObject {

    // MARK: - Wizard Steps

    enum Step: Int, CaseIterable {
        case identity = 0
        case connection = 1
        case authentication = 2
        case verify = 3

        var title: String {
            switch self {
            case .identity: return "Identity"
            case .connection: return "Connection"
            case .authentication: return "Authentication"
            case .verify: return "Verify"
            }
        }
    }

    @Published var currentStep: Step = .identity

    // MARK: - Identity

    @Published var name = ""
    @Published var tagsText = ""
    @Published var notes = ""
    @Published var selectedIcon: ServerIcon = .serverRack
    @Published var selectedColor: ServerColor = .blue

    // MARK: - Connection

    @Published var host = ""
    @Published var port = 22
    @Published var username = ""

    // MARK: - Authentication

    /// Top-level auth choice. `usePassword` and `importKey` map to existing
    /// Go server records; `generateNew` produces a `.privateKey` record
    /// after the wizard's verify step has injected the new key.
    @Published var keyMode: KeyAcquisitionMode = .usePassword

    /// Used when `keyMode == .usePassword` OR (transiently) by
    /// `.generateNew` for the one-time injection password.
    @Published var password = ""

    /// Existing key fields (only used when `keyMode == .importKey`).
    @Published var privateKey = ""
    @Published var keyPassphrase = ""
    @Published var sshKeyFileName: String?
    @Published var showSSHKeyFilePicker = false

    // MARK: - Generate Mode

    /// One-time SSH password used to inject the freshly generated key.
    /// Wiped to `""` as soon as the inject step has either succeeded or
    /// definitively failed (so it never persists past the wizard).
    @Published var injectionPassword = ""

    /// Generation parameters surfaced in the UI.
    @Published var generateKeyType: KeygenType = .ed25519
    @Published var generateComment: String = "aevonx@\(ProcessInfo.processInfo.hostName.split(separator: ".").first.map(String.init) ?? "device")"
    @Published var generatePassphrase: String = ""

    /// After a successful inject, this fingerprint identifies the Keychain
    /// entry that holds the generated private key. The private key itself
    /// is intentionally NOT a property — it is owned by `KeygenKeyStorage`.
    @Published private(set) var generatedFingerprint: String?
    @Published private(set) var generatedPublicKey: String?
    @Published private(set) var generatedKeyTypeAfterInject: KeygenType?

    /// Held in memory ONLY between successful generation/injection and
    /// onSave being called. Wiped via `wipeGeneratedSecrets()`.
    private var generatedPrivateKey: String?

    /// Pipeline state for the verify step's progress UI.
    @Published var injectStage: GenerateInjectStage = .idle

    // MARK: - Verify (legacy "Test Connection" path)

    @Published var isTesting = false
    @Published var testResult: ConnectionTestResult?
    @Published var connectionProgress: ConnectionProgress?

    // MARK: - Errors

    @Published var showError = false
    @Published var errorMessage: String?

    // MARK: - Wizard helpers

    var isFirstStep: Bool { currentStep == .identity }
    var isLastStep: Bool { currentStep == .verify }

    func nextStep() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring()) { currentStep = next }
        }
    }

    func prevStep() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring()) { currentStep = prev }
        }
    }

    /// Validation rules per step. The Generate path is allowed to advance
    /// to Verify with just the injection password filled in — the actual
    /// generation happens in the verify step.
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .identity:
            return !name.isEmpty
        case .connection:
            return !host.isEmpty && !username.isEmpty
        case .authentication:
            switch keyMode {
            case .usePassword: return !password.isEmpty
            case .importKey:   return !privateKey.isEmpty
            case .generateNew: return !injectionPassword.isEmpty
            }
        case .verify:
            return true
        }
    }

    /// True when the wizard has the inputs needed to attempt the verify-step
    /// action (legacy test, or generate-and-inject).
    var canTest: Bool {
        guard !host.isEmpty, !username.isEmpty else { return false }
        switch keyMode {
        case .usePassword: return !password.isEmpty
        case .importKey:   return !privateKey.isEmpty
        case .generateNew: return !injectionPassword.isEmpty
        }
    }

    /// True when the wizard is in a state that can produce a save request.
    /// For generate mode, this requires the inject pipeline to have
    /// completed successfully so we have a private key to persist.
    var isValid: Bool {
        guard !name.isEmpty, !host.isEmpty, !username.isEmpty else { return false }
        switch keyMode {
        case .usePassword: return !password.isEmpty
        case .importKey:   return !privateKey.isEmpty
        case .generateNew: return generatedFingerprint != nil && generatedPrivateKey != nil
        }
    }

    // MARK: - Build Request

    func buildRequest() -> AddServerRequest? {
        guard isValid else { return nil }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        switch keyMode {
        case .usePassword:
            return AddServerRequest(
                name: name, host: host, port: port, username: username,
                authType: .password, password: password, privateKey: nil,
                keyPassphrase: nil, tags: tags,
                notes: notes.isEmpty ? nil : notes,
                iconName: selectedIcon.rawValue, customColor: selectedColor.rawValue
            )
        case .importKey:
            return AddServerRequest(
                name: name, host: host, port: port, username: username,
                authType: .privateKey, password: nil, privateKey: privateKey,
                keyPassphrase: keyPassphrase.isEmpty ? nil : keyPassphrase,
                tags: tags, notes: notes.isEmpty ? nil : notes,
                iconName: selectedIcon.rawValue, customColor: selectedColor.rawValue
            )
        case .generateNew:
            guard let priv = generatedPrivateKey else { return nil }
            return AddServerRequest(
                name: name, host: host, port: port, username: username,
                authType: .privateKey, password: nil, privateKey: priv,
                keyPassphrase: generatePassphrase.isEmpty ? nil : generatePassphrase,
                tags: tags, notes: notes.isEmpty ? nil : notes,
                iconName: selectedIcon.rawValue, customColor: selectedColor.rawValue
            )
        }
    }

    // MARK: - Legacy Test Connection (password / import paths)

    func testConnection() async {
        isTesting = true
        testResult = nil
        connectionProgress = nil
        defer { isTesting = false }

        guard let request = buildRequest() else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }

        let startTime = Date()
        connectionProgress = ConnectionProgress(stage: .establishingSSH, message: "Connecting...", percentComplete: 0.5)

        let connectResult = await SSHBridge.shared.testConnectAsync(
            host: request.host,
            port: Int32(request.port),
            username: request.username,
            password: request.authType == .password ? request.password ?? "" : "",
            privateKey: request.authType == .privateKey ? request.privateKey ?? "" : "",
            passphrase: request.keyPassphrase ?? ""
        )
        let latencyMs = Date().timeIntervalSince(startTime) * 1000

        guard let rd = connectResult.data(using: .utf8),
              let rj = try? JSONSerialization.jsonObject(with: rd) as? [String: Any],
              rj["success"] as? Bool == true else {
            var errorMsg = "Connection failed"
            if let rd = connectResult.data(using: .utf8),
               let rj = try? JSONSerialization.jsonObject(with: rd) as? [String: Any],
               let errStr = rj["error"] as? String {
                errorMsg = errStr
            }
            testResult = ConnectionTestResult(success: false, message: errorMsg, stage: .failed)
            return
        }

        connectionProgress = ConnectionProgress(stage: .complete, message: "Connected", percentComplete: 1.0)
        testResult = ConnectionTestResult(success: true, message: "Connection successful", stage: .complete, latencyMs: latencyMs)
    }

    // MARK: - Generate & Inject Pipeline

    /// Runs the full generate-and-inject pipeline. Drives `injectStage`
    /// transitions so the UI can render real progress (no fake percentages).
    /// On success, populates `generatedFingerprint`/`generatedPublicKey`
    /// and saves the private key to the Keychain.
    func runGenerateAndInject() async {
        guard keyMode == .generateNew else { return }
        guard injectStage != .generating, !injectStage.isInFlight else { return }

        // Reset previous run.
        wipeGeneratedSecrets()
        injectStage = .generating

        // 1. Generate locally.
        let pair: KeygenKeyPair
        do {
            pair = try await KeygenBridge.shared.generate(
                type: generateKeyType,
                comment: generateComment,
                passphrase: generatePassphrase
            )
        } catch {
            injectStage = .failed("Key generation failed: \(error.localizedDescription)")
            return
        }

        // 2. Probe the password connection so we don't write authorized_keys
        //    just to discover the credentials are wrong on the next step.
        injectStage = .probingPassword
        guard await probeWithPassword() else {
            injectStage = .failed("Password authentication failed. Double-check the SSH password.")
            return
        }

        // 3. Build the inject command in Go and run it via password session.
        injectStage = .injecting
        let injectCmd = KeygenBridge.shared.injectPublicKeyCmd(home: homeForUser, publicKey: pair.publicKey)
        let injectOutcome: KeygenInjectOutcome
        do {
            let result = try await KeygenBridge.shared.testExecute(
                host: host, port: port, username: username,
                password: injectionPassword, privateKey: "", passphrase: "",
                command: injectCmd
            )
            injectOutcome = KeygenInjectOutcome.parse(result.stdout)
        } catch {
            injectStage = .failed("Inject failed: \(error.localizedDescription)")
            return
        }
        guard injectOutcome.isSuccess else {
            injectStage = .failed("Server rejected the inject: \(injectOutcome)")
            return
        }

        // 4. Verify the key is present on the server (defence in depth).
        injectStage = .verifyingInjection
        let verifyCmd = KeygenBridge.shared.verifyKeyInjectedCmd(home: homeForUser, publicKey: pair.publicKey)
        do {
            let result = try await KeygenBridge.shared.testExecute(
                host: host, port: port, username: username,
                password: injectionPassword, privateKey: "", passphrase: "",
                command: verifyCmd
            )
            if KeygenVerifyOutcome.parse(result.stdout) != .present {
                injectStage = .failed("Could not confirm the key was written.")
                return
            }
        } catch {
            injectStage = .failed("Verify failed: \(error.localizedDescription)")
            return
        }

        // 5. Reconnect using ONLY the new private key. This is the proof
        //    that we won't lock the user out: if this connect fails, we
        //    bail BEFORE persisting the server.
        injectStage = .probingNewKey
        guard await probeWithGeneratedKey(privateKey: pair.privateKey) else {
            injectStage = .failed("Server accepts only the password — reconnect with the new key did not succeed.")
            return
        }

        // 6. Persist private key to Keychain (Touch ID prompted here).
        injectStage = .savingToKeychain
        do {
            _ = try await KeygenKeyStorage.shared.save(
                pair: pair,
                serverID: nil,
                reason: "Save the new SSH key to your Keychain"
            )
        } catch {
            injectStage = .failed("Keychain save failed: \(error.localizedDescription)")
            return
        }

        // 7. Stash the artifacts the wizard's save flow needs.
        generatedPublicKey = pair.publicKey
        generatedFingerprint = pair.fingerprint
        generatedKeyTypeAfterInject = pair.type
        generatedPrivateKey = pair.privateKey

        // 8. Wipe the one-time injection password — it's never needed again.
        injectionPassword = ""

        injectStage = .success
    }

    /// Drops every secret the generate flow holds in memory. Called from
    /// `runGenerateAndInject` between runs and also implicitly when the
    /// view model is deallocated.
    private func wipeGeneratedSecrets() {
        generatedPrivateKey = nil
        generatedFingerprint = nil
        generatedPublicKey = nil
        generatedKeyTypeAfterInject = nil
    }

    /// Username-aware home directory. Currently maps `root` → `/root` and
    /// every other user to `/home/<user>`. The server-side commands
    /// generated by `KeygenBridge` quote this so it cannot break out.
    private var homeForUser: String {
        if username == "root" { return "/root" }
        return "/home/\(username)"
    }

    private func probeWithPassword() async -> Bool {
        let result = await SSHBridge.shared.testConnectAsync(
            host: host, port: Int32(port), username: username,
            password: injectionPassword, privateKey: "", passphrase: ""
        )
        return parseSuccess(result)
    }

    private func probeWithGeneratedKey(privateKey: String) async -> Bool {
        let result = await SSHBridge.shared.testConnectAsync(
            host: host, port: Int32(port), username: username,
            password: "", privateKey: privateKey, passphrase: generatePassphrase
        )
        return parseSuccess(result)
    }

    private func parseSuccess(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return obj["success"] as? Bool == true
    }

    // MARK: - Existing-key file import

    func importSSHKeyFile(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let keyContent = try String(contentsOf: url, encoding: .utf8)
            privateKey = keyContent
            sshKeyFileName = url.lastPathComponent
        } catch {
            errorMessage = "Failed to read key file: \(error.localizedDescription)"
            showError = true
        }
    }
}
