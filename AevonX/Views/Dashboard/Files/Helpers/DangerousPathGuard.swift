//
//  DangerousPathGuard.swift
//  AevonX
//
//  Warning system for dangerous path operations
//  Warns before deleting/modifying system-critical directories
//

import SwiftUI

// MARK: - Dangerous Path Guard

struct DangerousPathGuard {
    
    /// Critical system paths that should never be deleted
    private static let criticalPaths: Set<String> = [
        "/", "/root", "/home", "/etc", "/usr", "/bin", "/sbin",
        "/var", "/lib", "/lib64", "/boot", "/dev", "/proc", "/sys",
        "/opt", "/srv", "/tmp", "/run", "/mnt", "/media",
        "/etc/nginx", "/etc/apache2", "/etc/ssh",
        "/var/www", "/var/log", "/var/lib",
        "/usr/bin", "/usr/sbin", "/usr/lib", "/usr/local"
    ]
    
    /// Sensitive config files
    private static let sensitiveFiles: Set<String> = [
        "/etc/passwd", "/etc/shadow", "/etc/group", "/etc/sudoers",
        "/etc/fstab", "/etc/hosts", "/etc/hostname", "/etc/resolv.conf",
        "/etc/ssh/sshd_config", "/etc/nginx/nginx.conf",
        "/root/.ssh/authorized_keys", "/root/.bashrc", "/root/.profile"
    ]
    
    /// Check if a path is dangerous to delete
    static func isDangerousToDelete(_ path: String) -> DangerLevel {
        let normalized = path.hasSuffix("/") ? String(path.dropLast()) : path
        
        if criticalPaths.contains(normalized) {
            return .critical
        }
        
        if sensitiveFiles.contains(normalized) {
            return .high
        }
        
        // Check parent directories
        if normalized.hasPrefix("/etc/") || normalized.hasPrefix("/usr/") ||
           normalized.hasPrefix("/bin/") || normalized.hasPrefix("/sbin/") {
            return .medium
        }
        
        return .safe
    }
    
    /// Check if a path is dangerous to edit
    static func isDangerousToEdit(_ path: String) -> DangerLevel {
        if sensitiveFiles.contains(path) {
            return .high
        }
        
        if path.hasPrefix("/etc/") {
            return .medium
        }
        
        return .safe
    }
    
    enum DangerLevel {
        case safe
        case medium   // Show a subtle warning
        case high     // Show an orange warning
        case critical // Show a red warning, require confirmation
        
        var color: Color {
            switch self {
            case .safe: return .clear
            case .medium: return .axWarning
            case .high: return .orange
            case .critical: return .axError
            }
        }
        
        var message: String {
            switch self {
            case .safe: return ""
            case .medium: return "⚠️ System path — proceed with caution"
            case .high: return "⚠️ Sensitive config file — changes may break the system"
            case .critical: return "🛑 Critical system path — deleting this may crash the server"
            }
        }
        
        var isDangerous: Bool {
            self != .safe
        }
    }
}
