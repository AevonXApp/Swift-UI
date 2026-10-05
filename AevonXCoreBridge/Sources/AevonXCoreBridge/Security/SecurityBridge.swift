//
//  SecurityBridge.swift
//  AevonXCoreBridge
//
//  Full Swift wrapper for Go Core Security operations.
//  Covers: models, static commands, parsers, parameterized command builders.
//

import Foundation
import AevonXCoreLib

public final class SecurityBridge: @unchecked Sendable {

    public static let shared = SecurityBridge()
    private init() {}

    // MARK: - Model Decode

    public func decodeScore(json: String) -> String {
        withCArgs { c in extract(SecurityDecodeScore(c.str(json))) }
    }

    public func decodeAIData(json: String) -> String {
        withCArgs { c in extract(SecurityDecodeAIData(c.str(json))) }
    }

    // MARK: - Static Commands (33 commands batch)

    public func getCommands() -> String {
        extract(SecurityGetCommands())
    }

    // MARK: - Parsers

    public func parseOpenPorts(linesJSON: String) -> String {
        withCArgs { c in extract(SecurityParseOpenPorts(c.str(linesJSON))) }
    }

    public func parseConnections(linesJSON: String) -> String {
        withCArgs { c in extract(SecurityParseConnections(c.str(linesJSON))) }
    }

    public func parseFirewallRules(linesJSON: String) -> String {
        withCArgs { c in extract(SecurityParseFirewallRules(c.str(linesJSON))) }
    }

    public func parseUsers(usersJSON: String, sudoJSON: String) -> String {
        withCArgs { c in extract(SecurityParseUsers(c.str(usersJSON), c.str(sudoJSON))) }
    }

    public func parseSSHConfig(output: String) -> String {
        withCArgs { c in extract(SecurityParseSSHConfig(c.str(output))) }
    }

    public func parseLoginStats(linesJSON: String) -> String {
        withCArgs { c in extract(SecurityParseLoginStats(c.str(linesJSON))) }
    }

    public func parseSessions(output: String) -> String {
        withCArgs { c in extract(SecurityParseSessions(c.str(output))) }
    }

    public func parseBannedIPs(output: String) -> String {
        withCArgs { c in extract(SecurityParseBannedIPs(c.str(output))) }
    }

    public func parseJailList(output: String) -> String {
        withCArgs { c in extract(SecurityParseJailList(c.str(output))) }
    }

    public func parseCertificates(linesJSON: String) -> String {
        withCArgs { c in extract(SecurityParseCertificates(c.str(linesJSON))) }
    }

    public func parseAttackSources(linesJSON: String) -> String {
        withCArgs { c in extract(SecurityParseAttackSources(c.str(linesJSON))) }
    }

    public func parseWAFStatus(installOutput: String, enabledOutput: String) -> String {
        withCArgs { c in extract(SecurityParseWAFStatus(c.str(installOutput), c.str(enabledOutput))) }
    }

    public func calculateScore(json: String) -> String {
        withCArgs { c in extract(SecurityCalculateScore(c.str(json))) }
    }

    // MARK: - SSH Command Builders

    public func cmdSSHConfig(configPath: String) -> String {
        withCArgs { c in extract(SecurityCmdSSHConfig(c.str(configPath))) }
    }

    public func cmdSetSSHPort(port: String, configPath: String) -> String {
        withCArgs { c in extract(SecurityCmdSetSSHPort(c.str(port), c.str(configPath))) }
    }

    public func cmdSetSSHPasswordAuth(enabled: Bool, configPath: String) -> String {
        withCArgs { c in extract(SecurityCmdSetSSHPasswordAuth(enabled ? 1 : 0, c.str(configPath))) }
    }

    public func cmdSetSSHKeyAuth(enabled: Bool, configPath: String) -> String {
        withCArgs { c in extract(SecurityCmdSetSSHKeyAuth(enabled ? 1 : 0, c.str(configPath))) }
    }

    public func cmdSetSSHRootLogin(mode: String, configPath: String) -> String {
        withCArgs { c in extract(SecurityCmdSetSSHRootLogin(c.str(mode), c.str(configPath))) }
    }

    public func cmdSSHLoginLogs(logPath: String, count: Int) -> String {
        withCArgs { c in extract(SecurityCmdSSHLoginLogs(c.str(logPath), Int32(count))) }
    }

    public func cmdSSHLoginStats(logPath: String) -> String {
        withCArgs { c in extract(SecurityCmdSSHLoginStats(c.str(logPath))) }
    }

    public func cmdAddAuthorizedKey(key: String) -> String {
        withCArgs { c in extract(SecurityCmdAddAuthorizedKey(c.str(key))) }
    }

    public func cmdRemoveAuthorizedKey(index: Int) -> String {
        extract(SecurityCmdRemoveAuthorizedKey(Int32(index)))
    }

    public func cmdKillSession(user: String) -> String {
        withCArgs { c in extract(SecurityCmdKillSession(c.str(user))) }
    }

    // MARK: - Firewall Command Builders

    public func cmdAddFirewallRule(proto: String, port: String, strategy: String, direction: String, sourceIP: String) -> String {
        withCArgs { c in extract(SecurityCmdAddFirewallRule(c.str(proto), c.str(port), c.str(strategy), c.str(direction), c.str(sourceIP))) }
    }

    public func cmdDeleteFirewallRule(proto: String, port: String, direction: String) -> String {
        withCArgs { c in extract(SecurityCmdDeleteFirewallRule(c.str(proto), c.str(port), c.str(direction))) }
    }

    public func cmdICMPBlock(enabled: Bool) -> String {
        extract(SecurityCmdICMPBlock(enabled ? 1 : 0))
    }

    // MARK: - Fail2ban Command Builders

    public func cmdFail2banUnban(ip: String, jail: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banUnban(c.str(ip), c.str(jail))) }
    }

    public func cmdFail2banBanIP(ip: String, jail: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banBanIP(c.str(ip), c.str(jail))) }
    }

    public func cmdFail2banSetMaxRetry(count: Int, configDir: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banSetMaxRetry(Int32(count), c.str(configDir))) }
    }

    public func cmdFail2banSetBanTime(seconds: Int, configDir: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banSetBanTime(Int32(seconds), c.str(configDir))) }
    }

    public func cmdFail2banJailStatus(jail: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banJailStatus(c.str(jail))) }
    }

    public func cmdFail2banWhitelist(configDir: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banWhitelist(c.str(configDir))) }
    }

    public func cmdFail2banAddToWhitelist(ip: String, configDir: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banAddToWhitelist(c.str(ip), c.str(configDir))) }
    }

    public func cmdFail2banRemoveFromWhitelist(ip: String, configDir: String) -> String {
        withCArgs { c in extract(SecurityCmdFail2banRemoveFromWhitelist(c.str(ip), c.str(configDir))) }
    }

    // MARK: - Certificate / AI / Integrity / WAF Commands

    public func cmdScanCertificates(sitesDir: String) -> String {
        withCArgs { c in extract(SecurityCmdScanCertificates(c.str(sitesDir))) }
    }

    public func cmdTopAttackers(logPath: String, limit: Int) -> String {
        withCArgs { c in extract(SecurityCmdTopAttackers(c.str(logPath), Int32(limit))) }
    }

    public func cmdAuthLog(logPath: String, lines: Int) -> String {
        withCArgs { c in extract(SecurityCmdAuthLog(c.str(logPath), Int32(lines))) }
    }

    public func cmdFailedLogins(logPath: String) -> String {
        withCArgs { c in extract(SecurityCmdFailedLogins(c.str(logPath))) }
    }

    public func cmdAcceptedLogins(logPath: String) -> String {
        withCArgs { c in extract(SecurityCmdAcceptedLogins(c.str(logPath))) }
    }

    public func cmdMalwareScan(targetDir: String) -> String {
        withCArgs { c in extract(SecurityCmdMalwareScan(c.str(targetDir))) }
    }

    public func cmdToggleWAF(enabled: Bool, configPath: String) -> String {
        withCArgs { c in extract(SecurityCmdToggleWAF(enabled ? 1 : 0, c.str(configPath))) }
    }

    public func cmdWAFAuditLog(lines: Int) -> String {
        extract(SecurityCmdWAFAuditLog(Int32(lines)))
    }

    /// Get the command to block an IP via ufw/iptables.
    public func blockIPCmd(ip: String) -> String {
        withCArgs { c in
            let result = SecurityBlockIPCmd(c.str(ip))
            defer { CoreFreeString(result) }
            guard let result = result else { return "" }
            let json = String(cString: result)
            guard let data = json.data(using: .utf8),
                  let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = resp["success"] as? Bool, success,
                  let innerData = resp["data"] as? [String: Any],
                  let cmd = innerData["command"] as? String else { return "" }
            return cmd
        }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }
}
