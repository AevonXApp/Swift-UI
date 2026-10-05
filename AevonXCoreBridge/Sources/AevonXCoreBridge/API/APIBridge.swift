//
//  APIBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core API operations.
//  Covers: endpoints, config, validation, error descriptions, model decode.
//

import Foundation
import AevonXCoreLib

public final class APIBridge: @unchecked Sendable {

    public static let shared = APIBridge()
    private init() {}

    // MARK: - Endpoints

    public func getEndpoints() -> String {
        extract(APIGetEndpoints())
    }

    public func getServerEndpoint(id: String) -> String {
        withCArgs { c in extract(APIGetServerEndpoint(c.str(id))) }
    }

    public func getServerAuthorizeEndpoint(serverID: String) -> String {
        withCArgs { c in extract(APIGetServerAuthorizeEndpoint(c.str(serverID))) }
    }

    public func getPluginEndpoint(id: String) -> String {
        withCArgs { c in extract(APIGetPluginEndpoint(c.str(id))) }
    }

    public func getPluginDownloadEndpoint(id: String) -> String {
        withCArgs { c in extract(APIGetPluginDownloadEndpoint(c.str(id))) }
    }

    // MARK: - Config

    public func buildFullBaseURL(host: String, port: Int32, apiVersion: String, useHTTPS: Bool) -> String {
        withCArgs { c in extract(APIBuildFullBaseURL(c.str(host), port, c.str(apiVersion), useHTTPS ? 1 : 0)) }
    }

    public func getEnvironmentConfig(env: String) -> String {
        withCArgs { c in extract(APIGetEnvironmentConfig(c.str(env))) }
    }

    public func getAppURLs(env: String) -> String {
        withCArgs { c in extract(APIGetAppURLs(c.str(env))) }
    }

    public func httpStatusDescription(code: Int32) -> String {
        extract(APIHTTPStatusDescription(code))
    }

    // MARK: - Validation

    public func validateRegistration(name: String, username: String, email: String, password: String, confirmation: String) -> String {
        withCArgs { c in extract(APIValidateRegistration(c.str(name), c.str(username), c.str(email), c.str(password), c.str(confirmation))) }
    }

    public func validateLogin(login: String, password: String) -> String {
        withCArgs { c in extract(APIValidateLogin(c.str(login), c.str(password))) }
    }

    public func validateUsername(_ username: String) -> String {
        withCArgs { c in extract(APIValidateUsername(c.str(username))) }
    }

    public func maskEmail(_ email: String) -> String {
        withCArgs { c in extract(APIMaskEmail(c.str(email))) }
    }

    // MARK: - Error Descriptions

    public func authErrorDescription(code: String, detail: String) -> String {
        withCArgs { c in extract(APIAuthErrorDescription(c.str(code), c.str(detail))) }
    }

    public func serverErrorDescription(code: String, detail: String) -> String {
        withCArgs { c in extract(APIServerErrorDescription(c.str(code), c.str(detail))) }
    }

    public func vaultErrorDescription(code: String, detail: String) -> String {
        withCArgs { c in extract(APIVaultErrorDescription(c.str(code), c.str(detail))) }
    }

    public func pluginErrorDescription(code: String, detail: String) -> String {
        withCArgs { c in extract(APIPluginErrorDescription(c.str(code), c.str(detail))) }
    }

    // MARK: - Model Decode

    public func decodeUser(json: String) -> String {
        withCArgs { c in extract(APIDecodeUser(c.str(json))) }
    }

    public func decodeAuthResponse(json: String) -> String {
        withCArgs { c in extract(APIDecodeAuthResponse(c.str(json))) }
    }

    public func decodeServerResponse(json: String) -> String {
        withCArgs { c in extract(APIDecodeServerResponse(c.str(json))) }
    }

    public func decodeCATResponse(json: String) -> String {
        withCArgs { c in extract(APIDecodeCATResponse(c.str(json))) }
    }

    public func decodeSubscriptionStatus(json: String) -> String {
        withCArgs { c in extract(APIDecodeSubscriptionStatus(c.str(json))) }
    }

    public func getAllAuthErrors() -> String {
        extract(APIGetAllAuthErrors())
    }

    public func getAllServerErrors() -> String {
        extract(APIGetAllServerErrors())
    }

    public func userPlanLabel(json: String) -> String {
        withCArgs { c in extract(APIUserPlanLabel(c.str(json))) }
    }

    // MARK: - Auth HTTP (Go handles all network calls)

    /// Login via Go net/http — accepts email or username.
    public func login(baseURL: String, login: String, password: String, deviceID: String) -> String {
        withCArgs { c in extractAuth(APILogin(c.str(baseURL), c.str(login), c.str(password), c.str(deviceID))) }
    }

    /// Register via Go net/http.
    public func register(baseURL: String, name: String, username: String, email: String, password: String, confirmation: String, deviceID: String) -> String {
        withCArgs { c in extractAuth(APIRegister(c.str(baseURL), c.str(name), c.str(username), c.str(email), c.str(password), c.str(confirmation), c.str(deviceID))) }
    }

    /// Logout via Go net/http.
    public func logout(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APILogout(c.str(baseURL), c.str(token))) }
    }

    /// Get current user via Go net/http.
    public func getCurrentUser(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIGetCurrentUser(c.str(baseURL), c.str(token))) }
    }

    /// Check trial eligibility via Go net/http.
    public func checkTrialEligibility(baseURL: String, token: String, deviceID: String) -> String {
        withCArgs { c in extractAuth(APICheckTrialEligibility(c.str(baseURL), c.str(token), c.str(deviceID))) }
    }

    /// Forgot password via Go net/http.
    public func forgotPassword(baseURL: String, email: String, deviceID: String) -> String {
        withCArgs { c in extractAuth(APIForgotPassword(c.str(baseURL), c.str(email), c.str(deviceID))) }
    }

    // MARK: - Challenge HTTP (Go handles all network calls)

    /// Request a signed challenge from the server.
    public func requestChallenge(baseURL: String, deviceID: String) -> String {
        withCArgs { c in extractAuth(APIRequestChallenge(c.str(baseURL), c.str(deviceID))) }
    }

    /// Solve a challenge locally (Ed25519 verification in Go).
    public func solveChallenge(challengeToken: String, deviceID: String) -> String {
        withCArgs { c in extractAuth(APISolveChallenge(c.str(challengeToken), c.str(deviceID))) }
    }

    // MARK: - Device HTTP (Go handles all network calls)

    /// Fetch user's devices.
    public func fetchDevices(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIFetchDevices(c.str(baseURL), c.str(token))) }
    }

    /// Delete a device.
    public func deleteDevice(baseURL: String, token: String, deviceID: Int32) -> String {
        withCArgs { c in extractAuth(APIDeleteDevice(c.str(baseURL), c.str(token), deviceID)) }
    }

    // MARK: - Server CRUD HTTP (Go handles all network calls)

    /// Fetch all servers via Go net/http.
    public func fetchServers(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIFetchServers(c.str(baseURL), c.str(token))) }
    }

    /// Fetch single server via Go net/http.
    public func fetchServer(baseURL: String, token: String, serverID: String) -> String {
        withCArgs { c in extractAuth(APIFetchServer(c.str(baseURL), c.str(token), c.str(serverID))) }
    }

    /// Create server via Go net/http (encrypted payload as JSON).
    public func createServer(baseURL: String, token: String, payloadJSON: String) -> String {
        withCArgs { c in extractAuth(APICreateServer(c.str(baseURL), c.str(token), c.str(payloadJSON))) }
    }

    /// Update server via Go net/http (encrypted payload as JSON).
    public func updateServer(baseURL: String, token: String, serverID: String, payloadJSON: String) -> String {
        withCArgs { c in extractAuth(APIUpdateServer(c.str(baseURL), c.str(token), c.str(serverID), c.str(payloadJSON))) }
    }

    /// Delete server via Go net/http.
    public func deleteServer(baseURL: String, token: String, serverID: String) -> String {
        withCArgs { c in extractAuth(APIDeleteServer(c.str(baseURL), c.str(token), c.str(serverID))) }
    }

    /// Fetch subscription status via Go net/http.
    public func fetchSubscriptionStatus(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIFetchSubscriptionStatus(c.str(baseURL), c.str(token))) }
    }

    /// Fetch plan comparison data for paywall UI via Go net/http.
    public func fetchPlanComparison(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIFetchPlanComparison(c.str(baseURL), c.str(token))) }
    }

    /// Async: Fetch plan comparison data for paywall UI.
    public func fetchPlanComparisonAsync(baseURL: String, token: String) async -> String {
        await background { [self] in fetchPlanComparison(baseURL: baseURL, token: token) }
    }

    /// Request Connection Authorization Token (CAT) via Go net/http.
    public func requestCAT(baseURL: String, token: String, serverID: String, fingerprint: String) -> String {
        withCArgs { c in extractAuth(APIRequestCAT(c.str(baseURL), c.str(token), c.str(serverID), c.str(fingerprint))) }
    }

    /// Fetch per-device Ed25519 public keys via ECDH secure channel.
    public func fetchDeviceKeys(baseURL: String, token: String, fingerprint: String) -> String {
        withCArgs { c in extractAuth(APIFetchDeviceKeys(c.str(baseURL), c.str(token), c.str(fingerprint))) }
    }

    // MARK: - Vault HTTP (Go handles all network calls)

    /// Check vault status via Go net/http.
    public func checkVaultStatus(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APICheckVaultStatus(c.str(baseURL), c.str(token))) }
    }

    /// Register recovery key via Go net/http.
    public func registerRecoveryKey(baseURL: String, token: String, verifierHash: String, salt: String) -> String {
        withCArgs { c in extractAuth(APIRegisterRecoveryKey(c.str(baseURL), c.str(token), c.str(verifierHash), c.str(salt))) }
    }

    /// Verify recovery key via Go net/http.
    public func verifyRecoveryKey(baseURL: String, token: String, verifierHash: String) -> String {
        withCArgs { c in extractAuth(APIVerifyRecoveryKey(c.str(baseURL), c.str(token), c.str(verifierHash))) }
    }

    /// Check recovery key status via Go net/http.
    public func checkRecoveryKeyStatus(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APICheckRecoveryKeyStatus(c.str(baseURL), c.str(token))) }
    }

    /// Get server ECDH public key via Go net/http.
    public func getServerPublicKey(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIGetServerPublicKey(c.str(baseURL), c.str(token))) }
    }

    // MARK: - Plugin HTTP (Go handles all network calls)

    /// Fetch paginated plugins via Go net/http.
    public func fetchPlugins(baseURL: String, token: String, page: Int32, search: String, pricing: String, category: String) -> String {
        withCArgs { c in extractAuth(APIFetchPlugins(c.str(baseURL), c.str(token), page, c.str(search), c.str(pricing), c.str(category))) }
    }

    /// Fetch plugin categories via Go net/http.
    public func fetchPluginCategories(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APIFetchPluginCategories(c.str(baseURL), c.str(token))) }
    }

    /// Fetch single plugin details via Go net/http.
    public func fetchPlugin(baseURL: String, token: String, pluginID: String) -> String {
        withCArgs { c in extractAuth(APIFetchPlugin(c.str(baseURL), c.str(token), c.str(pluginID))) }
    }

    /// Get plugin download info (one-time token) via Go net/http.
    /// When serverIP is provided, the download token is bound to the server's IP
    /// (for server-side curl downloads) instead of the client's IP.
    /// Architecture (amd64/arm64) tells the backend to return an arch-specific ZIP.
    public func getPluginDownloadInfo(baseURL: String, token: String, pluginID: String, versionID: String, serverID: String, serverIP: String = "", architecture: String = "") -> String {
        withCArgs { c in extractAuth(APIGetPluginDownloadInfo(c.str(baseURL), c.str(token), c.str(pluginID), c.str(versionID), c.str(serverID), c.str(serverIP), c.str(architecture))) }
    }

    /// Set remote server fingerprint (collected via SSH) before license verification.
    /// Ensures Fortress uses real server hardware identity, not local macOS info.
    public func setRemoteFingerprint(serverID: String, fingerprintJSON: String) -> String {
        withCArgs { c in extractAuth(APISetRemoteFingerprint(c.str(serverID), c.str(fingerprintJSON))) }
    }

    /// Runtime license verification — checks if a plugin is licensed for a server.
    /// Uses secure channel (ECDH + signed request/response).
    public func verifyPluginLicense(baseURL: String, token: String, pluginSlug: String, serverID: String) -> String {
        withCArgs { c in extractAuth(APIVerifyPluginLicense(c.str(baseURL), c.str(token), c.str(pluginSlug), c.str(serverID))) }
    }

    /// Establish a secure channel via ECDH X25519 key exchange.
    public func securityHandshake(baseURL: String, token: String) -> String {
        withCArgs { c in extractAuth(APISecurityHandshake(c.str(baseURL), c.str(token))) }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }

    /// Extract for auth HTTP calls (uses C.CString allocation from marshalResult).
    private func extractAuth(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { free(cStr) }
        return String(cString: cStr)
    }
}

// MARK: - Async Wrappers (off main thread)
// All Go CGo HTTP calls are synchronous and block the calling thread.
// These async wrappers dispatch to a background thread so @MainActor
// ViewModels never freeze the UI.

extension APIBridge {

    /// Run a synchronous CGo call on a background thread.
    private func background(_ work: @escaping @Sendable () -> String) async -> String {
        await Task.detached(priority: .userInitiated) { work() }.value
    }

    // MARK: Auth HTTP (Async)

    public func loginAsync(baseURL: String, login: String, password: String, deviceID: String) async -> String {
        await background { [self] in self.login(baseURL: baseURL, login: login, password: password, deviceID: deviceID) }
    }

    public func registerAsync(baseURL: String, name: String, username: String, email: String, password: String, confirmation: String, deviceID: String) async -> String {
        await background { [self] in register(baseURL: baseURL, name: name, username: username, email: email, password: password, confirmation: confirmation, deviceID: deviceID) }
    }

    public func logoutAsync(baseURL: String, token: String) async -> String {
        await background { [self] in logout(baseURL: baseURL, token: token) }
    }

    /// Log an activity event via Go net/http (fire-and-forget).
    public func logActivity(baseURL: String, token: String, type: String, description: String, context: String) -> String {
        withCArgs { c in extractAuth(APILogActivity(c.str(baseURL), c.str(token), c.str(type), c.str(description), c.str(context))) }
    }

    public func logActivityAsync(baseURL: String, token: String, type: String, description: String, context: String = "") async -> String {
        await background { [self] in logActivity(baseURL: baseURL, token: token, type: type, description: description, context: context) }
    }

    public func getCurrentUserAsync(baseURL: String, token: String) async -> String {
        await background { [self] in getCurrentUser(baseURL: baseURL, token: token) }
    }

    public func checkTrialEligibilityAsync(baseURL: String, token: String, deviceID: String) async -> String {
        await background { [self] in checkTrialEligibility(baseURL: baseURL, token: token, deviceID: deviceID) }
    }

    public func forgotPasswordAsync(baseURL: String, email: String, deviceID: String) async -> String {
        await background { [self] in forgotPassword(baseURL: baseURL, email: email, deviceID: deviceID) }
    }

    // MARK: Challenge HTTP (Async)

    public func requestChallengeAsync(baseURL: String, deviceID: String) async -> String {
        await background { [self] in requestChallenge(baseURL: baseURL, deviceID: deviceID) }
    }

    public func solveChallengeAsync(challengeToken: String, deviceID: String) async -> String {
        await background { [self] in solveChallenge(challengeToken: challengeToken, deviceID: deviceID) }
    }

    // MARK: Device HTTP (Async)

    public func fetchDevicesAsync(baseURL: String, token: String) async -> String {
        await background { [self] in fetchDevices(baseURL: baseURL, token: token) }
    }

    public func deleteDeviceAsync(baseURL: String, token: String, deviceID: Int32) async -> String {
        await background { [self] in deleteDevice(baseURL: baseURL, token: token, deviceID: deviceID) }
    }

    // MARK: Server CRUD HTTP (Async)

    public func fetchServersAsync(baseURL: String, token: String) async -> String {
        await background { [self] in fetchServers(baseURL: baseURL, token: token) }
    }

    public func fetchServerAsync(baseURL: String, token: String, serverID: String) async -> String {
        await background { [self] in fetchServer(baseURL: baseURL, token: token, serverID: serverID) }
    }

    public func createServerAsync(baseURL: String, token: String, payloadJSON: String) async -> String {
        await background { [self] in createServer(baseURL: baseURL, token: token, payloadJSON: payloadJSON) }
    }

    public func updateServerAsync(baseURL: String, token: String, serverID: String, payloadJSON: String) async -> String {
        await background { [self] in updateServer(baseURL: baseURL, token: token, serverID: serverID, payloadJSON: payloadJSON) }
    }

    public func deleteServerAsync(baseURL: String, token: String, serverID: String) async -> String {
        await background { [self] in deleteServer(baseURL: baseURL, token: token, serverID: serverID) }
    }

    /// Lock for ECDH-dependent calls. Go's secure channel uses a single global
    /// session — concurrent handshakes overwrite each other's keys, causing
    /// response signature verification failures. This lock ensures only one
    /// ECDH call runs at a time on the background dispatch queue.
    private static let ecdhLock = NSLock()

    public func fetchSubscriptionStatusAsync(baseURL: String, token: String) async -> String {
        await background { [self] in
            Self.ecdhLock.lock()
            defer { Self.ecdhLock.unlock() }
            return fetchSubscriptionStatus(baseURL: baseURL, token: token)
        }
    }

    public func requestCATAsync(baseURL: String, token: String, serverID: String, fingerprint: String) async -> String {
        await background { [self] in requestCAT(baseURL: baseURL, token: token, serverID: serverID, fingerprint: fingerprint) }
    }

    public func fetchDeviceKeysAsync(baseURL: String, token: String, fingerprint: String) async -> String {
        await background { [self] in
            Self.ecdhLock.lock()
            defer { Self.ecdhLock.unlock() }
            return fetchDeviceKeys(baseURL: baseURL, token: token, fingerprint: fingerprint)
        }
    }

    // MARK: Vault HTTP (Async)

    public func checkVaultStatusAsync(baseURL: String, token: String) async -> String {
        await background { [self] in checkVaultStatus(baseURL: baseURL, token: token) }
    }

    public func registerRecoveryKeyAsync(baseURL: String, token: String, verifierHash: String, salt: String) async -> String {
        await background { [self] in registerRecoveryKey(baseURL: baseURL, token: token, verifierHash: verifierHash, salt: salt) }
    }

    public func verifyRecoveryKeyAsync(baseURL: String, token: String, verifierHash: String) async -> String {
        await background { [self] in verifyRecoveryKey(baseURL: baseURL, token: token, verifierHash: verifierHash) }
    }

    public func checkRecoveryKeyStatusAsync(baseURL: String, token: String) async -> String {
        await background { [self] in checkRecoveryKeyStatus(baseURL: baseURL, token: token) }
    }

    public func getServerPublicKeyAsync(baseURL: String, token: String) async -> String {
        await background { [self] in getServerPublicKey(baseURL: baseURL, token: token) }
    }

    // MARK: Plugin HTTP (Async)

    public func fetchPluginsAsync(baseURL: String, token: String, page: Int32, search: String, pricing: String, category: String) async -> String {
        await background { [self] in fetchPlugins(baseURL: baseURL, token: token, page: page, search: search, pricing: pricing, category: category) }
    }

    public func fetchPluginCategoriesAsync(baseURL: String, token: String) async -> String {
        await background { [self] in fetchPluginCategories(baseURL: baseURL, token: token) }
    }

    public func fetchPluginAsync(baseURL: String, token: String, pluginID: String) async -> String {
        await background { [self] in fetchPlugin(baseURL: baseURL, token: token, pluginID: pluginID) }
    }

    public func getPluginDownloadInfoAsync(baseURL: String, token: String, pluginID: String, versionID: String, serverID: String, serverIP: String = "", architecture: String = "") async -> String {
        await background { [self] in getPluginDownloadInfo(baseURL: baseURL, token: token, pluginID: pluginID, versionID: versionID, serverID: serverID, serverIP: serverIP, architecture: architecture) }
    }

    public func verifyPluginLicenseAsync(baseURL: String, token: String, pluginSlug: String, serverID: String) async -> String {
        await background { [self] in verifyPluginLicense(baseURL: baseURL, token: token, pluginSlug: pluginSlug, serverID: serverID) }
    }

    public func securityHandshakeAsync(baseURL: String, token: String) async -> String {
        await background { [self] in securityHandshake(baseURL: baseURL, token: token) }
    }
}
