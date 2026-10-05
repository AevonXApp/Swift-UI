//
//  ServerProfile.swift
//  AevonXCoreBridge
//
//  Cached per-server capability model — bridge copy.
//  Stores the detected OS, init system, package manager, and shell
//  so that adapters can generate correct commands for any Linux distribution.
//

import Foundation

// MARK: - Linux Distribution

/// Known Linux distributions.
public enum LinuxDistro: String, Codable, Sendable {
    case ubuntu
    case debian
    case centos
    case rhel
    case fedora
    case alpine
    case archlinux
    case opensuse
    case amazonLinux = "amzn"
    case rocky
    case alma
    case unknown
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .ubuntu:       return "Ubuntu"
        case .debian:       return "Debian"
        case .centos:       return "CentOS"
        case .rhel:         return "Red Hat Enterprise Linux"
        case .fedora:       return "Fedora"
        case .alpine:       return "Alpine Linux"
        case .archlinux:    return "Arch Linux"
        case .opensuse:     return "openSUSE"
        case .amazonLinux:  return "Amazon Linux"
        case .rocky:        return "Rocky Linux"
        case .alma:         return "AlmaLinux"
        case .unknown:      return "Unknown"
        }
    }
    
    /// Whether this distro is Debian-based (uses apt)
    public var isDebianBased: Bool {
        switch self {
        case .ubuntu, .debian: return true
        default: return false
        }
    }
    
    /// Whether this distro is RHEL-based (uses yum/dnf)
    public var isRHELBased: Bool {
        switch self {
        case .centos, .rhel, .fedora, .rocky, .alma, .amazonLinux: return true
        default: return false
        }
    }
}

// MARK: - Init System

/// Known init systems.
public enum InitSystem: String, Codable, Sendable {
    case systemd
    case sysvinit
    case openrc
    case unknown
    
    public var displayName: String {
        switch self {
        case .systemd:  return "systemd"
        case .sysvinit: return "SysV Init"
        case .openrc:   return "OpenRC"
        case .unknown:  return "Unknown"
        }
    }
}

// MARK: - Package Manager

/// Known package managers.
public enum PackageManagerType: String, Codable, Sendable {
    case apt
    case yum
    case dnf
    case apk
    case pacman
    case zypper
    case unknown
    
    public var displayName: String {
        switch self {
        case .apt:      return "APT"
        case .yum:      return "YUM"
        case .dnf:      return "DNF"
        case .apk:      return "APK"
        case .pacman:   return "Pacman"
        case .zypper:   return "Zypper"
        case .unknown:  return "Unknown"
        }
    }
}

// MARK: - Shell Type

/// Known shells.
public enum ShellType: String, Codable, Sendable {
    case bash
    case sh
    case zsh
    case dash
    case ash
    case unknown
}

// MARK: - Server Profile

/// Cached capability profile for a remote server.
public struct ServerProfile: Sendable, Codable {
    
    /// Server identifier
    public let serverId: String
    
    /// Detected Linux distribution
    public let distro: LinuxDistro
    
    /// Distribution version string (e.g., "22.04", "9.3")
    public let distroVersion: String?
    
    /// Distribution codename (e.g., "jammy", "bookworm")
    public let distroCodename: String?
    
    /// Detected init system
    public let initSystem: InitSystem
    
    /// Detected package manager
    public let packageManager: PackageManagerType
    
    /// Detected default shell
    public let shell: ShellType
    
    /// Kernel version string
    public let kernelVersion: String?
    
    /// Machine architecture (e.g., "x86_64", "aarch64")
    public let architecture: String?
    
    /// Timestamp when this profile was detected
    public let detectedAt: Date
    
    public init(
        serverId: String,
        distro: LinuxDistro,
        distroVersion: String? = nil,
        distroCodename: String? = nil,
        initSystem: InitSystem,
        packageManager: PackageManagerType,
        shell: ShellType,
        kernelVersion: String? = nil,
        architecture: String? = nil,
        detectedAt: Date = Date()
    ) {
        self.serverId = serverId
        self.distro = distro
        self.distroVersion = distroVersion
        self.distroCodename = distroCodename
        self.initSystem = initSystem
        self.packageManager = packageManager
        self.shell = shell
        self.kernelVersion = kernelVersion
        self.architecture = architecture
        self.detectedAt = detectedAt
    }
    
    /// Whether this profile is still fresh (less than 24 hours old)
    public var isFresh: Bool {
        return Date().timeIntervalSince(detectedAt) < 86400
    }
    
    // MARK: - Path Resolution
    
    /// Nginx configuration base path based on distro
    public var nginxConfigPath: String {
        switch distro {
        case .centos, .rhel, .fedora, .rocky, .alma, .amazonLinux:
            return "/etc/nginx/conf.d"
        default:
            return "/etc/nginx/sites-available"
        }
    }
    
    /// Nginx enabled sites path
    public var nginxEnabledPath: String {
        switch distro {
        case .centos, .rhel, .fedora, .rocky, .alma, .amazonLinux:
            return "/etc/nginx/conf.d"
        default:
            return "/etc/nginx/sites-enabled"
        }
    }
    
    /// Apache configuration base path
    public var apacheConfigPath: String {
        switch distro {
        case .centos, .rhel, .fedora, .rocky, .alma, .amazonLinux:
            return "/etc/httpd/conf.d"
        default:
            return "/etc/apache2/sites-available"
        }
    }
    
    /// Apache service name
    public var apacheServiceName: String {
        switch distro {
        case .centos, .rhel, .fedora, .rocky, .alma, .amazonLinux:
            return "httpd"
        default:
            return "apache2"
        }
    }
    
    /// MySQL data directory
    public var mysqlDataDir: String {
        return "/var/lib/mysql"
    }
    
    /// Default web root
    public var defaultWebRoot: String {
        return "/var/www"
    }
}
