//
//  SecurityVM.swift
//  AevonX
//
//  ViewModel for SSH security, firewall, and Fail2Ban management.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class SecurityVM: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - SSH Security
    @Published var authorizedKeys: [SSHAuthorizedKey] = []
    @Published var hostKeyFingerprints: [SSHHostKeyFingerprint] = []
    @Published var failedLogins: [SSHFailedLogin] = []
    @Published var recentLogins: [SSHRecentLogin] = []
    @Published var securityScore: SSHSecurityScore?
    @Published var maxAuthTries = ""
    @Published var x11Forwarding = ""
    @Published var allowedUsers = ""
    @Published var newPubKey = ""

    // MARK: - Firewall
    @Published var firewallType = "none"
    @Published var firewallEnabled = false
    @Published var firewallStatus = ""
    @Published var firewallRules: [ServerFirewallRule] = []
    @Published var newRulePort = ""
    @Published var newRuleProto = "tcp"
    @Published var newRuleAction = "allow"
    @Published var blockIPText = ""

    // MARK: - Fail2Ban
    @Published var fail2BanInstalled = false
    @Published var fail2BanJails: [Fail2BanJail] = []
    @Published var fail2BanLogs: [Fail2BanLogEntry] = []
    @Published var unbanIPText = ""
    @Published var selectedJail: String?

    // MARK: - State
    @Published var isLoading = true
    @Published var isLoadingFirewall = true
    @Published var isLoadingFail2Ban = true
    @Published var saveMsg: (String, Bool)? = nil

    var isConnected: Bool {
        SSHBridge.shared.isConnected(serverID: serverId)
    }

    init(serverId: String) {
        self.serverId = serverId
    }

    func ssh(_ cmd: String) async -> String {
        guard !cmd.isEmpty else { return "" }
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: cmd)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Load All

    func loadAll() async {
        guard isConnected else { return }
        async let ssh: () = loadSSHSecurity()
        async let fw: () = loadFirewall()
        async let f2b: () = loadFail2Ban()
        _ = await (ssh, fw, f2b)
    }

    func loadSSHSecurity() async {
        isLoading = true
        defer { isLoading = false }
        let cmd = await service.sshSecuritySnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseSSHSecurity(sections)
    }

    func loadFirewall() async {
        isLoadingFirewall = true
        defer { isLoadingFirewall = false }
        let cmd = await service.firewallSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseFirewall(sections)
    }

    func loadFail2Ban() async {
        isLoadingFail2Ban = true
        defer { isLoadingFail2Ban = false }
        let cmd = await service.fail2BanSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseFail2Ban(sections)
    }

    // MARK: - SSH Actions

    func addSSHKey() async {
        guard !newPubKey.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let cmd = await service.sshAddKeyCmd(pubKey: newPubKey.trimmingCharacters(in: .whitespacesAndNewlines))
        let out = await ssh(cmd)
        if out.contains("OK") {
            newPubKey = ""
            showMsg(L10n.ServerSettings.keyAdded, true)
            await loadSSHSecurity()
        } else {
            showMsg(L10n.ServerSettings.keyAddFailed, false)
        }
    }

    func deleteSSHKey(_ lineNum: Int) async {
        let cmd = await service.sshDeleteKeyCmd(lineNum: Int32(lineNum))
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.keyRemoved, true)
            await loadSSHSecurity()
        } else {
            showMsg(L10n.ServerSettings.keyRemoveFailed, false)
        }
    }

    // MARK: - Firewall Actions

    func toggleFirewall() async {
        let cmd: String
        if firewallEnabled {
            cmd = await service.firewallDisableCmd(fwType: firewallType)
        } else {
            cmd = await service.firewallEnableCmd(fwType: firewallType)
        }
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(firewallEnabled ? L10n.ServerSettings.firewallDisabled : L10n.ServerSettings.firewallEnabled, true)
            await loadFirewall()
        } else {
            showMsg(L10n.ServerSettings.firewallToggleFailed, false)
        }
    }

    func addFirewallRule() async {
        guard !newRulePort.isEmpty else { return }
        let cmd = await service.firewallAddRuleCmd(
            fwType: firewallType, proto: newRuleProto,
            port: newRulePort, action: newRuleAction
        )
        let out = await ssh(cmd)
        if out.contains("OK") {
            newRulePort = ""
            showMsg(L10n.ServerSettings.ruleAdded, true)
            await loadFirewall()
        } else {
            showMsg(L10n.ServerSettings.ruleAddFailed, false)
        }
    }

    func deleteFirewallRule(_ rule: ServerFirewallRule) async {
        let cmd = await service.firewallDeleteRuleCmd(
            fwType: firewallType, ruleNum: Int32(rule.id),
            proto: rule.proto, port: rule.port
        )
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.ruleDeleted, true)
            await loadFirewall()
        } else {
            showMsg(L10n.ServerSettings.ruleDeleteFailed, false)
        }
    }

    func blockIP() async {
        guard !blockIPText.isEmpty else { return }
        let cmd = await service.firewallBlockIPCmd(fwType: firewallType, ip: blockIPText)
        let out = await ssh(cmd)
        if out.contains("OK") {
            blockIPText = ""
            showMsg(L10n.ServerSettings.ipBlocked, true)
            await loadFirewall()
        } else {
            showMsg(L10n.ServerSettings.ipBlockFailed, false)
        }
    }

    func unblockIP(_ ip: String) async {
        let cmd = await service.firewallUnblockIPCmd(fwType: firewallType, ip: ip)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.ipUnblocked, true)
            await loadFirewall()
        } else {
            showMsg(L10n.ServerSettings.ipUnblockFailed, false)
        }
    }

    // MARK: - Fail2Ban Actions

    func unbanIP(jail: String, ip: String) async {
        let cmd = await service.fail2BanUnbanIPCmd(jail: jail, ip: ip)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.ipUnbanned, true)
            await loadFail2Ban()
        } else {
            showMsg(L10n.ServerSettings.ipUnbanFailed, false)
        }
    }

    // MARK: - Helpers

    private func showMsg(_ text: String, _ success: Bool) {
        saveMsg = (text, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.saveMsg = nil }
    }
}
