//
//  AIGitAPIService.swift
//  AevonXCore
//
//  API service for AI-powered Git operations.
//  Communicates with AevonX-Web backend to generate AI commit messages.
//

import Foundation

// MARK: - AI Git API Errors

public enum AIGitAPIError: Error, LocalizedError {
    case noAuthToken
    case subscriptionRequired
    case aiServiceUnavailable
    case invalidResponse
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noAuthToken:
            return "Authentication required"
        case .subscriptionRequired:
            return "AI commit messages require a Pro subscription"
        case .aiServiceUnavailable:
            return "AI service is temporarily unavailable"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Models

private struct AICommitMessageResponse: Codable {
    let success: Bool
    let data: AICommitMessageData?
    let error: String?
    let message: String?
}

private struct AICommitMessageData: Codable {
    let message: String
}

// MARK: - AI Git API Service

public actor AIGitAPIService {
    
    public static let shared = AIGitAPIService()
    
    private let baseURL: String
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    private init() {
        self.baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
        
        self.jsonDecoder = JSONDecoder()
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.jsonEncoder = encoder
    }
    
    /// Generate an AI-powered commit message from a git diff.
    /// Requires Pro subscription.
    ///
    /// - Parameter diff: The git diff output
    /// - Returns: AI-generated commit message string
    public func generateCommitMessage(diff: String) async throws -> String {
        let endpoint = "\(baseURL)/ai-git/commit-message"
        
        guard let url = URL(string: endpoint) else {
            throw AIGitAPIError.invalidResponse
        }
        
        guard let token = await AuthService.shared.getToken() else {
            throw AIGitAPIError.noAuthToken
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["diff": diff]
        request.httpBody = try jsonEncoder.encode(body)
        
        // Execute
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIGitAPIError.invalidResponse
        }
        
        // Handle specific status codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 403:
            throw AIGitAPIError.subscriptionRequired
        case 503:
            throw AIGitAPIError.aiServiceUnavailable
        default:
            throw AIGitAPIError.invalidResponse
        }
        
        // Decode
        let apiResponse = try jsonDecoder.decode(AICommitMessageResponse.self, from: data)
        
        guard let commitMessage = apiResponse.data?.message, !commitMessage.isEmpty else {
            throw AIGitAPIError.invalidResponse
        }
        
        return commitMessage
    }
}
