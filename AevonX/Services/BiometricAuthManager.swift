//
//  BiometricAuthManager.swift
//  AevonX
//
//  Manages biometric authentication state to prevent multiple prompts
//

import SwiftUI
import AevonXCore

@MainActor
class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private var hasAuthenticatedThisSession = false
    private var lastAuthenticationTime: Date?
    private let authenticationValidityDuration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    /// Authenticate with biometrics, but only if not already authenticated recently
    func authenticateIfNeeded(reason: String) async throws {
        // Check if we've authenticated recently
        if hasAuthenticatedThisSession,
           let lastAuth = lastAuthenticationTime,
           Date().timeIntervalSince(lastAuth) < authenticationValidityDuration {
            print("[BiometricAuthManager] Skipping biometric auth - already authenticated within validity period")
            return
        }
        
        // Perform biometric authentication
        try await BiometricAuthService.shared.authenticate(reason: reason)
        
        // Update state
        hasAuthenticatedThisSession = true
        lastAuthenticationTime = Date()
        print("[BiometricAuthManager] Biometric authentication successful")
    }
    
    /// Force authentication regardless of previous state
    func authenticate(reason: String) async throws {
        try await BiometricAuthService.shared.authenticate(reason: reason)
        
        // Update state
        hasAuthenticatedThisSession = true
        lastAuthenticationTime = Date()
        print("[BiometricAuthManager] Forced biometric authentication successful")
    }
    
    /// Reset authentication state (e.g., on logout or app background)
    func resetAuthenticationState() {
        hasAuthenticatedThisSession = false
        lastAuthenticationTime = nil
        print("[BiometricAuthManager] Authentication state reset")
    }
    
    /// Check if authentication is still valid
    var isAuthenticationValid: Bool {
        guard hasAuthenticatedThisSession, let lastAuth = lastAuthenticationTime else {
            return false
        }
        return Date().timeIntervalSince(lastAuth) < authenticationValidityDuration
    }
}