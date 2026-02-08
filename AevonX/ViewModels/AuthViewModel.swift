//
//  AuthViewModel.swift
//  AevonX
//
//  Authentication ViewModel connecting UI to AuthService
//

import SwiftUI
import AevonXCore
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
    
    private let authService = AuthService.shared
    private var hasInitialized = false
    
    init() {
        // Defer initialization to avoid blocking app launch
        // Call initialize() explicitly when the view appears
    }
    
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
        
        // Then verify with server
        do {
            let response = try await authService.checkTrialEligibility()
            self.isTrialEligible = response.eligible
            self.trialMessage = response.message
            
            // Update local status based on server response
            if !response.eligible {
                self.trialStatus = .used
            }
        } catch {
            // If server check fails, rely on local status
            // Trial eligibility check failed
        }
    }
    
    func checkAuthStatus() async {
        if let token = await authService.getToken(), !token.isEmpty {
            do {
                let user = try await authService.getCurrentUser()
                self.currentUser = user
                self.isAuthenticated = true
            } catch {
                // Token is invalid, clear it
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
        
        do {
            let response = try await authService.login(email: email, password: password)
            self.currentUser = response.user
            self.isAuthenticated = true
            
            // Update trial status from login response using existing properties
            self.trialEndsAt = response.trialEndsAt
            
            // Calculate trial remaining days from trial_ends_at if available
            if let trialEndsAtString = response.trialEndsAt,
               let trialEndsAt = Self.parseDate(trialEndsAtString) {
                let remainingDays = Calendar.current.dateComponents([.day], from: Date(), to: trialEndsAt).day ?? 0
                self.trialRemainingDays = remainingDays > 0 ? remainingDays : nil
                self.trialExpired = remainingDays <= 0
                
                if remainingDays > 0 {
                    self.trialStatus = .used
                    self.trialMessage = "\(remainingDays) days remaining in your trial."
                } else if remainingDays <= 0 && response.trialEligible == false {
                    self.trialStatus = .used
                    self.trialMessage = "Your trial has expired."
                }
            } else if response.trialExpired == true {
                self.trialExpired = true
                self.trialStatus = .used
                self.trialMessage = "Your trial has expired."
            }
        } catch let error as AuthError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "An unexpected error occurred"
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
        
        // Basic validation
        guard password == passwordConfirmation else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        do {
            let response = try await authService.register(
                name: name,
                email: email,
                password: password,
                passwordConfirmation: passwordConfirmation
            )
            self.currentUser = response.user
            self.isAuthenticated = true
            
            // Update trial status from registration response
            self.isTrialEligible = response.trialEligible
            self.trialEndsAt = response.trialEndsAt
            
            if response.trialEligible == true {
                self.trialStatus = .used
                self.trialMessage = "Your 14-day free trial has started!"
            } else {
                self.trialMessage = "This device is not eligible for a free trial."
            }
        } catch let error as AuthError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            // Even if logout fails, clear local state
            self.currentUser = nil
            self.isAuthenticated = false
        }
        
        isLoading = false
    }
}
