//
//  AuthViewModel.swift
//  AevonX
//
//  Authentication ViewModel — ALL network calls go through Go Core.
//  Swift only handles: Keychain (save/get/delete token) and UI state.
//  No API URLs, auth logic, or request models are visible here.
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    // Trial status
    @Published var trialStatus: TrialService.TrialStatus = .unknown
    @Published var isTrialEligible: Bool?
    @Published var trialEndsAt: String?
    @Published var trialRemainingDays: Int?
    @Published var trialExpired: Bool?
    @Published var trialMessage: String?
    
    private let authService = AuthService.shared  // Keychain only
    private let apiBridge = APIBridge.shared       // Go HTTP
    private let logBridge = LoggerBridge.shared    // Go logging
    private var hasInitialized = false
    
    /// Base URL from Go Core config
    private var baseURL: String {
        ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }
    
    init() {}
    
    /// Call this when the main view appears to initialize auth state
    func initializeIfNeeded() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        Task {
            await checkTrialEligibility()
            await checkAuthStatus()
        }
    }
    
    /// Check trial eligibility on app launch
    func checkTrialEligibility() async {
        // First check local Keychain (fastest)
        let localStatus = await TrialService.shared.checkTrialEligibility()
        self.trialStatus = localStatus
        
        // Then verify with server via Go HTTP
        let token = await authService.getToken() ?? ""
        let deviceID = await TrialService.shared.getDeviceID() ?? ""
        
        guard !deviceID.isEmpty else { return }
        
        let resultJSON = await apiBridge.checkTrialEligibilityAsync(baseURL: baseURL, token: token, deviceID: deviceID)
        
        if let data = parseGoResult(resultJSON) {
            if let eligible = data["eligible"] as? Bool {
                self.isTrialEligible = eligible
                if !eligible {
                    self.trialStatus = .used
                }
            }
            if let message = data["message"] as? String {
                self.trialMessage = message
            }
        }
    }
    
    func checkAuthStatus() async {
        if let token = await authService.getToken(), !token.isEmpty {
            // Go HTTP: get current user
            let resultJSON = await apiBridge.getCurrentUserAsync(baseURL: baseURL, token: token)
            
            if let userData = parseGoResultNested(resultJSON, key: "user") {
                self.currentUser = decodeUser(from: userData)
                self.isAuthenticated = true
                logBridge.info("[AuthVM] Auth check passed", module: "Auth")
            } else {
                // Token is invalid, clear it
                logBridge.warn("[AuthVM] Token invalid, clearing", module: "Auth")
                _ = await authService.deleteToken()
                self.isAuthenticated = false
            }
        } else {
            self.isAuthenticated = false
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Step 1: Validate via Go Core
        let validationJSON = apiBridge.validateLogin(email: email, password: password)
        if let validationError = extractValidationError(validationJSON) {
            logBridge.warn("[AuthVM] Login validation failed: \(validationError)", module: "Auth")
            self.errorMessage = validationError
            isLoading = false
            return
        }
        
        // Step 2: HTTP call via Go net/http (no URLs visible here!)
        let resultJSON = await apiBridge.loginAsync(baseURL: baseURL, email: email, password: password)
        
        guard let authData = parseGoResult(resultJSON) else {
            let errorMsg = extractGoError(resultJSON)
            logBridge.error("[AuthVM] Login failed: \(errorMsg)", module: "Auth")
            self.errorMessage = errorMsg
            isLoading = false
            return
        }
        
        // Step 3: Save token to Keychain (Swift-only)
        if let token = authData["token"] as? String {
            _ = await authService.saveToken(token)
        }
        
        // Step 4: Parse user
        if let userData = authData["user"] as? [String: Any] {
            self.currentUser = decodeUser(from: userData)
        }
        self.isAuthenticated = true
        logBridge.info("[AuthVM] Login successful for \(apiBridge.maskEmail(email))", module: "Auth")
        
        // Trial status from response
        self.trialEndsAt = authData["trial_ends_at"] as? String
        
        if let trialEndsAtString = authData["trial_ends_at"] as? String,
           let trialEndsAt = Self.parseDate(trialEndsAtString) {
            let remainingDays = Calendar.current.dateComponents([.day], from: Date(), to: trialEndsAt).day ?? 0
            self.trialRemainingDays = remainingDays > 0 ? remainingDays : nil
            self.trialExpired = remainingDays <= 0
            
            if remainingDays > 0 {
                self.trialStatus = .used
                self.trialMessage = "\(remainingDays) days remaining in your trial."
            } else if remainingDays <= 0 && authData["trial_eligible"] as? Bool == false {
                self.trialStatus = .used
                self.trialMessage = "Your trial has expired."
            }
        } else if authData["trial_expired"] as? Bool == true {
            self.trialExpired = true
            self.trialStatus = .used
            self.trialMessage = "Your trial has expired."
        }
        
        isLoading = false
    }
    
    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        return date
    }
    
    func register(name: String, email: String, password: String, passwordConfirmation: String) async {
        isLoading = true
        errorMessage = nil
        
        // Step 1: Validate via Go Core
        let validationJSON = apiBridge.validateRegistration(
            name: name, email: email,
            password: password, confirmation: passwordConfirmation
        )
        if let validationError = extractValidationError(validationJSON) {
            logBridge.warn("[AuthVM] Registration validation failed: \(validationError)", module: "Auth")
            self.errorMessage = validationError
            isLoading = false
            return
        }
        
        // Step 2: HTTP call via Go net/http
        let deviceID = await TrialService.shared.getDeviceID() ?? ""
        let resultJSON = await apiBridge.registerAsync(
            baseURL: baseURL, name: name, email: email,
            password: password, confirmation: passwordConfirmation,
            deviceID: deviceID
        )
        
        guard let authData = parseGoResult(resultJSON) else {
            let errorMsg = extractGoError(resultJSON)
            logBridge.error("[AuthVM] Registration failed: \(errorMsg)", module: "Auth")
            self.errorMessage = errorMsg
            isLoading = false
            return
        }
        
        // Step 3: Save token to Keychain
        if let token = authData["token"] as? String {
            _ = await authService.saveToken(token)
        }
        
        // Step 4: Parse user
        if let userData = authData["user"] as? [String: Any] {
            self.currentUser = decodeUser(from: userData)
        }
        self.isAuthenticated = true
        logBridge.info("[AuthVM] Registration successful for \(apiBridge.maskEmail(email))", module: "Auth")
        
        // Trial status
        self.isTrialEligible = authData["trial_eligible"] as? Bool
        self.trialEndsAt = authData["trial_ends_at"] as? String
        
        if authData["trial_eligible"] as? Bool == true {
            self.trialStatus = .used
            self.trialMessage = "Your 14-day free trial has started!"
            _ = await TrialService.shared.markTrialAsUsed()
        } else {
            self.trialMessage = "This device is not eligible for a free trial."
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        logBridge.info("[AuthVM] Logout initiated", module: "Auth")
        
        let token = await authService.getToken() ?? ""
        
        // Go HTTP logout
        let _ = await apiBridge.logoutAsync(baseURL: baseURL, token: token)
        
        // Always clear local state
        _ = await authService.deleteToken()
        self.currentUser = nil
        self.isAuthenticated = false
        
        logBridge.info("[AuthVM] Logout complete", module: "Auth")
        isLoading = false
    }
    
    // MARK: - Go Core Bridge Helpers
    
    /// Parses Go AuthServiceResult JSON → extracts "data" as dictionary.
    private func parseGoResult(_ json: String) -> [String: Any]? {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              result["success"] as? Bool == true,
              let dataVal = result["data"] else {
            return nil
        }
        
        // data can be a raw JSON string (RawMessage) or a dictionary
        if let dict = dataVal as? [String: Any] {
            return dict
        }
        if let jsonStr = dataVal as? String,
           let innerData = jsonStr.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: innerData) as? [String: Any] {
            return dict
        }
        return nil
    }
    
    /// Parses nested key from Go result.
    private func parseGoResultNested(_ json: String, key: String) -> [String: Any]? {
        guard let data = parseGoResult(json) else { return nil }
        return data[key] as? [String: Any]
    }
    
    /// Extracts error message from Go AuthServiceResult.
    private func extractGoError(_ json: String) -> String {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              let error = result["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return "An unexpected error occurred"
        }
        return message
    }
    
    /// Extracts a validation error from Go validation result.
    private func extractValidationError(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = response["data"] as? [String: Any] else {
            return nil
        }
        
        let valid = result["valid"] as? Bool ?? true
        if !valid {
            return result["error"] as? String
        }
        return nil
    }
    
    /// Decodes a User from a dictionary (JSON from Go).
    private func decodeUser(from dict: [String: Any]) -> User? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let user = try? JSONDecoder().decode(User.self, from: jsonData) else {
            return nil
        }
        return user
    }
}
