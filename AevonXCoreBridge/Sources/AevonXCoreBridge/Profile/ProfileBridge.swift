//
//  ProfileBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Profile (user account) HTTP operations performed in Go.
//  Replaces the previous Swift-side URLSession code in AevonX/Services/ProfileAPIService.swift.
//
//  All network I/O happens in Go (with TLS pinning + error sanitization).
//  Swift only marshals JSON in/out and renders the result.
//

import Foundation
import AevonXCoreLib

extension APIBridge {

    // MARK: - Profile sync wrappers (on caller thread)

    /// PATCH /user/profile — update display name. Returns marshalResult JSON.
    public func updateProfile(baseURL: String, token: String, name: String) -> String {
        withCArgs { c in extractMarshalled(APIUpdateProfile(c.str(baseURL), c.str(token), c.str(name))) }
    }

    /// POST /user/password — change password.
    public func changePassword(baseURL: String, token: String, current: String, new: String) -> String {
        withCArgs { c in extractMarshalled(APIChangePassword(c.str(baseURL), c.str(token), c.str(current), c.str(new))) }
    }

    /// GET /user/sessions — list authenticated Sanctum sessions.
    public func fetchSessions(baseURL: String, token: String) -> String {
        withCArgs { c in extractMarshalled(APIFetchSessions(c.str(baseURL), c.str(token))) }
    }

    /// DELETE /user/sessions/{id} — revoke a single session.
    public func deleteSession(baseURL: String, token: String, sessionID: Int32) -> String {
        withCArgs { c in extractMarshalled(APIDeleteSession(c.str(baseURL), c.str(token), sessionID)) }
    }

    /// DELETE /user/sessions — revoke every non-current session.
    public func deleteAllSessions(baseURL: String, token: String) -> String {
        withCArgs { c in extractMarshalled(APIDeleteAllSessions(c.str(baseURL), c.str(token))) }
    }

    /// GET /user/activity?limit=N — recent activity log.
    public func fetchActivity(baseURL: String, token: String, limit: Int32) -> String {
        withCArgs { c in extractMarshalled(APIFetchActivity(c.str(baseURL), c.str(token), limit)) }
    }

    // MARK: - Profile async wrappers (off main thread)
    //
    // These mirror the existing async helpers in APIBridge.swift. CGo calls block
    // the caller, so we always dispatch to a background detached task to keep the
    // UI thread free.

    public func updateProfileAsync(baseURL: String, token: String, name: String) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.updateProfile(baseURL: baseURL, token: token, name: name)
        }.value
    }

    public func changePasswordAsync(baseURL: String, token: String, current: String, new: String) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.changePassword(baseURL: baseURL, token: token, current: current, new: new)
        }.value
    }

    public func fetchSessionsAsync(baseURL: String, token: String) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.fetchSessions(baseURL: baseURL, token: token)
        }.value
    }

    public func deleteSessionAsync(baseURL: String, token: String, sessionID: Int32) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.deleteSession(baseURL: baseURL, token: token, sessionID: sessionID)
        }.value
    }

    public func deleteAllSessionsAsync(baseURL: String, token: String) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.deleteAllSessions(baseURL: baseURL, token: token)
        }.value
    }

    public func fetchActivityAsync(baseURL: String, token: String, limit: Int32) async -> String {
        await Task.detached(priority: .userInitiated) { [self] in
            self.fetchActivity(baseURL: baseURL, token: token, limit: limit)
        }.value
    }

    // MARK: - Helper

    /// Extract a `*C.char` returned via Go's `marshalResult` (C.CString allocated, freed with `free`).
    private func extractMarshalled(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { free(cStr) }
        return String(cString: cStr)
    }
}
