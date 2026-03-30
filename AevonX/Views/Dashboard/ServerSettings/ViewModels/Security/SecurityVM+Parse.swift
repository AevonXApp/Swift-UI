//
//  SecurityVM+Parse.swift
//  AevonX
//
//  Parsing logic for SSH security, firewall, and Fail2Ban snapshots.
//

import Foundation

extension SecurityVM {

    // MARK: - SSH Security Parsing

    func parseSSHSecurity(_ sections: [String: String]) {
        parseAuthorizedKeys(sections["AUTHKEYS"] ?? "")
        parseHostKeys(sections["HOSTKEYS"] ?? "")
        parseFailedLogins(sections["FAILEDLOGINS"] ?? "")
        parseRecentLogins(sections["RECENTLOGINS"] ?? "")
        maxAuthTries = (sections["MAXAUTH"] ?? "").trimmingCharacters(in: .whitespaces)
        x11Forwarding = (sections["X11"] ?? "").trimmingCharacters(in: .whitespaces)
        allowedUsers = (sections["ALLOWUSERS"] ?? "").trimmingCharacters(in: .whitespaces)
        calculateSecurityScore()
    }

    private func parseAuthorizedKeys(_ s: String) {
        guard !s.isEmpty else { authorizedKeys = []; return }
        authorizedKeys = s.split(separator: "\n").enumerated().compactMap { idx, line in
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard !str.isEmpty else { return nil }
            let parts = str.split(separator: " ", maxSplits: 2)
            let keyType = parts.count > 0 ? String(parts[0]) : "unknown"
            let fp = parts.count > 1 ? String(parts[1].prefix(20)) + "..." : ""
            let comment = parts.count > 2 ? String(parts[2]) : ""
            return SSHAuthorizedKey(
                id: idx + 1, keyType: keyType, fingerprint: fp,
                comment: comment, fullLine: str
            )
        }
    }

    private func parseHostKeys(_ s: String) {
        hostKeyFingerprints = s.split(separator: "\n").compactMap { line in
            // Format: 256 SHA256:xxx /etc/ssh/ssh_host_ed25519_key.pub (ED25519)
            let parts = String(line).split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 4 else { return nil }
            let keyType = parts.last?.replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "") ?? ""
            return SSHHostKeyFingerprint(
                bits: parts[0], hash: parts[1],
                keyFile: parts[2], keyType: keyType
            )
        }
    }

    private func parseFailedLogins(_ s: String) {
        failedLogins = s.split(separator: "\n").compactMap { line in
            let str = String(line)
            // Extract IP from "Failed password for X from IP" or "Invalid user X from IP"
            var ip = "—"
            if let fromRange = str.range(of: "from ") {
                let after = str[fromRange.upperBound...]
                ip = String(after.prefix(while: { !$0.isWhitespace }))
            }
            var user = "—"
            if let forRange = str.range(of: "for ") {
                let after = str[forRange.upperBound...]
                user = String(after.prefix(while: { !$0.isWhitespace }))
            }
            // Timestamp is typically first 15 chars (syslog) or ISO format (journalctl)
            let timestamp = String(str.prefix(15))
            return SSHFailedLogin(timestamp: timestamp, ip: ip, user: user, message: str)
        }
    }

    private func parseRecentLogins(_ s: String) {
        recentLogins = s.split(separator: "\n").compactMap { line in
            let str = String(line)
            guard !str.hasPrefix("wtmp") && !str.isEmpty else { return nil }
            let parts = str.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            let user = parts[0]
            let terminal = parts[1]
            // fromIP might be an IP or hostname at index 2
            let fromIP = parts.count > 2 ? parts[2] : "—"
            let dateRange = parts.count > 3 ? parts[3...].joined(separator: " ") : ""
            return SSHRecentLogin(user: user, terminal: terminal, fromIP: fromIP, dateRange: dateRange)
        }
    }

    private func calculateSecurityScore() {
        var score = 100
        var issues: [String] = []

        // Check from existing VM data (permit root, password auth come from main VM)
        if maxAuthTries.isEmpty || (Int(maxAuthTries) ?? 6) > 5 {
            score -= 10
            issues.append("MaxAuthTries should be ≤ 5")
        }
        if x11Forwarding.lowercased() == "yes" {
            score -= 10
            issues.append("X11Forwarding is enabled")
        }
        if authorizedKeys.isEmpty {
            score -= 15
            issues.append("No SSH keys configured — using password only")
        }
        if failedLogins.count > 20 {
            score -= 15
            issues.append("\(failedLogins.count) failed login attempts detected")
        } else if failedLogins.count > 5 {
            score -= 5
            issues.append("\(failedLogins.count) failed login attempts")
        }
        if allowedUsers.isEmpty {
            score -= 10
            issues.append("AllowUsers not configured — all users can SSH")
        }

        let grade: String
        switch score {
        case 90...100: grade = "A"
        case 75..<90: grade = "B"
        case 60..<75: grade = "C"
        case 40..<60: grade = "D"
        default: grade = "F"
        }
        securityScore = SSHSecurityScore(score: max(score, 0), grade: grade, issues: issues)
    }

    // MARK: - Firewall Parsing

    func parseFirewall(_ sections: [String: String]) {
        firewallType = (sections["FWTYPE"] ?? "none").trimmingCharacters(in: .whitespaces)
        let status = sections["FWSTATUS"] ?? ""
        firewallStatus = status
        firewallEnabled = status.lowercased().contains("active") ||
                          status.lowercased().contains("running") ||
                          status.lowercased().contains("status: active")
        parseFirewallRules(sections["FWRULES"] ?? "")
    }

    private func parseFirewallRules(_ s: String) {
        switch firewallType {
        case "ufw":
            parseUFWRules(s)
        case "firewalld":
            parseFirewalldRules(s)
        case "iptables":
            parseIptablesRules(s)
        default:
            firewallRules = []
        }
    }

    private func parseUFWRules(_ s: String) {
        // Format: [ 1] 22/tcp ALLOW IN Anywhere
        firewallRules = s.split(separator: "\n").enumerated().compactMap { idx, line in
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard str.hasPrefix("[") else { return nil }
            let cleaned = str.replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespaces)
            let parts = cleaned.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            let ruleNum = Int(parts[0]) ?? (idx + 1)
            let portProto = parts[1].split(separator: "/")
            let port = portProto.count > 0 ? String(portProto[0]) : parts[1]
            let proto = portProto.count > 1 ? String(portProto[1]) : ""
            let action = parts[2]
            let direction = parts.count > 3 ? parts[3] : ""
            let source = parts.count > 4 ? parts[4...].joined(separator: " ") : "Anywhere"
            return ServerFirewallRule(
                id: ruleNum, action: action, direction: direction,
                proto: proto, port: port, source: source, raw: str
            )
        }
    }

    private func parseFirewalldRules(_ s: String) {
        // Parse ports from "ports:" line
        var ruleIdx = 0
        for line in s.split(separator: "\n") {
            let str = String(line).trimmingCharacters(in: .whitespaces)
            if str.hasPrefix("ports:") {
                let portsStr = str.replacingOccurrences(of: "ports:", with: "").trimmingCharacters(in: .whitespaces)
                for portEntry in portsStr.split(separator: " ") {
                    ruleIdx += 1
                    let parts = portEntry.split(separator: "/")
                    let port = parts.count > 0 ? String(parts[0]) : String(portEntry)
                    let proto = parts.count > 1 ? String(parts[1]) : "tcp"
                    firewallRules.append(ServerFirewallRule(
                        id: ruleIdx, action: "ACCEPT", direction: "IN",
                        proto: proto, port: port, source: "any", raw: String(portEntry)
                    ))
                }
            }
        }
    }

    private func parseIptablesRules(_ s: String) {
        // Parse iptables -L -n --line-numbers output
        firewallRules = s.split(separator: "\n").compactMap { line in
            let str = String(line)
            let parts = str.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard let num = Int(parts.first ?? ""), parts.count >= 4 else { return nil }
            let action = parts[1]
            let proto = parts[2]
            let source = parts.count > 4 ? parts[4] : "any"
            // Try to find dpt:PORT
            var port = "*"
            for p in parts {
                if p.hasPrefix("dpt:") {
                    port = String(p.dropFirst(4))
                }
            }
            return ServerFirewallRule(
                id: num, action: action, direction: "INPUT",
                proto: proto, port: port, source: source, raw: str
            )
        }
    }

    // MARK: - Fail2Ban Parsing

    func parseFail2Ban(_ sections: [String: String]) {
        let installed = (sections["F2BINSTALLED"] ?? "no").trimmingCharacters(in: .whitespaces)
        fail2BanInstalled = installed == "yes"
        if fail2BanInstalled {
            parseFail2BanJails(sections["F2BJAILS"] ?? "")
            parseFail2BanLog(sections["F2BLOG"] ?? "")
        }
    }

    private func parseFail2BanJails(_ s: String) {
        // Split by ---JAIL:name--- markers
        let jailBlocks = s.components(separatedBy: "---JAIL:")
        fail2BanJails = jailBlocks.compactMap { block in
            guard let endIdx = block.firstIndex(of: "-"),
                  block[block.startIndex..<endIdx] != "" else { return nil }
            // Extract jail name from "name---"
            let nameEnd = block.range(of: "---")
            let name = nameEnd != nil ? String(block[block.startIndex..<nameEnd!.lowerBound]) : ""
            guard !name.isEmpty else { return nil }
            let content = nameEnd != nil ? String(block[nameEnd!.upperBound...]) : block

            var banned = 0, totalBanned = 0, failed = 0, totalFailed = 0
            var ips: [String] = []

            for line in content.split(separator: "\n") {
                let str = String(line).trimmingCharacters(in: .whitespaces)
                if str.contains("Currently banned:") {
                    banned = Int(str.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
                } else if str.contains("Total banned:") {
                    totalBanned = Int(str.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
                } else if str.contains("Currently failed:") {
                    failed = Int(str.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
                } else if str.contains("Total failed:") {
                    totalFailed = Int(str.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
                } else if str.contains("Banned IP list:") {
                    let ipList = str.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                    ips = ipList.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                }
            }

            return Fail2BanJail(
                id: name, name: name,
                currentlyBanned: banned, totalBanned: totalBanned,
                currentlyFailed: failed, totalFailed: totalFailed,
                bannedIPs: ips
            )
        }
    }

    private func parseFail2BanLog(_ s: String) {
        fail2BanLogs = s.split(separator: "\n").compactMap { line in
            let str = String(line)
            // Format: 2024-01-01 12:00:00,000 fail2ban.actions [123]: NOTICE [sshd] Ban 1.2.3.4
            let parts = str.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 6 else { return nil }
            let timestamp = parts[0] + " " + parts[1]
            let level = parts.count > 3 ? parts[3] : ""
            // Find jail in [brackets]
            var jail = ""
            var action = ""
            var ip = ""
            for p in parts {
                if p.hasPrefix("[") && p.hasSuffix("]") && p != parts[3] {
                    jail = p.replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
                }
            }
            if let banIdx = parts.firstIndex(of: "Ban") {
                action = "Ban"
                if banIdx + 1 < parts.count { ip = parts[banIdx + 1] }
            } else if let unbanIdx = parts.firstIndex(of: "Unban") {
                action = "Unban"
                if unbanIdx + 1 < parts.count { ip = parts[unbanIdx + 1] }
            }
            guard !action.isEmpty else { return nil }
            return Fail2BanLogEntry(
                timestamp: timestamp, level: level,
                jail: jail, action: action, ip: ip
            )
        }
    }
}
