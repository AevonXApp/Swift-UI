//
//  PackageManagementStrategy.swift
//  AevonXCore
//
//  Strategy protocol for managing system packages across different package managers.
//  Implementations: AptStrategy, YumDnfStrategy, ApkStrategy.
//

import Foundation

// MARK: - Package Management Strategy

/// Protocol for managing system packages.
///
/// Implementations encapsulate package-manager-specific commands (apt, yum/dnf, apk).
/// Adapters use this protocol instead of hardcoding `apt-get` commands directly.
public protocol PackageManagementStrategy: Sendable {
    
    /// Install a package.
    func install(_ package: String, serverId: String) async throws
    
    /// Remove a package.
    func remove(_ package: String, serverId: String) async throws
    
    /// Purge a package (remove including config files).
    func purge(_ package: String, serverId: String) async throws
    
    /// Check if a package is installed.
    func isInstalled(_ package: String, serverId: String) async throws -> Bool
    
    /// Update package lists.
    func updatePackageLists(serverId: String) async throws
    
    /// Upgrade all installed packages.
    func upgradeAll(serverId: String) async throws
}

// MARK: - APT Strategy

/// Package management using APT (Debian, Ubuntu).
public struct AptStrategy: PackageManagementStrategy {
    
    private let sshService: any SSHServiceProtocol
    
    public init(sshService: any SSHServiceProtocol = SSHBridge.shared) {
        self.sshService = sshService
    }
    
    public func install(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo DEBIAN_FRONTEND=noninteractive LC_ALL=C apt-get install -y \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to install \(package): \(result.stderr)")
        }
    }
    
    public func remove(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo DEBIAN_FRONTEND=noninteractive LC_ALL=C apt-get remove -y \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to remove \(package): \(result.stderr)")
        }
    }
    
    public func purge(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo DEBIAN_FRONTEND=noninteractive LC_ALL=C apt-get purge -y \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to purge \(package): \(result.stderr)")
        }
    }
    
    public func isInstalled(_ package: String, serverId: String) async throws -> Bool {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "dpkg -s \(safePkg) 2>/dev/null | grep -q '^Status: install ok installed'",
            serverId: serverId
        )
        return result.exitCode == 0
    }
    
    public func updatePackageLists(serverId: String) async throws {
        let result = try await sshService.execute(
            "sudo LC_ALL=C apt-get update -qq",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to update package lists: \(result.stderr)")
        }
    }
    
    public func upgradeAll(serverId: String) async throws {
        let result = try await sshService.execute(
            "sudo DEBIAN_FRONTEND=noninteractive LC_ALL=C apt-get upgrade -y",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to upgrade packages: \(result.stderr)")
        }
    }
}

// MARK: - YUM/DNF Strategy

/// Package management using YUM or DNF (CentOS, RHEL, Fedora, Rocky, Alma).
public struct YumDnfStrategy: PackageManagementStrategy {
    
    /// Whether to prefer dnf over yum (dnf is the successor).
    private let preferDnf: Bool
    private let sshService: any SSHServiceProtocol
    
    /// The package manager command to use.
    private var cmd: String { preferDnf ? "dnf" : "yum" }
    
    public init(preferDnf: Bool = true, sshService: any SSHServiceProtocol = SSHBridge.shared) {
        self.preferDnf = preferDnf
        self.sshService = sshService
    }
    
    public func install(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo LC_ALL=C \(cmd) install -y \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to install \(package): \(result.stderr)")
        }
    }
    
    public func remove(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo LC_ALL=C \(cmd) remove -y \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to remove \(package): \(result.stderr)")
        }
    }
    
    public func purge(_ package: String, serverId: String) async throws {
        // YUM/DNF don't have purge; remove is equivalent
        try await remove(package, serverId: serverId)
    }
    
    public func isInstalled(_ package: String, serverId: String) async throws -> Bool {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "rpm -q \(safePkg) 2>/dev/null",
            serverId: serverId
        )
        return result.exitCode == 0
    }
    
    public func updatePackageLists(serverId: String) async throws {
        let result = try await sshService.execute(
            "sudo LC_ALL=C \(cmd) check-update -q 2>/dev/null; true",
            serverId: serverId
        )
        // check-update returns 100 when there are updates available, 0 if none
        // Both are acceptable
    }
    
    public func upgradeAll(serverId: String) async throws {
        let result = try await sshService.execute(
            "sudo LC_ALL=C \(cmd) upgrade -y",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to upgrade packages: \(result.stderr)")
        }
    }
}

// MARK: - APK Strategy

/// Package management using APK (Alpine Linux).
public struct ApkStrategy: PackageManagementStrategy {
    
    private let sshService: any SSHServiceProtocol
    
    public init(sshService: any SSHServiceProtocol = SSHBridge.shared) {
        self.sshService = sshService
    }
    
    public func install(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo apk add \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to install \(package): \(result.stderr)")
        }
    }
    
    public func remove(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo apk del \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to remove \(package): \(result.stderr)")
        }
    }
    
    public func purge(_ package: String, serverId: String) async throws {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "sudo apk del --purge \(safePkg)",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to purge \(package): \(result.stderr)")
        }
    }
    
    public func isInstalled(_ package: String, serverId: String) async throws -> Bool {
        let safePkg = ShellSanitizer.sanitizeIdentifier(package)
        let result = try await sshService.execute(
            "apk info -e \(safePkg) 2>/dev/null",
            serverId: serverId
        )
        return result.exitCode == 0 && !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public func updatePackageLists(serverId: String) async throws {
        let result = try await sshService.execute(
            "sudo apk update -q",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to update package lists: \(result.stderr)")
        }
    }
    
    public func upgradeAll(serverId: String) async throws {
        let result = try await sshService.execute(
            "sudo apk upgrade",
            serverId: serverId
        )
        guard result.exitCode == 0 else {
            throw AdapterError.commandFailed(reason: "Failed to upgrade packages: \(result.stderr)")
        }
    }
}

// MARK: - Strategy Factory

/// Creates the appropriate PackageManagementStrategy based on server profile.
public enum PackageStrategyFactory {
    
    /// Returns the correct strategy for the given server's package manager.
    public static func strategy(
        for profile: ServerProfile,
        sshService: any SSHServiceProtocol = SSHBridge.shared
    ) -> any PackageManagementStrategy {
        switch profile.packageManager {
        case .apt:
            return AptStrategy(sshService: sshService)
        case .dnf:
            return YumDnfStrategy(preferDnf: true, sshService: sshService)
        case .yum:
            return YumDnfStrategy(preferDnf: false, sshService: sshService)
        case .apk:
            return ApkStrategy(sshService: sshService)
        case .pacman, .zypper, .unknown:
            // Default to APT for unknown (most common)
            CoreLogger.shared.warning(
                "Unknown package manager '\(profile.packageManager.rawValue)', defaulting to apt",
                module: "PackageStrategy"
            )
            return AptStrategy(sshService: sshService)
        }
    }
}
