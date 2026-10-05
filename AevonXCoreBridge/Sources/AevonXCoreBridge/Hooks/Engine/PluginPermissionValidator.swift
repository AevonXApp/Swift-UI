//
//  PluginPermissionValidator.swift
//  AevonXCoreBridge
//
//  Security layer for the Hook & Plugin System.
//  Uses Smart Auto-Trust: installed plugins with a manifest are trusted automatically.
//  Security comes from safe character validation, binary path sandboxing, and shell escaping.
//

import Foundation

// MARK: - Permission Validator

/// Validates plugin commands against security policies.
///
/// Security model (Smart Auto-Trust):
/// 1. Action names must be safe characters only: `[a-zA-Z0-9_-.]`
/// 2. Plugin must be installed (has a manifest registered in PluginManifestStore)
/// 3. Binary path must be in an allowed directory (enforced by HookCommandDispatcher)
/// 4. Payload values are shell-escaped (enforced by HookCommandDispatcher)
/// 5. Rate limiting prevents SSH flooding (enforced by HookRateLimiter)
public final class PluginPermissionValidator: Sendable {

    public static let shared = PluginPermissionValidator()

    private init() {}

    // MARK: - Safe Characters

    /// Characters allowed in action names — alphanumeric + underscore + hyphen + dot
    private static let safeActionChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-."))

    // MARK: - Validation

    /// Validates whether a plugin definition is allowed to execute.
    /// Checks: enabled state, permissions, and action safety.
    public func validate(plugin: HookPluginDefinition, userRole: String = "admin") -> PluginValidationResult {
        // Check if plugin is enabled
        guard plugin.isEnabled else {
            return .rejected(reason: "Plugin '\(plugin.id)' is disabled")
        }

        // Check permissions if specified
        if let requiredPermissions = plugin.permissions, !requiredPermissions.isEmpty {
            let hasPermission = requiredPermissions.contains(userRole) || requiredPermissions.contains("*")
            guard hasPermission else {
                return .rejected(reason: "User role '\(userRole)' does not have permission for plugin '\(plugin.id)'")
            }
        }

        // Validate command action if present
        if let command = plugin.command {
            let result = validateActionSafety(command.action)
            if case .rejected = result { return result }
        }

        // Validate layout card commands if present
        if let layout = plugin.layout, let cards = layout.cards {
            for card in cards {
                if let command = card.command {
                    let result = validateActionSafety(command.action)
                    if case .rejected = result { return result }
                }
                if let ds = card.dataSource {
                    let result = validateActionSafety(ds.action)
                    if case .rejected = result { return result }
                }
            }
        }

        // Validate top-level data_source
        if let ds = plugin.dataSource {
            let result = validateActionSafety(ds.action)
            if case .rejected = result { return result }
        }

        return .allowed
    }

    // MARK: - Action Safety

    /// Validates that an action name contains only safe characters.
    /// This is the ONLY check needed for action names — the plugin binary handles action routing.
    public func validateActionSafety(_ action: String) -> PluginValidationResult {
        // Reject empty actions
        guard !action.isEmpty else {
            return .rejected(reason: "Action name cannot be empty")
        }

        // Reject any action containing shell metacharacters
        let dangerousPatterns = [";", "&&", "||", "|", "`", "$(", ">", "<", "\\", "\n", "\r"]
        for pattern in dangerousPatterns {
            if action.contains(pattern) {
                CoreLogger.shared.warning(
                    "SECURITY: Action '\(action)' contains dangerous pattern '\(pattern)' — REJECTED",
                    module: "PluginPermissionValidator"
                )
                return .rejected(reason: "Action contains forbidden characters")
            }
        }

        // Validate action name is safe characters only
        guard action.unicodeScalars.allSatisfy({ Self.safeActionChars.contains($0) }) else {
            return .rejected(reason: "Action '\(action)' contains unsafe characters")
        }

        return .allowed
    }

    /// UserDefaults key that bypasses the manifest's allowed_actions list.
    /// Intended for plugin developers iterating on a build that hasn't yet
    /// declared every action it exposes. Off by default.
    public static let unrestrictedHooksKey = "developer.unrestricted_hooks"

    /// Validates a plugin_cmd action — checks safety + namespace has a
    /// manifest + the action is in the manifest's `allowed_actions` (when
    /// declared). The developer toggle bypasses the allowed-list check.
    public func validatePluginAction(_ action: String, namespace: String?) -> PluginValidationResult {
        guard let ns = namespace else {
            return .rejected(reason: "plugin_cmd requires a namespace")
        }

        // Check action name safety
        let safetyResult = validateActionSafety(action)
        if case .rejected = safetyResult { return safetyResult }

        // Plugin must be installed (has a manifest)
        guard let manifest = PluginManifestStore.shared.manifest(for: ns) else {
            CoreLogger.shared.warning(
                "SECURITY: No manifest found for namespace '\(ns)' — plugin not installed",
                module: "PluginPermissionValidator"
            )
            return .rejected(reason: "No manifest for namespace '\(ns)' — plugin not installed")
        }

        // Developer escape hatch — short-circuits the allowed_actions gate
        let unrestricted = UserDefaults.standard.bool(forKey: Self.unrestrictedHooksKey)

        if !unrestricted, let allowed = manifest.allowedActions, !allowed.isEmpty {
            // Both fully-qualified ("axghost.webhook.setup") and short
            // ("webhook.setup") forms are accepted to match how the manifest
            // is typically authored.
            let qualified = "\(ns).\(action)"
            let isAllowed = allowed.contains(action) || allowed.contains(qualified)
            if !isAllowed {
                CoreLogger.shared.warning(
                    "SECURITY: Action '\(action)' is not in allowed_actions for '\(ns)' — REJECTED",
                    module: "PluginPermissionValidator"
                )
                return .rejected(reason: "Action '\(action)' not permitted by '\(ns)' manifest")
            }
        }

        CoreLogger.shared.debug(
            "Action '\(action)' trusted via installed plugin '\(ns)' (unrestricted=\(unrestricted))",
            module: "PluginPermissionValidator"
        )
        return .allowed
    }

    /// Validates template variables in a payload to prevent injection
    public func validatePayload(_ payload: [String: AnyCodable]) -> Bool {
        for (_, value) in payload {
            let str = value.stringValue
            let forbidden = [";", "&&", "||", "|", "`", "$(", ">", "<", "\\"]
            for pattern in forbidden {
                if str.contains(pattern) {
                    CoreLogger.shared.warning(
                        "SECURITY: Plugin payload value '\(str)' contains forbidden pattern '\(pattern)' — REJECTED",
                        module: "PluginPermissionValidator"
                    )
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - Validation Result

public enum PluginValidationResult: Sendable {
    case allowed
    case rejected(reason: String)

    public var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }

    public var rejectionReason: String? {
        if case .rejected(let reason) = self { return reason }
        return nil
    }
}
