//
//  VaultStatusViewModel.swift
//  AevonX
//
//  Manages detection of encryption key state (Setup vs Restore vs Active)
//  Uses Go Core for HTTP calls — no API URLs visible in open-source code.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class VaultStatusViewModel: ObservableObject {
    enum VaultState {
        case unknown
        case needsSetup        // No key exists anywhere — new account
        case recoveryRequired  // No local key — needs key entry
        case active            // Key exists and ready
    }
    
    @Published var state: VaultState = .unknown
    @Published var isVaultInitialized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiBridge = APIBridge.shared
    
    private var baseURL: String {
        AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }
    
    func checkVaultStatus() async {
        isLoading = true
        errorMessage = nil
        
        let hasLocalKey = EncryptionKeyStore.shared.hasKey()
        
        if hasLocalKey {
            state = .active
            isVaultInitialized = true
        } else {
            // Check server via Go HTTP for key hash
            let token = await AuthService.shared.getToken() ?? ""
            let resultJSON = await apiBridge.checkRecoveryKeyStatusAsync(baseURL: baseURL, token: token)
            
            if let data = parseGoResult(resultJSON),
               let hasKey = data["has_recovery_key"] as? Bool {
                if hasKey {
                    state = .recoveryRequired
                    isVaultInitialized = false
                } else {
                    state = .needsSetup
                    isVaultInitialized = false
                }
            } else {
                debugLog("[VaultStatus] API Check failed via Go")
                state = .recoveryRequired
                isVaultInitialized = false
            }
        }
        
        debugLog("[VaultStatus] Detected state: \(state)")
        isLoading = false
    }
    
    private func parseGoResult(_ json: String) -> [String: Any]? {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              result["success"] as? Bool == true,
              let dataVal = result["data"] else { return nil }
        if let dict = dataVal as? [String: Any] { return dict }
        return nil
    }
}
