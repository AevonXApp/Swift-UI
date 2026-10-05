//
//  CapabilityDetector.swift
//  AevonXCoreBridge
//
//  Detects server capabilities using a single batched SSH command.
//  Results are parsed into a ServerProfile and cached for the session.
//

import Foundation

// MARK: - Capability Detector

/// Detects OS, init system, package manager, shell, and architecture
/// of a remote server using a single batched SSH command.
///
/// **Usage**:
/// ```swift
/// let detector = CapabilityDetector(sshService: sshService)
/// let profile = try await detector.detect(serverId: "server-1")
/// ```
///
/// **Efficiency**: All detection is done in ONE SSH command call,
/// avoiding the overhead of multiple separate probing commands.
public actor CapabilityDetector {
    
    // MARK: - Properties
    
    private let sshService: any SSHServiceProtocol
    private var cache: [String: ServerProfile] = [:]
    
    // MARK: - Initialization
    
    public init(sshService: any SSHServiceProtocol) {
        self.sshService = sshService
    }
    
    // MARK: - Detection
    
    /// Detect server capabilities and return a cached or fresh ServerProfile.
    ///
    /// - Parameters:
    ///   - serverId: The server identifier
    ///   - forceRefresh: If true, bypass the cache and re-detect
    /// - Returns: A `ServerProfile` containing all detected capabilities
    public func detect(serverId: String, forceRefresh: Bool = false) async throws -> ServerProfile {
        // Check cache first
        if !forceRefresh, let cached = cache[serverId], cached.isFresh {
            return cached
        }
        
        // Run all detection in a single batched SSH command
        let detectionCommand = buildDetectionCommand()
        let result = try await sshService.execute(detectionCommand, serverId: serverId)
        
        guard result.exitCode == 0 || !result.stdout.isEmpty else {
            throw DetectionError.detectionFailed(reason: "Detection command failed: \(result.stderr)")
        }
        
        // Parse the batched output
        let profile = try parseDetectionOutput(result.stdout, serverId: serverId)
        
        // Cache the result
        cache[serverId] = profile
        
        CoreLogger.shared.info(
            "[CapabilityDetector] Detected: \(profile.distro.displayName) \(profile.distroVersion ?? "") " +
            "| Init: \(profile.initSystem.displayName) " +
            "| Pkg: \(profile.packageManager.displayName) " +
            "| Arch: \(profile.architecture ?? "unknown")",
            module: "CapabilityDetector"
        )
        
        return profile
    }
    
    /// Invalidate cached profile for a server.
    public func invalidate(serverId: String) {
        cache.removeValue(forKey: serverId)
    }
    
    /// Get cached profile without running detection.
    public func getCached(serverId: String) -> ServerProfile? {
        return cache[serverId]
    }
    
    // MARK: - Command Building
    
    /// Builds a single batched command that detects all server capabilities.
    /// Each section is delimited by a unique marker for reliable parsing.
    private func buildDetectionCommand() -> String {
        return """
        echo '---DISTRO_START---' && cat /etc/os-release 2>/dev/null | head -10 && echo '---DISTRO_END---' && \
        echo '---INIT_START---' && (command -v systemctl >/dev/null 2>&1 && echo 'systemd' || \
        (command -v rc-service >/dev/null 2>&1 && echo 'openrc' || \
        (test -f /etc/init.d/rc && echo 'sysvinit' || echo 'unknown'))) && echo '---INIT_END---' && \
        echo '---PKG_START---' && (command -v apt-get >/dev/null 2>&1 && echo 'apt' || \
        (command -v dnf >/dev/null 2>&1 && echo 'dnf' || \
        (command -v yum >/dev/null 2>&1 && echo 'yum' || \
        (command -v apk >/dev/null 2>&1 && echo 'apk' || \
        (command -v pacman >/dev/null 2>&1 && echo 'pacman' || \
        (command -v zypper >/dev/null 2>&1 && echo 'zypper' || echo 'unknown')))))) && echo '---PKG_END---' && \
        echo '---SHELL_START---' && basename "$SHELL" 2>/dev/null || echo 'sh' && echo '---SHELL_END---' && \
        echo '---KERNEL_START---' && uname -r 2>/dev/null && echo '---KERNEL_END---' && \
        echo '---ARCH_START---' && uname -m 2>/dev/null && echo '---ARCH_END---'
        """
    }
    
    // MARK: - Parsing
    
    /// Parse the batched detection output into a ServerProfile.
    private func parseDetectionOutput(_ output: String, serverId: String) throws -> ServerProfile {
        let distro = parseDistro(from: extractSection(output, start: "---DISTRO_START---", end: "---DISTRO_END---"))
        let initSystem = parseInitSystem(from: extractSection(output, start: "---INIT_START---", end: "---INIT_END---"))
        let packageManager = parsePackageManager(from: extractSection(output, start: "---PKG_START---", end: "---PKG_END---"))
        let shell = parseShell(from: extractSection(output, start: "---SHELL_START---", end: "---SHELL_END---"))
        let kernelVersion = extractSection(output, start: "---KERNEL_START---", end: "---KERNEL_END---")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let architecture = extractSection(output, start: "---ARCH_START---", end: "---ARCH_END---")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ServerProfile(
            serverId: serverId,
            distro: distro.distro,
            distroVersion: distro.version,
            distroCodename: distro.codename,
            initSystem: initSystem,
            packageManager: packageManager,
            shell: shell,
            kernelVersion: kernelVersion.isEmpty ? nil : kernelVersion,
            architecture: architecture.isEmpty ? nil : architecture
        )
    }
    
    /// Extract a section between start/end markers from the batched output.
    private func extractSection(_ output: String, start: String, end: String) -> String {
        guard let startRange = output.range(of: start),
              let endRange = output.range(of: end) else {
            return ""
        }
        let section = output[startRange.upperBound..<endRange.lowerBound]
        return String(section).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Individual Parsers
    
    /// Parse /etc/os-release content to determine the Linux distribution.
    private func parseDistro(from osRelease: String) -> (distro: LinuxDistro, version: String?, codename: String?) {
        var id = ""
        var versionId: String?
        var versionCodename: String?
        
        for line in osRelease.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            
            switch key {
            case "ID":
                id = value.lowercased()
            case "VERSION_ID":
                versionId = value
            case "VERSION_CODENAME":
                versionCodename = value
            default:
                break
            }
        }
        
        let distro: LinuxDistro
        switch id {
        case "ubuntu":              distro = .ubuntu
        case "debian":              distro = .debian
        case "centos":              distro = .centos
        case "rhel":                distro = .rhel
        case "fedora":              distro = .fedora
        case "alpine":              distro = .alpine
        case "arch", "archlinux":   distro = .archlinux
        case "opensuse", "opensuse-leap", "opensuse-tumbleweed":
            distro = .opensuse
        case "amzn":                distro = .amazonLinux
        case "rocky":               distro = .rocky
        case "almalinux":           distro = .alma
        default:                    distro = .unknown
        }
        
        return (distro, versionId, versionCodename)
    }
    
    /// Parse init system detection output.
    private func parseInitSystem(from output: String) -> InitSystem {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "systemd":  return .systemd
        case "openrc":   return .openrc
        case "sysvinit": return .sysvinit
        default:         return .unknown
        }
    }
    
    /// Parse package manager detection output.
    private func parsePackageManager(from output: String) -> PackageManagerType {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "apt":    return .apt
        case "dnf":    return .dnf
        case "yum":    return .yum
        case "apk":    return .apk
        case "pacman": return .pacman
        case "zypper": return .zypper
        default:       return .unknown
        }
    }
    
    /// Parse shell detection output.
    private func parseShell(from output: String) -> ShellType {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "bash": return .bash
        case "sh":   return .sh
        case "zsh":  return .zsh
        case "dash": return .dash
        case "ash":  return .ash
        default:     return .unknown
        }
    }
}
