import Foundation

/// Feature keys matching backend `plan_feature_limits.feature_key` values.
public enum FeatureKey: String, CaseIterable, Sendable {
    // Resource limits
    case limitServers = "limit_servers"

    // Docker sub-feature gates (1 = enabled, 0 = disabled)
    case dockerCompose    = "feature_docker_compose"
    case dockerHealth     = "feature_docker_health"
    case dockerSecurity   = "feature_docker_security"
    case dockerLogs       = "feature_docker_logs"
    case dockerTools      = "feature_docker_tools"
    case dockerAICompose  = "feature_docker_ai_compose"
    case dockerDockerfile = "feature_docker_dockerfile"
    case dockerExport     = "feature_docker_export"
    case dockerTemplates  = "feature_docker_templates"

    // Git integration (1 = enabled, 0 = disabled)
    case git              = "feature_git"
}

/// Result of a feature gate check.
public enum FeatureGateResult: Sendable {
    case allowed
    case locked(currentPlan: String)
    case limitReached(limit: Int, current: Int)
    case expired
    case unknown

    public var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }
}

/// Decoded feature gate from the permit.
public struct FeatureGateEntry: Codable, Sendable {
    public let lim: Int
    public let cur: Int
    public let can: Bool
}

/// Decoded permit verification result from Go Core.
struct PermitVerifyResponse: Codable {
    let data: PermitVerifyData?
}

struct PermitVerifyData: Codable {
    let valid: Bool
    let plan: String?
    let sub_active: Bool?
    let gates: [String: FeatureGateEntry]?
    let accessible_server_ids: [String]?
    let server_limit: Int?
    let current_server_count: Int?
    let most_recent_server_id: String?
    let reason: String?
}

/// Feature Gate Manager
///
/// Central manager for subscription-gated features.
/// Uses Ed25519 signed permits from the backend, verified through Go Core.
///
/// - Layer 1 (this): Pre-filters UI decisions using cached permit
/// - Layer 2 (Go Core): Verifies Ed25519 signature + device binding
/// - Layer 3 (Backend): The FINAL wall — 403 on every protected action
///
/// Even if this manager is bypassed, the backend ALWAYS enforces limits.
public actor FeatureGateManager {

    public static let shared = FeatureGateManager()

    // Cached permit data (from last Ed25519-verified subscription check)
    private var cachedGates: [String: FeatureGateEntry] = [:]
    private var cachedPlan: String = "free"
    private var cachedSubActive: Bool = false
    private var cachedAccessibleServerIDs: [String] = []
    private var cachedServerLimit: Int = 1
    private var cachedCurrentServerCount: Int = 0
    private var cachedMostRecentServerID: String?
    private var isVerified: Bool = false

    private init() {}

    // MARK: - Feature Checking

    /// Check if a feature is available for the current user.
    /// Returns the gate result based on the cached permit.
    public func canUse(_ feature: FeatureKey) -> FeatureGateResult {
        guard isVerified else { return .unknown }

        guard let gate = cachedGates[feature.rawValue] else {
            return .unknown
        }

        if gate.can {
            return .allowed
        }

        // Determine the reason
        if gate.lim == 0 {
            return .locked(currentPlan: cachedPlan)
        }

        if !cachedSubActive && gate.lim == -1 {
            return .expired
        }

        return .limitReached(limit: gate.lim, current: gate.cur)
    }

    /// Quick boolean check for use in UI bindings.
    public func isAllowed(_ feature: FeatureKey) -> Bool {
        return canUse(feature).isAllowed
    }

    /// Check if a feature is enabled by gate key string.
    /// Returns true if: no gate exists (free feature), or gate `lim >= 1` / `can == true`.
    /// Returns false only if gate exists with `lim == 0` (explicitly disabled).
    /// If permit is not verified, returns false for safety.
    public func isFeatureEnabled(_ gateKey: String) -> Bool {
        guard isVerified else { return false }
        guard let gate = cachedGates[gateKey] else {
            return true // No gate = free feature, always accessible
        }
        return gate.can || gate.lim >= 1
    }

    /// Returns the limit value for any gate key (including per-type keys like "limit_websites_nginx").
    /// Returns nil if permit not verified or gate not found. Returns -1 for unlimited.
    public func gateLimit(for rawKey: String) -> Int? {
        guard isVerified, let gate = cachedGates[rawKey] else { return nil }
        return gate.lim
    }

    /// Returns all gate entries (for resource limit checking in UI).
    public var allGates: [String: FeatureGateEntry] {
        return cachedGates
    }

    /// Get the current plan name.
    public var currentPlan: String {
        return cachedPlan
    }

    /// Whether the subscription is currently active.
    public var isSubscriptionActive: Bool {
        return cachedSubActive
    }

    /// Whether the permit has been Ed25519-verified by Go Core.
    public var permitIsVerified: Bool {
        return isVerified
    }

    /// Server IDs the user can access (from SIGNED permit only).
    public var accessibleServerIDs: [String] {
        return cachedAccessibleServerIDs
    }

    /// Server limit for the user's plan (from SIGNED permit only).
    public var serverLimit: Int {
        return cachedServerLimit
    }

    /// Current server count (from SIGNED permit only).
    public var currentServerCount: Int {
        return cachedCurrentServerCount
    }

    /// Most recently created server ID (from SIGNED permit only).
    public var mostRecentServerID: String? {
        return cachedMostRecentServerID
    }

    // MARK: - Permit Update

    /// Update the cached permit from subscription status response.
    /// Calls Go Core to verify the Ed25519 signature + device binding.
    ///
    /// - Parameters:
    ///   - permitB64: Base64url-encoded permit from backend
    ///   - signatureB64: Base64url-encoded Ed25519 signature from backend
    public func updatePermit(permitB64: String, signatureB64: String) {
        // Get device ID for binding verification
        let deviceID = DeviceIdentifier.shared.getDeviceIDSync() ?? ""

        // Go Core verifies: Ed25519 signature + device match + expiry
        let resultJSON = CoreBridge.shared.verifyFeaturePermit(
            permitB64: permitB64,
            signatureB64: signatureB64,
            deviceID: deviceID
        )

        // Parse Go Core response
        guard let data = resultJSON.data(using: .utf8),
              let response = try? JSONDecoder().decode(PermitVerifyResponse.self, from: data),
              let verifyData = response.data,
              verifyData.valid else {
            CoreLogger.shared.warning("Feature permit verification failed", module: "FeatureGate")
            isVerified = false
            return
        }

        // Cache ALL verified data from signed permit
        cachedGates = verifyData.gates ?? [:]
        cachedPlan = verifyData.plan ?? "free"
        cachedSubActive = verifyData.sub_active ?? false
        cachedAccessibleServerIDs = verifyData.accessible_server_ids ?? []
        cachedServerLimit = verifyData.server_limit ?? 1
        cachedCurrentServerCount = verifyData.current_server_count ?? 0
        cachedMostRecentServerID = verifyData.most_recent_server_id
        isVerified = true

        CoreLogger.shared.debug("Feature permit verified — plan: \(cachedPlan), gates: \(cachedGates.count)", module: "FeatureGate")
    }

    /// Clear cached permit (e.g., on logout).
    public func clearPermit() {
        cachedGates = [:]
        cachedPlan = "free"
        cachedSubActive = false
        cachedAccessibleServerIDs = []
        cachedServerLimit = 1
        cachedCurrentServerCount = 0
        cachedMostRecentServerID = nil
        isVerified = false
    }
}
