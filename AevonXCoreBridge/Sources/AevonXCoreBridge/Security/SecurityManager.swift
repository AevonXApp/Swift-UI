//
//  SecurityManager.swift
//  AevonXCoreBridge
//
//  Go-backed SecurityManager — drop-in replacement for AevonXCore's SecurityManager.
//  Uses SSHBridge.shared.executeAsyncJSON() + SSHResult.parse() for all operations.
//

import Foundation

// MARK: - Security Manager

public actor SecurityManager {
    
    public static let shared = SecurityManager()
    
    private init() {}
    
    // MARK: - Dynamic Path Discovery
    
    /// Resolves auth log path: /var/log/auth.log (Debian) or journalctl (RHEL/other)
    public func authLogPath(serverId: String) async -> String {
        let probe = "test -f /var/log/auth.log && echo '/var/log/auth.log' || (test -f /var/log/secure && echo '/var/log/secure' || echo 'journalctl')"
        let path = await run(probe, serverId: serverId)
        return path.isEmpty ? "journalctl" : path
    }
    
    /// Resolves SSH config directory
    public func sshConfigPath(serverId: String) async -> String {
        let probe = "test -f /etc/ssh/sshd_config && echo '/etc/ssh/sshd_config' || echo ''"
        let path = await run(probe, serverId: serverId)
        return path.isEmpty ? "/etc/ssh/sshd_config" : path
    }
    
    /// Resolves fail2ban config directory
    public func fail2banConfigPath(serverId: String) async -> String {
        let probe = "test -d /etc/fail2ban && echo '/etc/fail2ban' || echo ''"
        let path = await run(probe, serverId: serverId)
        return path.isEmpty ? "/etc/fail2ban" : path
    }
    
    /// Resolves ModSecurity config path
    public func modsecConfigPath(serverId: String) async -> String {
        let probe = "test -f /etc/modsecurity/modsecurity.conf && echo '/etc/modsecurity/modsecurity.conf' || (test -f /etc/httpd/conf.d/mod_security.conf && echo '/etc/httpd/conf.d/mod_security.conf' || echo '')"
        let path = await run(probe, serverId: serverId)
        return path.isEmpty ? "/etc/modsecurity/modsecurity.conf" : path
    }
    
    /// Resolves syslog path
    public func syslogPath(serverId: String) async -> String {
        let probe = "test -f /var/log/syslog && echo '/var/log/syslog' || (test -f /var/log/messages && echo '/var/log/messages' || echo 'journalctl')"
        let path = await run(probe, serverId: serverId)
        return path.isEmpty ? "journalctl" : path
    }
    
    // MARK: - Helpers
    
    /// Execute a command and return trimmed stdout, or empty string on failure
    public func run(_ command: String, serverId: String) async -> String {
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: command)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Execute a command and return stdout lines
    public func runLines(_ command: String, serverId: String) async -> [String] {
        let output = await run(command, serverId: serverId)
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}
