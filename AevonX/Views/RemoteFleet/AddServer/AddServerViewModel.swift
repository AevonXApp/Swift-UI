//
//  AddServerViewModel.swift
//  AevonX
//

import SwiftUI
import AevonXCore
import Combine

@MainActor
class AddServerViewModel: ObservableObject {
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
    @Published var name = ""
    @Published var host = ""
    @Published var port = 22
    @Published var username = ""
    @Published var authType: AuthenticationType = .password
    @Published var password = ""
    @Published var privateKey = ""
    @Published var keyPassphrase = ""
    @Published var tagsText = ""
    @Published var notes = ""
    
    // Icon and Color selection (from AevonXCore)
    @Published var selectedIcon: ServerIcon = .serverRack
    @Published var selectedColor: ServerColor = .blue
    
    @Published var isTesting = false
    @Published var testResult: ConnectionTestResult?
    @Published var connectionProgress: ConnectionProgress?
    
    @Published var showError = false
    @Published var errorMessage: String?
    
    // SSH key file import
    @Published var showSSHKeyFilePicker = false
    @Published var sshKeyFileName: String?
    
    var isFirstStep: Bool { currentStep == .identity }
    var isLastStep: Bool { currentStep == .verify }
    
    func nextStep() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring()) {
                currentStep = next
            }
        }
    }
    
    func prevStep() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring()) {
                currentStep = prev
            }
        }
    }
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .identity:
            return !name.isEmpty
        case .connection:
            return !host.isEmpty && !username.isEmpty
        case .authentication:
            return authType == .password ? !password.isEmpty : !privateKey.isEmpty
        case .verify:
            return true
        }
    }
    
    var isValid: Bool {
        !name.isEmpty &&
        !host.isEmpty &&
        !username.isEmpty &&
        (authType == .password ? !password.isEmpty : !privateKey.isEmpty)
    }
    
    var canTest: Bool {
        !host.isEmpty && !username.isEmpty &&
        (authType == .password ? !password.isEmpty : !privateKey.isEmpty)
    }
    
    func buildRequest() -> AddServerRequest? {
        guard isValid else { return nil }
        
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return AddServerRequest(
            name: name,
            host: host,
            port: port,
            username: username,
            authType: authType,
            password: authType == .password ? password : nil,
            privateKey: authType == .privateKey ? privateKey : nil,
            keyPassphrase: authType == .privateKey && !keyPassphrase.isEmpty ? keyPassphrase : nil,
            tags: tags,
            notes: notes.isEmpty ? nil : notes,
            iconName: selectedIcon.rawValue,
            customColor: selectedColor.rawValue
        )
    }
    
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
        
        do {
            let serverData = request.toEncryptedServerData()
            
            // Encrypt server data using new ServerEncryptionService
            // (biometric is handled by EncryptionKeyStore internally on first access)
            let encryptedPayload = try await ServerEncryptionService.shared.encryptServer(serverData)
            
            let serverId = "test-\(UUID().uuidString)"
            await SSHService.shared.setProgressHandler(for: serverId) { [weak self] stage, progress in
                guard let self = self else { return }
                Task { @MainActor in
                    self.connectionProgress = ConnectionProgress(
                        stage: stage,
                        message: stage.rawValue,
                        percentComplete: progress
                    )
                }
            }
            
            let result = await SSHService.shared.testConnection(
                to: encryptedPayload,
                host: request.host,
                port: request.port,
                serverId: serverId
            )
            
            testResult = result
            
        } catch {
            errorMessage = "Connection test failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
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
