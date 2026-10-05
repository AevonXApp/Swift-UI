import Foundation

/// Access level for a server
public enum ServerAccessLevel: String {
    case full = "full"
    case readOnly = "read_only"
    case none = "none"
}

/// Accessible server with access level information
public struct AccessibleServer: Identifiable {
    public let id: String
    public let server: ServerResponse
    public let accessLevel: ServerAccessLevel
    
    public init(id: String, server: ServerResponse, accessLevel: ServerAccessLevel) {
        self.id = id
        self.server = server
        self.accessLevel = accessLevel
    }
}

/// Service for managing subscription status and server access
public actor SubscriptionManager {
    
    public static let shared = SubscriptionManager()
    
    // MARK: - Properties
    
    private var cachedStatus: SubscriptionStatus?
    private var lastFetch: Date?
    private let cacheValidity: TimeInterval = 60 // Cache for 60 seconds (was 600 — reduced for security)
    
    /// Injectable API fetch closure — set from app layer to avoid circular dependency.
    /// Takes (baseURL, token) → JSON response string.
    public var apiFetcher: (@Sendable (String, String) async -> String)?
    
    private init() {}
    
    /// Configure the API fetcher from the app layer.
    public func setApiFetcher(_ fetcher: @escaping @Sendable (String, String) async -> String) {
        self.apiFetcher = fetcher
    }
    
    // MARK: - Subscription Status
    
    /// Fetches current subscription status
    /// - Parameter forceRefresh: If true, ignores cache and fetches fresh data
    /// - Returns: Current subscription status
    public func getSubscriptionStatus(forceRefresh: Bool = false) async throws -> SubscriptionStatus {
        // Check cache
        if !forceRefresh,
           let cached = cachedStatus,
           let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidity {
            return cached
        }
        
        // Fetch fresh data via injected API fetcher
        let token = await AuthService.shared.getToken() ?? ""
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
        
        guard let fetcher = apiFetcher else {
            throw NSError(domain: "SubscriptionManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "API fetcher not configured"])
        }
        let resultJSON = await fetcher(baseURL, token)
        
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let respData = result["data"] as? [String: Any] else {
            throw NSError(domain: "SubscriptionManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch subscription status"])
        }
        
        // Parse Ed25519-signed feature permit from backend
        let featurePermit = respData["feature_permit"] as? String
        let permitSig = respData["permit_signature"] as? String

        // CRITICAL: Verify permit through Go Core FIRST (Ed25519 + device binding)
        if let permit = featurePermit, let sig = permitSig {
            await FeatureGateManager.shared.updatePermit(permitB64: permit, signatureB64: sig)
        }

        // Build status from VERIFIED permit data ONLY — never from unsigned JSON.
        // If permit verification failed, FeatureGateManager.permitIsVerified = false
        // and all access-critical fields default to deny (free plan, no servers).
        let fgm = FeatureGateManager.shared
        let permitVerified = await fgm.permitIsVerified

        let verifiedPlan: String
        let verifiedServerLimit: Int
        let verifiedServerCount: Int
        let verifiedAccessibleIDs: [String]
        let verifiedSubActive: Bool
        let verifiedMostRecentID: String?

        if permitVerified {
            // TRUSTED: Data extracted from Ed25519-verified permit
            verifiedPlan = await fgm.currentPlan
            verifiedServerLimit = await fgm.serverLimit
            verifiedServerCount = await fgm.currentServerCount
            verifiedAccessibleIDs = await fgm.accessibleServerIDs
            verifiedSubActive = await fgm.isSubscriptionActive
            verifiedMostRecentID = await fgm.mostRecentServerID
        } else {
            // DENY BY DEFAULT: Permit not verified — treat as free with no access
            CoreLogger.shared.warning("Permit verification failed — defaulting to deny-all", module: "Subscription")
            verifiedPlan = "free"
            verifiedServerLimit = 1
            verifiedServerCount = 0
            verifiedAccessibleIDs = []
            verifiedSubActive = false
            verifiedMostRecentID = nil
        }

        let status = SubscriptionStatus(
            plan: verifiedPlan,
            serverLimit: verifiedServerLimit,
            currentServerCount: verifiedServerCount,
            accessibleServerIds: verifiedAccessibleIDs,
            subscription: SubscriptionInfo(
                active: verifiedSubActive,
                expiredAt: nil,
                mostRecentServerId: verifiedMostRecentID
            ),
            permitJSON: featurePermit,
            permitSignature: permitSig
        )

        cachedStatus = status
        lastFetch = Date()

        return status
    }
    
    /// Clears the cached subscription status
    public func clearCache() {
        cachedStatus = nil
        lastFetch = nil
    }
    
    // MARK: - Server Access Control
    
    /// Determines accessible servers based on Ed25519-verified permit data.
    /// NEVER uses unsigned API response fields — only data verified by Go Core.
    /// - Parameter servers: All servers from the API
    /// - Returns: Array of accessible servers with their access levels
    public func getAccessibleServers(from servers: [ServerResponse]) async -> [AccessibleServer] {
        // Ensure we have a fresh subscription status (triggers permit verification)
        guard let _ = try? await getSubscriptionStatus() else {
            // No status = no verified permit = DENY ALL
            return servers.map { AccessibleServer(id: $0.id, server: $0, accessLevel: .readOnly) }
        }

        // Get access data from VERIFIED permit only
        let fgm = FeatureGateManager.shared
        let permitVerified = await fgm.permitIsVerified

        guard permitVerified else {
            // Permit not verified = ALL read-only (deny by default)
            return servers.map { AccessibleServer(id: $0.id, server: $0, accessLevel: .readOnly) }
        }

        let accessibleIDs = Set(await fgm.accessibleServerIDs)

        return servers.map { server in
            let level: ServerAccessLevel = accessibleIDs.contains(server.id) ? .full : .readOnly
            return AccessibleServer(id: server.id, server: server, accessLevel: level)
        }
    }
    
    /// Checks if user can add a new server using Ed25519-verified permit.
    /// NO FALLBACK to unsigned data — if permit not verified, DENY.
    /// - Returns: true if user can add a server
    public func canAddServer() async -> Bool {
        // Ensure permit is fresh
        let _ = try? await getSubscriptionStatus()

        // ONLY use Ed25519-verified gate result
        let gateResult = await FeatureGateManager.shared.canUse(.limitServers)
        if case .allowed = gateResult {
            return true
        }
        // .unknown = permit not verified → DENY (no fallback to unsigned data)
        return false
    }
    
    /// Checks if a specific server can be modified (from VERIFIED permit only).
    /// - Parameter serverId: The server ID
    /// - Returns: true if the server can be modified
    public func canModifyServer(serverId: String) async -> Bool {
        let _ = try? await getSubscriptionStatus()
        let fgm = FeatureGateManager.shared
        guard await fgm.permitIsVerified else { return false }
        return await fgm.accessibleServerIDs.contains(serverId)
    }

    /// Gets the access level for a specific server (from VERIFIED permit only).
    /// - Parameter serverId: The server ID
    /// - Returns: The access level
    public func getAccessLevel(for serverId: String) async -> ServerAccessLevel {
        let _ = try? await getSubscriptionStatus()
        let fgm = FeatureGateManager.shared
        guard await fgm.permitIsVerified else { return .readOnly }

        if await fgm.accessibleServerIDs.contains(serverId) {
            return .full
        }
        return .readOnly
    }
    
    /// Gets the remaining server slots (from VERIFIED permit only).
    /// - Returns: Number of additional servers that can be added
    public func remainingServerSlots() async -> Int {
        let _ = try? await getSubscriptionStatus()
        let fgm = FeatureGateManager.shared
        guard await fgm.permitIsVerified else { return 0 }
        let limit = await fgm.serverLimit
        let current = await fgm.currentServerCount
        return max(0, limit - current)
    }

    // MARK: - Plan Information

    /// Gets the current plan name (from VERIFIED permit only).
    /// - Returns: Plan name
    public func currentPlan() async -> String {
        let _ = try? await getSubscriptionStatus()
        let fgm = FeatureGateManager.shared
        guard await fgm.permitIsVerified else { return "free" }
        return await fgm.currentPlan
    }

    /// Checks if user has an active subscription (from VERIFIED permit only).
    /// - Returns: true if subscription is active
    public func hasActiveSubscription() async -> Bool {
        let _ = try? await getSubscriptionStatus()
        let fgm = FeatureGateManager.shared
        guard await fgm.permitIsVerified else { return false }
        return await fgm.isSubscriptionActive
    }
}
