//
//  AuthService.swift
//  AevonXCoreBridge
//
//  Authentication service for API communication
//

import Foundation
import Security

/// Actor-based authentication service
public actor AuthService {
    public static let shared = AuthService()
    
    private let tokenKey = "app.aevonx.apiToken"
    private let vaultService = "app.aevonx.main.service"
    
    private var baseURL: String {
        ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }
    
    private init() {
        CoreLogger.shared.debug("[AuthService] INFO: AuthService initialized", module: "Auth")
    }
    
    // MARK: - Keychain Operations
    
    public func saveToken(_ token: String) -> Bool {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecAttrService as String: vaultService,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing token first
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecAttrService as String: vaultService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            CoreLogger.shared.debug("[AuthService] DEBUG: getToken failed - status: \(status), result: \(result != nil ? "has data" : "nil")", module: "Auth")
            return nil
        }
        
        CoreLogger.shared.debug("[AuthService] DEBUG: getToken succeeded - token length: \(token.count) chars", module: "Auth")
        return token
    }
    
    public func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecAttrService as String: vaultService
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - API Calls
    
    public func register(name: String, email: String, password: String, passwordConfirmation: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/register"
        
        // Security: Mask email for logging
        let maskedEmail = maskEmail(email)
        CoreLogger.shared.debug("[AuthService] DEBUG: Registration attempt for user: \(maskedEmail)", module: "Auth")
        
        // Get device ID for trial tracking
        let deviceId = await TrialService.shared.getDeviceID()
        if let deviceId = deviceId {
            CoreLogger.shared.debug("[AuthService] DEBUG: Device ID available for registration: \(deviceId.prefix(8))...", module: "Auth")
        } else {
            CoreLogger.shared.debug("[AuthService] WARNING: Device ID unavailable for registration", module: "Auth")
        }
        
        var body: [String: String] = [
            "name": name,
            "email": email,
            "password": password,
            "password_confirmation": passwordConfirmation
        ]
        
        // Add device_id if available
        if let deviceId = deviceId {
            body["device_id"] = deviceId
        }
        
        do {
            let data = try await performPostRequest(to: endpoint, body: body)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            CoreLogger.shared.debug("[AuthService] INFO: Registration successful for: \(maskedEmail)", module: "Auth")
            CoreLogger.shared.debug("[AuthService] DEBUG: Trial eligible: \(response.trialEligible ?? false)", module: "Auth")
            
            // Save token to Keychain
            if let token = response.token {
                let saved = saveToken(token)
                CoreLogger.shared.debug("[AuthService] DEBUG: Token saved to Keychain: \(saved)", module: "Auth")
            }
            
            // Mark trial as used locally if registration was successful
            if response.trialEligible == true {
                _ = await TrialService.shared.markTrialAsUsed()
            }
            
            return response
        } catch {
            CoreLogger.shared.debug("[AuthService] ERROR: Registration error: \(error.localizedDescription)", module: "Auth")
            throw error
        }
    }
    
    /// Check trial eligibility for the current device
    public func checkTrialEligibility() async throws -> TrialEligibilityResponse {
        let endpoint = "\(baseURL)/trial-eligibility"
        
        guard let deviceId = await TrialService.shared.getDeviceID() else {
            throw AuthError.deviceIdUnavailable
        }
        
        // First check local Keychain
        let localTrialUsed = await TrialService.shared.hasTrialBeenUsedLocally()
        if localTrialUsed {
            return TrialEligibilityResponse(
                eligible: false,
                deviceId: deviceId,
                message: "This device has already been used for a trial."
            )
        }
        
        let body: [String: String] = [
            "device_id": deviceId
        ]
        
        let data = try await performPostRequest(to: endpoint, body: body)
        let response = try JSONDecoder().decode(TrialEligibilityResponse.self, from: data)
        return response
    }
    
    public func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/login"
        
        // Security: Mask email for logging
        let maskedEmail = maskEmail(email)
        CoreLogger.shared.debug("[AuthService] DEBUG: Login attempt for user: \(maskedEmail)", module: "Auth")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        do {
            let data = try await performPostRequest(to: endpoint, body: body)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            CoreLogger.shared.debug("[AuthService] INFO: Login successful for: \(maskedEmail)", module: "Auth")
            
            // Save token to Keychain
            if let token = response.token {
                let saved = saveToken(token)
                CoreLogger.shared.debug("[AuthService] DEBUG: Token saved to Keychain: \(saved)", module: "Auth")
            }
            
            return response
        } catch {
            CoreLogger.shared.debug("[AuthService] ERROR: Login error: \(error.localizedDescription)", module: "Auth")
            throw error
        }
    }
    
    public func logout() async throws {
        let endpoint = "\(baseURL)/logout"
        
        CoreLogger.shared.debug("[AuthService] INFO: Logout attempt", module: "Auth")
        
        do {
            _ = try await performAuthenticatedRequest(to: endpoint, method: "POST")
            
            // Delete token from Keychain
            let deleted = deleteToken()
            CoreLogger.shared.debug("[AuthService] DEBUG: Token deleted from Keychain: \(deleted)", module: "Auth")
            CoreLogger.shared.debug("[AuthService] INFO: Logout successful", module: "Auth")
        } catch {
            CoreLogger.shared.debug("[AuthService] ERROR: Logout error: \(error.localizedDescription)", module: "Auth")
            throw error
        }
    }
    
    public func getCurrentUser() async throws -> User {
        let endpoint = "\(baseURL)/user"
        
        CoreLogger.shared.debug("[AuthService] DEBUG: Fetching current user...", module: "Auth")
        
        let data = try await performAuthenticatedRequest(to: endpoint, method: "GET")
        let response = try JSONDecoder().decode(UserResponse.self, from: data)
        
        CoreLogger.shared.debug("[AuthService] INFO: Current user fetched: \(maskEmail(response.user.email))", module: "Auth")
        
        return response.user
    }
    
    // MARK: - Private Helpers
    
    /// Masks email for security in logs (e.g., j***@example.com)
    private func maskEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else {
            return "***"
        }
        let localPart = email[..<atIndex]
        guard let firstChar = localPart.first else {
            return "***"
        }
        return "\(firstChar)***\(email.suffix(from: atIndex))"
    }
    
    private func performPostRequest(to endpoint: String, body: [String: String]) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            CoreLogger.shared.debug("[AuthService] ERROR: Invalid response type for POST \(endpoint)", module: "Auth")
            throw AuthError.invalidResponse
        }
        
        _ = String(data: data, encoding: .utf8) ?? "Unable to decode"
        CoreLogger.shared.debug("[AuthService] DEBUG: POST \(endpoint) - Status: \(httpResponse.statusCode)", module: "Auth")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.apiError(errorResponse.message)
            }
            throw AuthError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
    
    private func performAuthenticatedRequest(to endpoint: String, method: String) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw AuthError.invalidURL
        }
        
        guard let token = getToken() else {
            CoreLogger.shared.debug("[AuthService] WARNING: No token available for authenticated request to \(endpoint)", module: "Auth")
            throw AuthError.noToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            CoreLogger.shared.debug("[AuthService] ERROR: Invalid response type for \(method) \(endpoint)", module: "Auth")
            throw AuthError.invalidResponse
        }
        
        CoreLogger.shared.debug("[AuthService] DEBUG: \(method) \(endpoint) - Status: \(httpResponse.statusCode)", module: "Auth")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                _ = deleteToken()
                CoreLogger.shared.debug("[AuthService] WARNING: Token deleted due to 401 unauthorized", module: "Auth")
                throw AuthError.unauthorized
            }
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.apiError(errorResponse.message)
            }
            throw AuthError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
}

// MARK: - Data Models

public struct AuthResponse: Codable {
    public let user: User
    public let token: String?
    public let message: String
    public let trialEligible: Bool?
    public let trialEndsAt: String?
    public let trialExpired: Bool?
    
    enum CodingKeys: String, CodingKey {
        case user, token, message
        case trialEligible = "trial_eligible"
        case trialEndsAt = "trial_ends_at"
        case trialExpired = "trial_expired"
    }
}

public struct UserResponse: Codable {
    public let user: User
}

public struct User: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let email: String
    public let emailVerifiedAt: String?
    public let createdAt: String
    public let updatedAt: String
    public let plan: String?
    public let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case emailVerifiedAt = "email_verified_at"
        case createdAt       = "created_at"
        case updatedAt       = "updated_at"
        case plan
        case avatarUrl       = "avatar_url"
    }
    
    /// Human-readable plan label
    public var planLabel: String {
        switch plan?.lowercased() {
        case "pro":        return "Pro"
        case "enterprise": return "Enterprise"
        default:           return "Free"
        }
    }
    
    /// Is the user on a paid plan?
    public var isProOrHigher: Bool {
        return plan == "pro" || plan == "enterprise"
    }
}

public struct ErrorResponse: Codable {
    public let message: String
}

// MARK: - Errors

public enum AuthError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noToken
    case unauthorized
    case decodingError
    case deviceIdUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .apiError(let message):
            return message
        case .noToken:
            return "No authentication token found"
        case .unauthorized:
            return "Session expired. Please login again."
        case .decodingError:
            return "Failed to decode response"
        case .deviceIdUnavailable:
            return "Unable to retrieve device identifier"
        }
    }
}
