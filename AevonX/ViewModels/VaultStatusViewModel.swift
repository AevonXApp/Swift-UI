//
//  VaultStatusViewModel.swift
//  AevonX
//
//  Manages detection of encryption key state (Setup vs Restore vs Active)
//

import SwiftUI
import Combine
import AevonXCore

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
    
    func checkVaultStatus() async {
        isLoading = true
        errorMessage = nil
        
        let hasLocalKey = EncryptionKeyStore.shared.hasKey()
        
        if hasLocalKey {
            state = .active
            isVaultInitialized = true
        } else {
            // Check server for key hash to determine if this is new or existing account
            do {
                let serverStatus = try await VaultAPIService.shared.checkRecoveryKeyStatus()
                if serverStatus.hasRecoveryKey {
                    // Server has key hash → existing account, needs key entry
                    state = .recoveryRequired
                    isVaultInitialized = false
                } else {
                    // No key anywhere → new account, needs setup
                    state = .needsSetup
                    isVaultInitialized = false
                }
            } catch {
                print("[VaultStatus] API Check failed: \(error.localizedDescription)")
                // If API fails, don't assume needsSetup — that would generate a new key!
                // It's safer to assume recoveryRequired so the user can enter their existing key
                state = .recoveryRequired
                isVaultInitialized = false
            }
        }
        
        print("[VaultStatus] Detected state: \(state)")
        isLoading = false
    }
}
