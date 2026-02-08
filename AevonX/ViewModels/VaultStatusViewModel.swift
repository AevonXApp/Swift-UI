//
//  VaultStatusViewModel.swift
//  AevonX
//
//  Manages detection of Vault state (New Setup vs Recovery Required)
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class VaultStatusViewModel: ObservableObject {
    enum VaultState {
        case unknown
        case needsSetup        // Server: false, Local: false
        case recoveryRequired  // Server: true,  Local: false
        case active            // Server: true,  Local: true
    }
    
    @Published var state: VaultState = .unknown
    @Published var isVaultInitialized = false // Legacy support for UI bindings
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let vaultAPI = VaultAPIService.shared
    private let recoveryManager = RecoveryKeyManager.shared
    
    func checkVaultStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Check server status
            let serverStatus = try await vaultAPI.checkRecoveryKeyStatus()
            let serverHasKey = serverStatus.hasRecoveryKey
            
            // 2. Check local status
            let localHasKey = await recoveryManager.hasRecoveryKey()
            
            // 3. Determine state
            if serverHasKey && localHasKey {
                state = .active
                isVaultInitialized = true
            } else if serverHasKey && !localHasKey {
                state = .recoveryRequired
                isVaultInitialized = false
            } else {
                state = .needsSetup
                isVaultInitialized = false
            }
            
            print("[VaultStatus] Detected state: \(state)")
            
        } catch {
            print("[VaultStatus] API Check failed: \(error.localizedDescription)")
            // Fallback to local check if offline
            let localHasKey = await recoveryManager.hasRecoveryKey()
            if localHasKey {
                state = .active
                isVaultInitialized = true
            } else {
                errorMessage = "Unable to verify vault status with server."
                state = .unknown
            }
        }
        
        isLoading = false
    }
}
