//
//  ProfileAPIService.swift
//  AevonX
//
//  Thin Swift wrapper around the Go-side Profile bridge.
//
//  Network I/O, TLS pinning, error sanitization and request signing all happen
//  in core-go (`pkg/api/profile_service.go`). This file only:
//    1. Reads the Sanctum token from Keychain.
//    2. Forwards the call to APIBridge.shared.<method>Async(...).
//    3. Parses the resulting AuthServiceResult JSON into either UserSession /
//       ActivityLogEntry value types or a thrown error.
//
//  No URLSession / URLRequest / HTTPURLResponse references in this file —
//  enforced by scripts/oss-audit.sh.
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

    private let decoder: JSONDecoder = .iso8601()

    // MARK: - Profile

    func updateProfile(name: String) async throws {
        let token = try await getToken()
        let json = await APIBridge.shared.updateProfileAsync(baseURL: baseURL, token: token, name: name)
        try CoreResult.ensureSuccess(json)
    }

    // MARK: - Password

    func changePassword(current: String, new: String) async throws {
        let token = try await getToken()
        let json = await APIBridge.shared.changePasswordAsync(baseURL: baseURL, token: token, current: current, new: new)
        try CoreResult.ensureSuccess(json)
    }

    // MARK: - Sessions

    func fetchSessions() async throws -> [UserSession] {
        let token = try await getToken()
        let json = await APIBridge.shared.fetchSessionsAsync(baseURL: baseURL, token: token)
        struct Resp: Decodable { let sessions: [UserSession] }
        return try CoreResult.decodePayload(json, as: Resp.self, decoder: decoder).sessions
    }

    func deleteSession(id: Int) async throws {
        let token = try await getToken()
        let json = await APIBridge.shared.deleteSessionAsync(baseURL: baseURL, token: token, sessionID: Int32(id))
        try CoreResult.ensureSuccess(json)
    }

    func deleteAllSessions() async throws {
        let token = try await getToken()
        let json = await APIBridge.shared.deleteAllSessionsAsync(baseURL: baseURL, token: token)
        try CoreResult.ensureSuccess(json)
    }

    // MARK: - Activity

    func fetchActivity(limit: Int = 30) async throws -> [ActivityLogEntry] {
        let token = try await getToken()
        let json = await APIBridge.shared.fetchActivityAsync(baseURL: baseURL, token: token, limit: Int32(limit))
        struct Resp: Decodable { let activity: [ActivityLogEntry] }
        return try CoreResult.decodePayload(json, as: Resp.self, decoder: decoder).activity
    }

    /// Log a client-side activity event to the backend.
    /// Fire-and-forget — uses APIBridge.logActivityAsync (which itself runs Go HTTP).
    nonisolated func logActivity(type: String, description: String, context: String? = nil) {
        Task { @MainActor in
            do {
                let token = try await self.getToken()
                let _ = await APIBridge.shared.logActivityAsync(
                    baseURL: self.baseURL,
                    token: token,
                    type: type,
                    description: description,
                    context: context ?? ""
                )
            } catch {
                // Silent failure — activity logging should never disrupt the app
            }
        }
    }

    // MARK: - Helpers

    private func getToken() async throws -> String {
        guard let token = await AuthService.shared.getToken() else {
            throw CoreResult.makeError(code: 401, message: "Not authenticated")
        }
        return token
    }
}
