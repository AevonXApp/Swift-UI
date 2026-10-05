//
//  SecurityManager+Extensions.swift
//  AevonXCoreBridge
//
//  All SecurityManager domain methods — consolidated from AevonXCore extensions.
//  Methods use self.run() / self.runLines() which route through SSHBridge.
//

import Foundation

// MARK: - Integrity

extension SecurityManager {
    
    /// Scan for SUID files
    public func scanSUIDFiles(serverId: String) async -> [String] {
        await runLines(
            "find / -perm -4000 -type f 2>/dev/null | head -30",
            serverId: serverId
        )
    }
    
    /// Scan for world-writable files
    public func scanWorldWritableFiles(serverId: String) async -> [String] {
        await runLines(
            "find / -xdev -perm -o+w -type f 2>/dev/null | head -30",
            serverId: serverId
        )
    }
}

// MARK: - Certificates

extension SecurityManager {
    
    /// Scan SSL certificates from Nginx sites-enabled
    public func scanCertificates(serverId: String) async -> [CertificateInfo] {
        let sitesDir = "/etc/nginx/sites-enabled"
        let lines = await runLines(
            "grep -rh 'ssl_certificate ' \(sitesDir)/ 2>/dev/null | awk '{print $2}' | tr -d ';' | sort -u | head -20",
            serverId: serverId
        )
        
        var certs: [CertificateInfo] = []
        for certPath in lines {
            guard !certPath.isEmpty else { continue }
            let detail = await run(
                "openssl x509 -in '\(certPath)' -noout -subject -enddate -issuer 2>/dev/null | tr '\\n' '|'",
                serverId: serverId
            )
            
            let parts = detail.components(separatedBy: "|")
            var domain = "", expiryStr = "", issuer = ""
            for part in parts {
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.contains("subject=") {
                    domain = trimmed.replacingOccurrences(of: "subject=", with: "")
                        .components(separatedBy: "CN = ").last ?? trimmed
                } else if trimmed.contains("notAfter=") {
                    expiryStr = trimmed.replacingOccurrences(of: "notAfter=", with: "")
                } else if trimmed.contains("issuer=") {
                    issuer = trimmed.replacingOccurrences(of: "issuer=", with: "")
                        .components(separatedBy: "O = ").last ?? trimmed
                }
            }
            
            // Calculate days left
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd HH:mm:ss yyyy z"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let expiryDate = formatter.date(from: expiryStr.trimmingCharacters(in: .whitespacesAndNewlines))
            let daysLeft = expiryDate.map { Calendar.current.dateComponents([.day], from: Date(), to: $0).day ?? 0 } ?? 0
            
            certs.append(CertificateInfo(domain: domain, expiry: expiryStr, daysLeft: daysLeft, issuer: issuer))
        }
        return certs
    }
    
    /// Check TLS version configuration
    public func tlsVersion(serverId: String) async -> String {
        let output = await run(
            "grep -r 'ssl_protocols' /etc/nginx/nginx.conf /etc/nginx/conf.d/ 2>/dev/null | head -1 | awk '{for(i=2;i<=NF;i++) printf $i\" \"}'",
            serverId: serverId
        )
        return output.isEmpty ? "Unknown" : output
    }
}

// MARK: - Malware

extension SecurityManager {
    
    /// Check if ClamAV is installed
    public func clamavInstalled(serverId: String) async -> Bool {
        let output = await run(
            "which clamscan 2>/dev/null && echo 'installed' || echo 'not-installed'",
            serverId: serverId
        )
        return output.contains("installed") && !output.contains("not-installed")
    }
    
    /// Install ClamAV
    public func installClamAV(serverId: String) async -> Bool {
        let output = await run(
            "apt-get install -y clamav clamav-daemon 2>/dev/null || yum install -y clamav clamav-update 2>/dev/null; echo 'DONE'",
            serverId: serverId
        )
        return output.contains("DONE")
    }
    
    /// Run quick scan on common directories
    public func clamavQuickScan(serverId: String) async -> [MalwareScanResult] {
        let output = await run(
            "clamscan -r /tmp /var/tmp --infected --no-summary 2>/dev/null | head -50",
            serverId: serverId
        )
        return parseScanOutput(output)
    }
    
    /// Run full system scan
    public func clamavFullScan(serverId: String) async -> [MalwareScanResult] {
        let output = await run(
            "clamscan -r / --infected --no-summary --exclude-dir='^/sys|^/proc|^/dev' 2>/dev/null | head -100",
            serverId: serverId
        )
        return parseScanOutput(output)
    }
    
    private func parseScanOutput(_ output: String) -> [MalwareScanResult] {
        output.components(separatedBy: "\n")
            .filter { $0.contains("FOUND") }
            .map { line -> MalwareScanResult in
                let parts = line.components(separatedBy: ": ")
                return MalwareScanResult(
                    file: parts.first ?? line,
                    threat: parts.last?.replacingOccurrences(of: " FOUND", with: "") ?? "Unknown"
                )
            }
    }
}

// MARK: - Users

extension SecurityManager {
    
    /// List system users (UID >= 1000 or UID = 0), flagged with sudo status
    public func listSystemUsers(serverId: String) async -> [SystemUser] {
        let usersOutput = await runLines(
            "awk -F: '$3 >= 1000 || $3 == 0 { print $1\"|\"$3\"|\"$7\"|\"$6 }' /etc/passwd 2>/dev/null",
            serverId: serverId
        )
        
        let sudoOutput = await runLines(
            "grep -E '^[^#].*ALL' /etc/sudoers 2>/dev/null | awk '{print $1}'; getent group sudo wheel 2>/dev/null | awk -F: '{print $4}' | tr ',' '\\n'",
            serverId: serverId
        )
        
        let sudoSet = Set(
            sudoOutput
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != "ALL" && $0 != "%sudo" && $0 != "%wheel" }
        )
        
        return usersOutput.compactMap { line -> SystemUser? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 4 else { return nil }
            return SystemUser(
                name: parts[0],
                uid: parts[1],
                shell: parts[2],
                home: parts[3],
                hasSudo: sudoSet.contains(parts[0])
            )
        }
    }
    
    /// List usernames with sudo privileges
    public func listSudoUsers(serverId: String) async -> [String] {
        let output = await runLines(
            "grep -E '^[^#].*ALL' /etc/sudoers 2>/dev/null | awk '{print $1}'; getent group sudo wheel 2>/dev/null | awk -F: '{print $4}' | tr ',' '\\n'",
            serverId: serverId
        )
        return Array(Set(
            output
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != "ALL" && $0 != "%sudo" && $0 != "%wheel" }
        ))
    }
}

// MARK: - Network

extension SecurityManager {
    
    /// Scan open ports
    public func openPorts(serverId: String) async -> [OpenPort] {
        let cmd = """
        ss -tlnp 2>/dev/null | awk 'NR>1 { split($4,a,":"); port=a[length(a)]; proc=$6; gsub(/.*users:\\(\\("|".*/, "", proc); print "tcp|"port"|"proc }';
        ss -ulnp 2>/dev/null | awk 'NR>1 { split($4,a,":"); port=a[length(a)]; proc=$6; gsub(/.*users:\\(\\("|".*/, "", proc); print "udp|"port"|"proc }'
        """
        
        let lines = await runLines(cmd, serverId: serverId)
        return lines.compactMap { line -> OpenPort? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else { return nil }
            return OpenPort(port: parts[1], proto: parts[0], service: parts[2])
        }
    }
    
    /// Get active connections
    public func activeConnections(serverId: String) async -> (total: Int, connections: [NetworkConnection]) {
        let lines = await runLines(
            "ss -tn state established 2>/dev/null | awk 'NR>1 {split($5,a,\":\"); print a[1]}' | sort | uniq -c | sort -rn | head -10",
            serverId: serverId
        )
        
        var total = 0
        let connections = lines.compactMap { line -> NetworkConnection? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2, let count = Int(parts[0]) else { return nil }
            total += count
            return NetworkConnection(ip: parts[1], count: count)
        }
        return (total, connections)
    }
}

// MARK: - Logs

extension SecurityManager {
    
    /// Read auth log entries
    public func authLog(lines: Int, serverId: String) async -> [String] {
        let safeLines = min(max(lines, 10), 500)
        let logPath = await authLogPath(serverId: serverId)
        
        let cmd: String
        if logPath == "journalctl" {
            cmd = "journalctl -u sshd --no-pager -n \(safeLines) 2>/dev/null || echo ''"
        } else {
            cmd = "tail -\(safeLines) '\(logPath)' 2>/dev/null || echo ''"
        }
        return await runLines(cmd, serverId: serverId)
    }
    
    /// Read sudo log entries
    public func sudoLog(lines: Int, serverId: String) async -> [String] {
        let safeLines = min(max(lines, 10), 500)
        let logPath = await authLogPath(serverId: serverId)
        
        let cmd: String
        if logPath == "journalctl" {
            cmd = "journalctl -u sudo --no-pager -n \(safeLines) 2>/dev/null || echo ''"
        } else {
            cmd = "grep 'sudo' '\(logPath)' 2>/dev/null | tail -\(safeLines) || echo ''"
        }
        return await runLines(cmd, serverId: serverId)
    }
    
    /// Read system log entries
    public func sysLog(lines: Int, serverId: String) async -> [String] {
        let safeLines = min(max(lines, 10), 500)
        let logPath = await syslogPath(serverId: serverId)
        
        let cmd: String
        if logPath == "journalctl" {
            cmd = "journalctl --no-pager -n \(safeLines) 2>/dev/null || echo ''"
        } else {
            cmd = "tail -\(safeLines) '\(logPath)' 2>/dev/null || echo ''"
        }
        return await runLines(cmd, serverId: serverId)
    }
}

// MARK: - Firewall

extension SecurityManager {
    
    /// Ensure UFW is installed and active — auto-installs if missing
    private func ensureUFW(serverId: String) async -> Bool {
        let check = await run("command -v ufw 2>/dev/null && echo 'EXISTS' || echo 'MISSING'", serverId: serverId)
        if check.contains("MISSING") {
            let install = await run("""
            if command -v apt-get >/dev/null 2>&1; then
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ufw 2>&1 && echo 'INSTALLED'
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y ufw 2>&1 && echo 'INSTALLED'
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y ufw 2>&1 && echo 'INSTALLED'
            else
                echo 'NO_PKG_MANAGER'
            fi
            """, serverId: serverId)
            guard install.contains("INSTALLED") else { return false }
        }
        // Ensure UFW is enabled
        let status = await run("sudo ufw status 2>/dev/null | head -1", serverId: serverId)
        if !status.contains("active") {
            _ = await run("echo 'y' | sudo ufw enable 2>&1", serverId: serverId)
        }
        return true
    }

    /// Check if firewall is active
    public func firewallStatus(serverId: String) async -> Bool {
        let output = await run("sudo ufw status 2>/dev/null | head -1 || iptables -L -n 2>/dev/null | head -1", serverId: serverId)
        return output.contains("active") || output.contains("Chain")
    }

    /// Enable firewall
    public func enableFirewall(serverId: String) async -> Bool {
        guard await ensureUFW(serverId: serverId) else { return false }
        let output = await run("echo 'y' | sudo ufw enable 2>&1 && echo 'OK' || echo 'FAILED'", serverId: serverId)
        return output.contains("OK")
    }

    /// Disable firewall
    public func disableFirewall(serverId: String) async -> Bool {
        let output = await run("sudo ufw disable 2>&1 && echo 'OK' || echo 'FAILED'", serverId: serverId)
        return output.contains("OK")
    }
    
    /// List firewall rules — parses `ufw status` output
    public func listFirewallRules(serverId: String) async -> [SecurityFirewallRule] {
        let output = await run("sudo ufw status 2>/dev/null", serverId: serverId)
        // UFW status output format:
        // To                         Action      From
        // --                         ------      ----
        // 22/tcp                     ALLOW       Anywhere
        // 443                        DENY        192.168.1.0/24
        // 22/tcp (v6)                ALLOW       Anywhere (v6)
        return output.components(separatedBy: "\n").compactMap { line -> SecurityFirewallRule? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Skip header, separator, status lines, and v6 duplicates
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("Status:"),
                  !trimmed.hasPrefix("To "),
                  !trimmed.hasPrefix("--"),
                  !trimmed.contains("(v6)"),
                  trimmed.contains("ALLOW") || trimmed.contains("DENY") || trimmed.contains("REJECT")
            else { return nil }

            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 3 else { return nil }
            // parts[0] = "22/tcp" or "443", parts[1] = "ALLOW"/"DENY", parts[2..] = source
            let portProto = parts[0].components(separatedBy: "/")
            let port = portProto[0]
            let proto = portProto.count > 1 ? portProto[1] : "tcp"
            let action = parts[1]
            // Source is everything after action (skipping "IN" if present)
            let sourceStart = parts[2].uppercased() == "IN" ? 3 : 2
            let source = sourceStart < parts.count ? parts[sourceStart...].joined(separator: " ") : "Anywhere"

            return SecurityFirewallRule(
                proto: proto,
                port: port,
                target: action,
                chain: "INPUT",
                source: source
            )
        }
    }
    
    /// Add firewall rule — returns (success, output) for error reporting
    public func addFirewallRule(proto: String, port: String, strategy: String, direction: String, sourceIP: String, serverId: String) async -> (Bool, String) {
        guard await ensureUFW(serverId: serverId) else {
            return (false, "Failed to install or enable UFW on server")
        }
        let cleanPort = port.filter { $0.isASCII && $0.isNumber }
        guard !cleanPort.isEmpty else { return (false, "Invalid port number") }
        let cleanProto = proto.lowercased() == "udp" ? "udp" : "tcp"
        let stratLower = strategy.lowercased()
        let action = (stratLower == "deny" || stratLower == "drop") ? "deny" : "allow"
        let hasSource = !sourceIP.isEmpty && sourceIP != "0.0.0.0/0" && sourceIP != "::/0"
        let cmd: String
        if hasSource {
            cmd = "sudo ufw \(action) from \(ShellSanitizer.quote(sourceIP)) to any port \(cleanPort) proto \(cleanProto) 2>&1 && echo 'OK' || echo 'FAILED'"
        } else {
            cmd = "sudo ufw \(action) \(cleanPort)/\(cleanProto) 2>&1 && echo 'OK' || echo 'FAILED'"
        }
        let output = await run(cmd, serverId: serverId)
        return (output.contains("OK"), output)
    }
    
    /// Delete firewall rule — returns (success, output) for error reporting
    public func deleteFirewallRule(proto: String, port: String, direction: String, serverId: String) async -> (Bool, String) {
        guard await ensureUFW(serverId: serverId) else {
            return (false, "UFW not available")
        }
        let cleanPort = port.filter { $0.isASCII && $0.isNumber }
        guard !cleanPort.isEmpty else { return (false, "Invalid port") }
        let cleanProto = proto.lowercased() == "udp" ? "udp" : "tcp"
        let cmd = "(echo 'y' | sudo ufw delete allow \(cleanPort)/\(cleanProto) 2>&1 || echo 'y' | sudo ufw delete deny \(cleanPort)/\(cleanProto) 2>&1) && echo 'OK' || echo 'FAILED'"
        let output = await run(cmd, serverId: serverId)
        return (output.contains("OK"), output)
    }
    
    /// Toggle ICMP block
    public func icmpBlock(enabled: Bool, serverId: String) async -> Bool {
        let action = enabled ? "-A" : "-D"
        let cmd = "sudo iptables \(action) INPUT -p icmp --icmp-type echo-request -j DROP 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Set firewall enabled/disabled — UFW only, no dangerous iptables fallback
    public func setFirewall(enabled: Bool, serverId: String) async -> Bool {
        guard await ensureUFW(serverId: serverId) else { return false }
        let cmd: String
        if enabled {
            cmd = "echo 'y' | sudo ufw enable 2>&1 && echo 'OK' || echo 'FAILED'"
        } else {
            cmd = "sudo ufw disable 2>&1 && echo 'OK' || echo 'FAILED'"
        }
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Get listening ports (alias for openPorts)
    public func listeningPorts(serverId: String) async -> [OpenPort] {
        await openPorts(serverId: serverId)
    }
    
    /// Set ICMP block (alias for icmpBlock)
    public func setICMPBlock(enabled: Bool, serverId: String) async -> Bool {
        await icmpBlock(enabled: enabled, serverId: serverId)
    }
}

// MARK: - BruteForce (Fail2ban)

extension SecurityManager {
    
    /// Check fail2ban status
    public func fail2banStatus(serverId: String) async -> Bool {
        let output = await run("systemctl is-active fail2ban 2>/dev/null", serverId: serverId)
        return output == "active"
    }
    
    /// Install fail2ban
    public func installFail2ban(serverId: String) async -> Bool {
        let output = await run(
            "apt-get install -y fail2ban 2>/dev/null || yum install -y fail2ban 2>/dev/null; systemctl enable fail2ban && systemctl start fail2ban && echo 'OK' || echo 'FAILED'",
            serverId: serverId
        )
        return output.contains("OK")
    }
    
    /// Get banned IPs
    public func fail2banBannedIPs(serverId: String) async -> [String] {
        await runLines(
            "fail2ban-client status sshd 2>/dev/null | grep 'Banned IP' | sed 's/.*Banned IP list://' | tr ' ' '\\n' | grep -v '^$'",
            serverId: serverId
        )
    }
    
    /// Get banned count
    public func fail2banBannedCount(serverId: String) async -> Int {
        let output = await run(
            "fail2ban-client status sshd 2>/dev/null | grep 'Currently banned' | awk '{print $NF}'",
            serverId: serverId
        )
        return Int(output) ?? 0
    }
    
    /// List jails
    public func fail2banJailList(serverId: String) async -> [String] {
        let output = await run(
            "fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*Jail list://' | tr ',' '\\n' | xargs",
            serverId: serverId
        )
        return output.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }
    
    /// Unban IP
    public func fail2banUnban(ip: String, jail: String, serverId: String) async -> Bool {
        let safeIP = ShellSanitizer.quote(ip)
        let safeJail = ShellSanitizer.quote(jail)
        let cmd = "fail2ban-client set \(safeJail) unbanip \(safeIP) 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Ban IP
    public func fail2banBanIP(ip: String, jail: String, serverId: String) async -> Bool {
        let safeIP = ShellSanitizer.quote(ip)
        let safeJail = ShellSanitizer.quote(jail)
        let cmd = "fail2ban-client set \(safeJail) banip \(safeIP) 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Unban all
    public func fail2banUnbanAll(jail: String = "sshd", serverId: String) async -> Bool {
        let output = await run("fail2ban-client unban --all 2>&1 && echo 'OK' || echo 'FAILED'", serverId: serverId)
        return output.contains("OK")
    }
    
    /// Set max retry
    public func fail2banSetMaxRetry(count: Int, serverId: String) async -> Bool {
        let configDir = await fail2banConfigPath(serverId: serverId)
        let cmd = """
        cat > '\(configDir)/jail.local' 2>/dev/null << 'EOF'
        [DEFAULT]
        maxretry = \(count)
        EOF
        systemctl restart fail2ban 2>&1 && echo 'OK' || echo 'FAILED'
        """
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Set ban time
    public func fail2banSetBanTime(seconds: Int, serverId: String) async -> Bool {
        let configDir = await fail2banConfigPath(serverId: serverId)
        let cmd = """
        echo '[DEFAULT]' > '\(configDir)/jail.local';
        echo 'bantime = \(seconds)' >> '\(configDir)/jail.local';
        systemctl restart fail2ban 2>&1 && echo 'OK' || echo 'FAILED'
        """
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Get jail status
    public func fail2banJailStatus(jail: String, serverId: String) async -> String {
        let safeJail = ShellSanitizer.quote(jail)
        return await run("fail2ban-client status \(safeJail) 2>/dev/null", serverId: serverId)
    }
    
    /// Get whitelist
    public func fail2banWhitelist(serverId: String) async -> [String] {
        let configDir = await fail2banConfigPath(serverId: serverId)
        let output = await run(
            "grep -h 'ignoreip' '\(configDir)/jail.conf' '\(configDir)/jail.local' 2>/dev/null | grep -v '#' | awk -F'=' '{print $2}' | tr ' ' '\\n' | grep -v '^$'",
            serverId: serverId
        )
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    /// Add to whitelist
    public func fail2banAddToWhitelist(ip: String, serverId: String) async -> Bool {
        let configDir = await fail2banConfigPath(serverId: serverId)
        let safeIP = ShellSanitizer.quote(ip)
        let cmd = """
        if grep -q 'ignoreip' '\(configDir)/jail.local' 2>/dev/null; then
            sed -i "s/ignoreip = /ignoreip = \(safeIP) /" '\(configDir)/jail.local'
        else
            echo "[DEFAULT]" >> '\(configDir)/jail.local'
            echo "ignoreip = 127.0.0.1/8 ::1 \(safeIP)" >> '\(configDir)/jail.local'
        fi
        systemctl restart fail2ban 2>&1 && echo 'OK' || echo 'FAILED'
        """
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Remove from whitelist
    public func fail2banRemoveFromWhitelist(ip: String, serverId: String) async -> Bool {
        let configDir = await fail2banConfigPath(serverId: serverId)
        let safeIP = ShellSanitizer.quote(ip)
        let cmd = "sed -i 's/ *\(safeIP)//' '\(configDir)/jail.local' 2>&1 && systemctl restart fail2ban 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
}

// MARK: - SSH

extension SecurityManager {
    
    /// Check SSH service status
    public func sshStatus(serverId: String) async -> Bool {
        let output = await run(
            "if systemctl is-active sshd >/dev/null 2>&1 || systemctl is-active ssh >/dev/null 2>&1; then echo active; else echo inactive; fi",
            serverId: serverId
        )
        return output.contains("active") && !output.contains("inactive")
    }
    
    /// Read SSH configuration.
    ///
    /// Port resolution uses the three-probe detection from `KeygenBridge`
    /// (`sshd -T` → listening socket → grep on sshd_config) so the displayed
    /// value reflects what sshd is actually serving — not whatever happens
    /// to be the first uncommented line in `sshd_config`.
    /// PermitRootLogin / PasswordAuthentication / PubkeyAuthentication still
    /// come from a directed `grep` since those directives are unambiguous.
    public func sshConfig(serverId: String) async -> SSHConfigData {
        let configPath = await sshConfigPath(serverId: serverId)

        // Run port-detection and the rest of the config grep in parallel —
        // they touch the same SSH session but the bridge serialises them
        // and the round-trip cost is dominated by network latency.
        async let portTask = detectSSHPort(serverId: serverId, configPath: configPath)
        async let configTask = run(
            "grep -E '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)' '\(configPath)' 2>/dev/null",
            serverId: serverId
        )
        let detection = await portTask
        let configOutput = await configTask

        var rootLogin = "yes", passwordAuth = "yes", pubkeyAuth = "yes"
        for line in configOutput.components(separatedBy: "\n") {
            let parts = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            guard parts.count >= 2 else { continue }
            switch parts[0] {
            case "PermitRootLogin": rootLogin = parts[1]
            case "PasswordAuthentication": passwordAuth = parts[1]
            case "PubkeyAuthentication": pubkeyAuth = parts[1]
            default: break
            }
        }
        return SSHConfigData(
            port: String(detection.port),
            permitRootLogin: rootLogin,
            passwordAuth: passwordAuth,
            pubkeyAuth: pubkeyAuth
        )
    }

    /// Robust SSH port detection. Falls back to the registered server port,
    /// then the SSH default of 22, if every probe is silent.
    private func detectSSHPort(serverId: String, configPath: String) async -> KeygenPortDetection {
        let cmd = KeygenBridge.shared.sshPortDetectCmd(configPath: configPath)
        let output = await run(cmd, serverId: serverId)
        return KeygenBridge.shared.parseSSHPort(output: output)
    }
    
    /// Set SSH port — opens new port in firewall, writes config, then schedules a delayed restart
    /// so the response reaches the client before the connection drops.
    public func setSSHPort(port: String, serverId: String) async -> Bool {
        // Validate port range
        guard let portNum = Int(port), portNum >= 1, portNum <= 65535 else { return false }

        let configPath = await sshConfigPath(serverId: serverId)
        let safePort = String(portNum)

        // Step 1: Open the new port in UFW firewall FIRST (if UFW is active)
        let openPortCmd = """
        if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q 'Status: active'; then
            sudo ufw allow \(safePort)/tcp comment 'SSH' 2>&1 && echo 'FW_OK'
        else
            echo 'FW_OK'
        fi
        """
        let fwResult = await run(openPortCmd, serverId: serverId)
        guard fwResult.contains("FW_OK") else { return false }

        // Step 2: Update sshd_config (add Port line if not present, or replace existing)
        let updateCmd = """
        if grep -qE '^#?Port ' '\(configPath)'; then
            sudo sed -i 's/^#\\?Port .*/Port \(safePort)/' '\(configPath)'
        else
            echo 'Port \(safePort)' | sudo tee -a '\(configPath)' >/dev/null
        fi && echo 'CONFIG_OK'
        """
        let configResult = await run(updateCmd, serverId: serverId)
        guard configResult.contains("CONFIG_OK") else { return false }

        // Step 3: Schedule a delayed restart (2 sec) so this response gets back first
        let restartCmd = "nohup bash -c 'sleep 2 && sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh 2>/dev/null' &>/dev/null &"
        _ = await run(restartCmd, serverId: serverId)

        return true
    }
    
    /// Toggle password authentication
    public func setSSHPasswordAuth(enabled: Bool, serverId: String) async -> Bool {
        let configPath = await sshConfigPath(serverId: serverId)
        let val = enabled ? "yes" : "no"
        let cmd = "sed -i 's/^#\\?PasswordAuthentication .*/PasswordAuthentication \(val)/' '\(configPath)' && systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; echo 'OK'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Toggle pubkey authentication
    public func setSSHKeyAuth(enabled: Bool, serverId: String) async -> Bool {
        let configPath = await sshConfigPath(serverId: serverId)
        let val = enabled ? "yes" : "no"
        let cmd = "sed -i 's/^#\\?PubkeyAuthentication .*/PubkeyAuthentication \(val)/' '\(configPath)' && systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; echo 'OK'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Set root login mode
    public func setSSHRootLogin(mode: String, serverId: String) async -> Bool {
        let configPath = await sshConfigPath(serverId: serverId)
        let safeMode = ShellSanitizer.quote(mode)
        let cmd = "sed -i 's/^#\\?PermitRootLogin .*/PermitRootLogin '\(safeMode)'/' '\(configPath)' && systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; echo 'OK'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Get SSH login logs
    public func sshLoginLogs(count: Int, serverId: String) async -> [String] {
        let safeCount = min(max(count, 10), 500)
        let authLog = await authLogPath(serverId: serverId)
        let cmd: String
        if authLog == "journalctl" {
            cmd = "journalctl -u sshd --no-pager -n \(safeCount) 2>/dev/null | grep -E '(Accepted|Failed)' || echo 'no-logs'"
        } else {
            cmd = "grep 'sshd' '\(authLog)' 2>/dev/null | grep -E '(Accepted|Failed)' | tail -\(safeCount) || echo 'no-logs'"
        }
        return await runLines(cmd, serverId: serverId)
    }
    
    /// Get SSH login statistics
    public func sshLoginStats(serverId: String) async -> (success: Int, failed: Int, todayFailed: Int) {
        let authLog = await authLogPath(serverId: serverId)
        let cmd: String
        if authLog == "journalctl" {
            cmd = """
            echo "success:$(journalctl -u sshd --no-pager 2>/dev/null | grep -c 'Accepted' || echo 0)";
            echo "failed:$(journalctl -u sshd --no-pager 2>/dev/null | grep -c 'Failed' || echo 0)";
            echo "today_failed:0"
            """
        } else {
            cmd = """
            echo "success:$(grep 'sshd' '\(authLog)' 2>/dev/null | grep -c 'Accepted' || echo 0)";
            echo "failed:$(grep 'sshd' '\(authLog)' 2>/dev/null | grep -c 'Failed' || echo 0)";
            echo "today_failed:$(grep 'sshd' '\(authLog)' 2>/dev/null | grep 'Failed' | grep "$(date '+%b %e')" | wc -l || echo 0)"
            """
        }
        
        let lines = await runLines(cmd, serverId: serverId)
        var success = 0, failed = 0, todayFailed = 0
        for line in lines {
            if line.starts(with: "success:") { success = Int(line.replacingOccurrences(of: "success:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0 }
            if line.starts(with: "failed:") { failed = Int(line.replacingOccurrences(of: "failed:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0 }
            if line.starts(with: "today_failed:") { todayFailed = Int(line.replacingOccurrences(of: "today_failed:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0 }
        }
        return (success, failed, todayFailed)
    }
    
    /// Generate SSH ed25519 key pair
    public func generateSSHKey(serverId: String) async -> String? {
        let output = await run(
            "ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N '' -q 2>&1 && cat /root/.ssh/id_ed25519.pub || echo 'FAILED'",
            serverId: serverId
        )
        return output.contains("FAILED") ? nil : output
    }
    
    /// Read SSH public key
    public func readSSHPublicKey(serverId: String) async -> String? {
        let output = await run(
            "cat /root/.ssh/id_ed25519.pub 2>/dev/null || cat /root/.ssh/id_rsa.pub 2>/dev/null || echo 'no-key'",
            serverId: serverId
        )
        return output == "no-key" ? nil : output
    }
    
    /// Read authorized_keys
    public func readAuthorizedKeys(serverId: String) async -> [String] {
        let output = await run("cat /root/.ssh/authorized_keys 2>/dev/null || echo ''", serverId: serverId)
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    /// Add a public key to authorized_keys
    public func addAuthorizedKey(key: String, serverId: String) async -> Bool {
        let safeKey = ShellSanitizer.quote(key.trimmingCharacters(in: .whitespacesAndNewlines))
        let cmd = """
        mkdir -p /root/.ssh && chmod 700 /root/.ssh;
        echo \(safeKey) >> /root/.ssh/authorized_keys;
        chmod 600 /root/.ssh/authorized_keys && echo 'OK' || echo 'FAILED'
        """
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Remove a key from authorized_keys by line index (0-based)
    public func removeAuthorizedKey(index: Int, serverId: String) async -> Bool {
        let lineNum = index + 1
        let cmd = "sed -i '\(lineNum)d' /root/.ssh/authorized_keys 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
    
    /// Get active SSH sessions with PIDs for targeted kill.
    /// Returns: user, tty, ip, since, pid
    public func activeSessions(serverId: String) async -> [(user: String, ip: String, since: String, pid: String, tty: String)] {
        // `who -u` shows: user tty date time idle pid (host)
        let output = await run("who -u 2>/dev/null | grep -v 'LOGIN' || echo ''", serverId: serverId)
        var sessions: [(user: String, ip: String, since: String, pid: String, tty: String)] = []
        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            // who -u format: user tty date time idle pid (ip)
            guard parts.count >= 6 else { continue }
            let user = parts[0]
            let tty = parts[1]
            let since = "\(parts[2]) \(parts[3])"
            // idle is at index 4, pid at index 5
            let pid = parts[5]
            // IP is usually in parentheses at the end
            let ip = parts.last?.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "") ?? "local"
            sessions.append((user: user, ip: ip, since: since, pid: pid, tty: tty))
        }
        return sessions
    }

    /// Get the current SSH connection's IP as seen by the server
    public func currentSessionIP(serverId: String) async -> String {
        // SSH_CONNECTION env var: "client_ip client_port server_ip server_port"
        let output = await run("echo $SSH_CONNECTION | awk '{print $1}'", serverId: serverId)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Kill a specific session by PID (not all sessions for a user)
    public func killSessionByPID(pid: String, serverId: String) async -> Bool {
        guard let pidNum = Int(pid), pidNum > 1 else { return false }
        let cmd = "kill \(pidNum) 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }

    /// Legacy kill by user — kept for backwards compatibility but NOT recommended
    public func killSession(user: String, serverId: String) async -> Bool {
        let safeUser = ShellSanitizer.quote(user)
        let cmd = "pkill -u \(safeUser) sshd 2>&1 && echo 'OK' || echo 'FAILED'"
        return await run(cmd, serverId: serverId).contains("OK")
    }
}

// MARK: - WAF

extension SecurityManager {
    
    /// Check WAF status
    public func wafStatus(serverId: String) async -> WAFStatus {
        let installed = await run(
            "dpkg -l | grep modsecurity 2>/dev/null || rpm -qa | grep mod_security 2>/dev/null; echo 'CHECK'",
            serverId: serverId
        )
        let configPath = await modsecConfigPath(serverId: serverId)
        let enabled = await run(
            "grep 'SecRuleEngine' '\(configPath)' 2>/dev/null | head -1",
            serverId: serverId
        )
        return WAFStatus(
            installed: installed.contains("modsecurity") || installed.contains("mod_security"),
            enabled: enabled.contains("On")
        )
    }
    
    /// Toggle WAF
    public func toggleWAF(enabled: Bool, serverId: String) async -> Bool {
        let configPath = await modsecConfigPath(serverId: serverId)
        let val = enabled ? "On" : "Off"
        let opposite = enabled ? "Off" : "On"
        let output = await run(
            "sed -i 's/SecRuleEngine \(opposite)/SecRuleEngine \(val)/' '\(configPath)' 2>/dev/null && systemctl reload nginx 2>/dev/null && echo 'OK' || echo 'FAILED'",
            serverId: serverId
        )
        return output.contains("OK")
    }
    
    /// Install ModSecurity
    public func installWAF(serverId: String) async -> Bool {
        let output = await run(
            "apt-get install -y libapache2-mod-security2 modsecurity-crs 2>&1 || apt-get install -y libnginx-mod-security 2>&1; echo 'DONE'",
            serverId: serverId
        )
        return output.contains("DONE")
    }
    
    /// Read ModSecurity audit log entries
    public func wafAuditLog(lines: Int, serverId: String) async -> [String] {
        let safeLines = min(max(lines, 10), 500)
        let cmd = """
        if [ -f /var/log/modsec_audit.log ]; then
            tail -\(safeLines) /var/log/modsec_audit.log 2>/dev/null
        elif [ -f /var/log/apache2/modsec_audit.log ]; then
            tail -\(safeLines) /var/log/apache2/modsec_audit.log 2>/dev/null
        elif [ -f /var/log/httpd/modsec_audit.log ]; then
            tail -\(safeLines) /var/log/httpd/modsec_audit.log 2>/dev/null
        else
            echo ''
        fi
        """
        return await runLines(cmd, serverId: serverId)
    }
    
    /// Count active ModSecurity rules
    public func wafRuleCount(serverId: String) async -> Int {
        let output = await run(
            "find /usr/share/modsecurity-crs/rules/ /etc/modsecurity/rules/ -name '*.conf' 2>/dev/null | xargs grep -c 'SecRule' 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'",
            serverId: serverId
        )
        return Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
}

// MARK: - Hardening

extension SecurityManager {
    
    /// Check system hardening settings and return a security score
    public func hardeningCheck(serverId: String) async -> SecurityScore {
        let configPath = await sshConfigPath(serverId: serverId)
        
        let cmd = """
        echo "ASLR:$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo N/A)";
        echo "SYN_COOKIES:$(cat /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null || echo N/A)";
        echo "SOURCE_ROUTE:$(cat /proc/sys/net/ipv4/conf/all/accept_source_route 2>/dev/null || echo N/A)";
        echo "CORE_DUMP:$(cat /proc/sys/fs/suid_dumpable 2>/dev/null || echo N/A)";
        echo "ROOT_LOGIN:$(grep '^PermitRootLogin' '\(configPath)' 2>/dev/null | awk '{print $2}' || echo N/A)";
        echo "SSH_PORT:$(grep '^Port' '\(configPath)' 2>/dev/null | awk '{print $2}' || echo 22)";
        echo "PASSWORD_AUTH:$(grep '^PasswordAuthentication' '\(configPath)' 2>/dev/null | awk '{print $2}' || echo N/A)";
        echo "IPV6:$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo N/A)";
        echo "FAIL2BAN:$(systemctl is-active fail2ban 2>/dev/null || echo inactive)"
        """
        
        let output = await run(cmd, serverId: serverId)
        
        var score: Double = 20
        let fwActive = await firewallStatus(serverId: serverId)
        let f2bActive = await fail2banStatus(serverId: serverId)
        let config = await sshConfig(serverId: serverId)
        
        if fwActive { score += 15 }
        if f2bActive { score += 15 }
        
        let rootDisabled = config.permitRootLogin == "no" || config.permitRootLogin == "prohibit-password"
        let keyAuth = config.pubkeyAuth == "yes"
        let sshIsSecure = rootDisabled && keyAuth
        
        if rootDisabled { score += 10 }
        if keyAuth { score += 10 }
        if output.contains("ASLR:2") { score += 5 }
        if output.contains("SYN_COOKIES:1") { score += 5 }
        if output.contains("SOURCE_ROUTE:0") { score += 5 }
        if output.contains("FAIL2BAN:active") { score += 5 }
        
        let rules = await listFirewallRules(serverId: serverId)
        if rules.count > 3 { score += 10 }
        
        let banned = await fail2banBannedIPs(serverId: serverId)
        let stats = await sshLoginStats(serverId: serverId)
        
        var hardeningData: [String: String] = [:]
        for line in output.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                hardeningData[parts[0]] = parts.dropFirst().joined(separator: ":")
            }
        }
        
        return SecurityScore(
            value: min(score, 100),
            firewallActive: fwActive,
            fail2banActive: f2bActive,
            sshSecure: sshIsSecure,
            activeRules: rules.count,
            bannedIPs: banned.count,
            failedLogins: stats.failed,
            hardeningData: hardeningData
        )
    }
}

// MARK: - AI

extension SecurityManager {
    
    /// Gather all security data needed for AI analysis
    public func gatherSecurityData(serverId: String) async -> AISecurityData {
        let authLog = await authLogPath(serverId: serverId)
        let stats = await sshLoginStats(serverId: serverId)
        
        let attackerLines: [String]
        if authLog == "journalctl" {
            attackerLines = await runLines(
                "journalctl -u sshd --no-pager 2>/dev/null | grep 'Failed' | grep -oP '\\d+\\.\\d+\\.\\d+\\.\\d+' | sort | uniq -c | sort -rn | head -5",
                serverId: serverId
            )
        } else {
            attackerLines = await runLines(
                "grep 'Failed' '\(authLog)' 2>/dev/null | grep -oP '\\d+\\.\\d+\\.\\d+\\.\\d+' | sort | uniq -c | sort -rn | head -5",
                serverId: serverId
            )
        }
        
        let topAttackers = attackerLines.compactMap { line -> AttackSource? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2, let count = Int(parts[0]) else { return nil }
            return AttackSource(ip: parts[1], count: count)
        }
        
        let score = await hardeningCheck(serverId: serverId)
        let hardeningStr = score.hardeningData.map { "\($0.key):\($0.value)" }.joined(separator: "\n")
        
        let config = await sshConfig(serverId: serverId)
        let configStr = "Port:\(config.port)\nPermitRootLogin:\(config.permitRootLogin)\nPasswordAuth:\(config.passwordAuth)\nPubkeyAuth:\(config.pubkeyAuth)"
        
        return AISecurityData(
            failedLogins: stats.failed,
            acceptedLogins: stats.success,
            topAttackers: topAttackers,
            hardeningData: hardeningStr,
            sshConfig: configStr
        )
    }
    
    /// Get top failed login sources
    public func topFailedLoginIPs(limit: Int, serverId: String) async -> [AttackSource] {
        let authLog = await authLogPath(serverId: serverId)
        let safeLimit = min(max(limit, 1), 50)
        
        let cmd: String
        if authLog == "journalctl" {
            cmd = "journalctl -u sshd --no-pager 2>/dev/null | grep 'Failed' | grep -oP '\\d+\\.\\d+\\.\\d+\\.\\d+' | sort | uniq -c | sort -rn | head -\(safeLimit)"
        } else {
            cmd = "grep 'Failed password' '\(authLog)' 2>/dev/null | grep -oP '\\d+\\.\\d+\\.\\d+\\.\\d+' | sort | uniq -c | sort -rn | head -\(safeLimit)"
        }
        
        let lines = await runLines(cmd, serverId: serverId)
        return lines.compactMap { line -> AttackSource? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2, let count = Int(parts[0]) else { return nil }
            return AttackSource(ip: parts[1], count: count)
        }
    }
}
