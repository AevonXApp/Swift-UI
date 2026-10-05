import Foundation
import Security

/// Service for managing trial eligibility and device tracking
public actor TrialService {
    
    public static let shared = TrialService()
    
    // MARK: - Keychain Constants
    
    private let trialUsedKey = "app.aevonx.trial.used"
    private let trialUsedService = "app.aevonx.main.service"
    
    // MARK: - Trial Status
    
    public enum TrialStatus: Equatable {
        case eligible
        case used
        case unknown
    }
    
    private init() {}
    
    // MARK: - Device ID
    
    /// Gets the hashed device identifier
    public func getDeviceID() async -> String? {
        return await DeviceIdentifier.shared.getDeviceID()
    }
    
    // MARK: - Keychain Operations
    
    /// Checks if trial has been used on this device (from Keychain)
    public func hasTrialBeenUsedLocally() -> Bool {
        return getTrialUsedFlagFromKeychain()
    }
    
    /// Marks trial as used in Keychain (persists even if app is deleted)
    public func markTrialAsUsed() -> Bool {
        return saveTrialUsedFlagToKeychain()
    }
    
    /// Clears the trial used flag (for testing purposes)
    public func clearTrialFlag() -> Bool {
        return deleteTrialUsedFlagFromKeychain()
    }
    
    // MARK: - Keychain Implementation
    
    private func saveTrialUsedFlagToKeychain() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: trialUsedKey,
            kSecAttrService as String: trialUsedService,
            kSecValueData as String: Data("used".utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getTrialUsedFlagFromKeychain() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: trialUsedKey,
            kSecAttrService as String: trialUsedService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return false
        }
        
        return value == "used"
    }
    
    private func deleteTrialUsedFlagFromKeychain() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: trialUsedKey,
            kSecAttrService as String: trialUsedService
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Combined Check
    
    /// Comprehensive trial eligibility check
    /// - Returns: Trial status based on local Keychain flag
    public func checkTrialEligibility() async -> TrialStatus {
        // First check local Keychain
        if hasTrialBeenUsedLocally() {
            return .used
        }
        
        return .eligible
    }
}

// MARK: - Trial Eligibility Response

public struct TrialEligibilityResponse: Codable {
    public let eligible: Bool
    public let deviceId: String?
    public let message: String?
    
    public init(eligible: Bool, deviceId: String?, message: String?) {
        self.eligible = eligible
        self.deviceId = deviceId
        self.message = message
    }
}
