//
//  ProfileAPIService.swift
//  AevonX
//
//  Handles all Profile-related API calls:
//  profile update, password change, sessions management, and activity log.
//

import Foundation
import Combine
import AevonXCore


// MARK: - User Session Model

public struct UserSession: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let lastUsedAt: Date?
    public let createdAt: Date
    public let isCurrent: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case lastUsedAt  = "last_used_at"
        case createdAt   = "created_at"
        case isCurrent   = "is_current"
    }

    /// Human-readable "last used" string
    public var lastUsedLabel: String {
        guard let date = lastUsedAt else { return "Never" }
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60:       return "Just now"
        case ..<3600:     return "\(Int(diff / 60))m ago"
        case ..<86400:    return "\(Int(diff / 3600))h ago"
        default:          return "\(Int(diff / 86400))d ago"
        }
    }

    /// Device icon guess from session name
    public var deviceIcon: String {
        let lower = name.lowercased()
        if lower.contains("iphone") { return "iphone" }
        if lower.contains("ipad")   { return "ipad" }
        if lower.contains("mac")    { return "laptopcomputer" }
        return "desktopcomputer"
    }
}

// MARK: - Activity Log Model

public struct ActivityLogEntry: Codable, Identifiable {
    public let id: Int
    public let type: String
    public let description: String
    public let context: String?
    public let icon: String
    public let color: String
    public let ipAddress: String?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, description, context, icon, color
        case ipAddress  = "ip_address"
        case createdAt  = "created_at"
    }
}

// MARK: - ProfileAPIService

@MainActor
class ProfileAPIService: ObservableObject {
    static let shared = ProfileAPIService()

    private var baseURL: String {
        ConfigurationManager.shared.currentConfiguration.fullBaseURL
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }()

    // MARK: - Update Profile Name

    func updateProfile(name: String) async throws {
        let token = try await getToken()
        var req = URLRequest(url: URL(string: "\(baseURL)/user/profile")!)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["name": name])
        try await perform(req)
    }

    // MARK: - Change Password

    func changePassword(current: String, new: String) async throws {
        let token = try await getToken()
        var req = URLRequest(url: URL(string: "\(baseURL)/user/password")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "current_password": current,
            "new_password": new,
            "new_password_confirmation": new
        ])
        try await perform(req)
    }

    // MARK: - Sessions

    func fetchSessions() async throws -> [UserSession] {
        let token = try await getToken()
        var req = URLRequest(url: URL(string: "\(baseURL)/user/sessions")!)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await performData(req)
        struct Resp: Decodable { let sessions: [UserSession] }
        return try decoder.decode(Resp.self, from: data).sessions
    }

    func deleteSession(id: Int) async throws {
        let token = try await getToken()
        var req = URLRequest(url: URL(string: "\(baseURL)/user/sessions/\(id)")!)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await perform(req)
    }

    func deleteAllSessions() async throws {
        let token = try await getToken()
        var req = URLRequest(url: URL(string: "\(baseURL)/user/sessions")!)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await perform(req)
    }

    // MARK: - Activity

    func fetchActivity(limit: Int = 30) async throws -> [ActivityLogEntry] {
        let token = try await getToken()
        var req = URLRequest(url: URL(string: "\(baseURL)/user/activity?limit=\(limit)")!)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await performData(req)
        struct Resp: Decodable { let activity: [ActivityLogEntry] }
        return try decoder.decode(Resp.self, from: data).activity
    }

    // MARK: - Private Helpers

    private func getToken() async throws -> String {
        guard let token = await AuthService.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        return token
    }

    @discardableResult
    private func perform(_ req: URLRequest) async throws -> Data {
        return try await performData(req)
    }

    private func performData(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            if let http = response as? HTTPURLResponse {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    throw NSError(domain: "ProfileAPI", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: msg])
                }
                throw URLError(.badServerResponse)
            }
            throw URLError(.badServerResponse)
        }
        return data
    }
}
