//
//  ServiceManagementStrategy.swift
//  AevonXCore
//
//  Strategy protocol for managing system services across different init systems.
//  Implementations: SystemdStrategy, SysVInitStrategy, OpenRCStrategy.
//

import Foundation

// MARK: - Service Management Strategy

/// Protocol for managing system services.
///
/// Implementations encapsulate init-system-specific commands (systemd, SysV init, OpenRC).
/// Adapters use this protocol instead of hardcoding `systemctl` commands directly.
public protocol ServiceManagementStrategy: Sendable {
    
    /// Start a service.
    func startService(_ name: String, serverId: String) async throws
    
    /// Stop a service.
    func stopService(_ name: String, serverId: String) async throws
    
    /// Restart a service.
    func restartService(_ name: String, serverId: String) async throws
    
    /// Reload service configuration without full restart.
    func reloadService(_ name: String, serverId: String) async throws
    
    /// Get the current status of a service.
    func getServiceStatus(_ name: String, serverId: String) async throws -> ServiceStatus
    
    /// Enable a service to start on boot.
    func enableOnBoot(_ name: String, serverId: String) async throws
    
    /// Disable a service from starting on boot.
    func disableOnBoot(_ name: String, serverId: String) async throws
    
    /// Check if a service is enabled on boot.
    func isEnabledOnBoot(_ name: String, serverId: String) async throws -> Bool
}

// MARK: - Systemd Strategy

/// Service management using systemd (systemctl).
/// Used on most modern Linux distributions (Ubuntu 16+, Debian 8+, CentOS 7+, etc.)
public struct SystemdStrategy: ServiceManagementStrategy {
    
    private let sshService: any SSHServiceProtocol
    
    public init(sshService: any SSHServiceProtocol = SSHBridge.shared) {
        self.sshService = sshService
    }
    
    public func startService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo systemctl start \(safeName)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "start", reason: result.stderr)
        }
    }
    
    public func stopService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo systemctl stop \(safeName)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "stop", reason: result.stderr)
        }
    }
    
    public func restartService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo systemctl restart \(safeName)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "restart", reason: result.stderr)
        }
    }
    
    public func reloadService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo systemctl reload \(safeName)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "reload", reason: result.stderr)
        }
    }
    
    public func getServiceStatus(_ name: String, serverId: String) async throws -> ServiceStatus {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute(
            "LC_ALL=C systemctl is-active \(safeName) 2>/dev/null || echo 'unknown'",
            serverId: serverId
        )
        let status = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        switch status {
        case "active":   return .active
        case "inactive": return .inactive
        case "failed":   return .failed
        default:         return .unknown
        }
    }
    
    public func enableOnBoot(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo systemctl enable \(safeName)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "enable", reason: result.stderr)
        }
    }
    
    public func disableOnBoot(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo systemctl disable \(safeName)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "disable", reason: result.stderr)
        }
    }
    
    public func isEnabledOnBoot(_ name: String, serverId: String) async throws -> Bool {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute(
            "systemctl is-enabled \(safeName) 2>/dev/null",
            serverId: serverId
        )
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "enabled"
    }
}

// MARK: - SysV Init Strategy

/// Service management using SysV init (service / update-rc.d).
/// Used on older Linux distributions.
public struct SysVInitStrategy: ServiceManagementStrategy {
    
    private let sshService: any SSHServiceProtocol
    
    public init(sshService: any SSHServiceProtocol = SSHBridge.shared) {
        self.sshService = sshService
    }
    
    public func startService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo service \(safeName) start", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "start", reason: result.stderr)
        }
    }
    
    public func stopService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo service \(safeName) stop", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "stop", reason: result.stderr)
        }
    }
    
    public func restartService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo service \(safeName) restart", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "restart", reason: result.stderr)
        }
    }
    
    public func reloadService(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute("sudo service \(safeName) reload", serverId: serverId)
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "reload", reason: result.stderr)
        }
    }
    
    public func getServiceStatus(_ name: String, serverId: String) async throws -> ServiceStatus {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute(
            "sudo service \(safeName) status 2>/dev/null",
            serverId: serverId
        )
        let output = result.stdout.lowercased()
        if output.contains("running") || output.contains("active") {
            return .active
        } else if output.contains("stopped") || output.contains("not running") {
            return .inactive
        } else if result.exitCode != 0 {
            return .failed
        }
        return .unknown
    }
    
    public func enableOnBoot(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        // Try update-rc.d first (Debian-based), then chkconfig (RHEL-based)
        let result = try await sshService.execute(
            "sudo update-rc.d \(safeName) defaults 2>/dev/null || sudo chkconfig \(safeName) on 2>/dev/null",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "enable", reason: result.stderr)
        }
    }
    
    public func disableOnBoot(_ name: String, serverId: String) async throws {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute(
            "sudo update-rc.d \(safeName) disable 2>/dev/null || sudo chkconfig \(safeName) off 2>/dev/null",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.serviceActionFailed(action: "disable", reason: result.stderr)
        }
    }
    
    public func isEnabledOnBoot(_ name: String, serverId: String) async throws -> Bool {
        let safeName = ShellSanitizer.sanitizeServiceName(name)
        let result = try await sshService.execute(
            "chkconfig --list \(safeName) 2>/dev/null | grep ':on' || ls /etc/rc2.d/S*\(safeName) 2>/dev/null",
            serverId: serverId
        )
        return result.exitCode == 0 && !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Strategy Factory

/// Creates the appropriate ServiceManagementStrategy based on server profile.
public enum ServiceStrategyFactory {
    
    /// Returns the correct strategy for the given server's init system.
    public static func strategy(
        for profile: ServerProfile,
        sshService: any SSHServiceProtocol = SSHBridge.shared
    ) -> any ServiceManagementStrategy {
        switch profile.initSystem {
        case .systemd:
            return SystemdStrategy(sshService: sshService)
        case .sysvinit:
            return SysVInitStrategy(sshService: sshService)
        case .openrc:
            // OpenRC would need its own strategy; fall back to SysV for now
            return SysVInitStrategy(sshService: sshService)
        case .unknown:
            // Default to systemd as it's the most common
            return SystemdStrategy(sshService: sshService)
        }
    }
}
