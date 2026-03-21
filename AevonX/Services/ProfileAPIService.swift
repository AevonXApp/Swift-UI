//
//  ProfileAPIService.swift
//  AevonX
//
//  Handles all Profile-related API calls:
//  profile update, password change, sessions management, and activity log.
//

import Foundation
import Combine
import AevonXCoreBridge

// MARK: - User Session Model

public struct UserSession: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let deviceType: String?
    public let os: String?
    public let ipAddress: String?
    public let country: String?
    public let city: String?
    public let appVersion: String?
    public let lastUsedAt: Date?
    public let createdAt: Date
    public let isCurrent: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, os, country, city
        case deviceType  = "device_type"
        case ipAddress   = "ip_address"
        case appVersion  = "app_version"
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

    /// Device icon based on device_type from server
    public var deviceIcon: String {
        let type = (deviceType ?? "").lowercased()
        if type.contains("macbook")   { return "laptopcomputer" }
        if type.contains("imac")      { return "desktopcomputer" }
        if type.contains("mac_mini")  { return "macmini" }
        if type.contains("mac_studio") { return "macstudio" }
        if type.contains("mac_pro")   { return "macpro.gen3" }
        if type.contains("iphone")    { return "iphone" }
        if type.contains("ipad")      { return "ipad" }
        return "desktopcomputer"
    }
    
    /// Location string
    public var locationLabel: String {
        [city, country].compactMap { $0 }.joined(separator: ", ")
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
        AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
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

    // MARK: - Log Activity (fire-and-forget)
    
    /// Log a client-side activity event to the backend.
    /// Call from anywhere — runs in background, never blocks.
    nonisolated func logActivity(type: String, description: String, context: String? = nil) {
        Task { @MainActor in
            do {
                let token = try await self.getToken()
                var req = URLRequest(url: URL(string: "\(self.baseURL)/user/activity")!)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                var body: [String: String] = ["type": type, "description": description]
                if let ctx = context { body["context"] = ctx }
                req.httpBody = try JSONSerialization.data(withJSONObject: body)
                try await self.perform(req)
            } catch {
                // Silent failure — activity logging should never disrupt the app
            }
        }
    }
}
