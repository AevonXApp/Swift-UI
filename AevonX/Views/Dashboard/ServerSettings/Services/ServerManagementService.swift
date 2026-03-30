//
//  ServerManagementService.swift
//  AevonX
//
//  Bridge-backed actor for server settings operations.
//  Calls ServerSettingsBridge methods only — no hardcoded SSH commands.
//

import Foundation
import AevonXCoreBridge

actor ServerManagementService {

    static let shared = ServerManagementService()
    private let bridge = ServerSettingsBridge.shared

    private init() {}

    // MARK: - Server Info

    func serverInfoSnapshotCmd() -> String {
        bridge.serverInfoSnapshotCmd()
    }

    func networkInfoSnapshotCmd() -> String {
        bridge.networkInfoSnapshotCmd()
    }

    func diskSnapshotCmd() -> String {
        bridge.diskSnapshotCmd()
    }

    // MARK: - SSH Config

    func sshConfigSnapshotCmd() -> String {
        bridge.sshConfigSnapshotCmd()
    }

    func sshConfigSaveCmd(permitRoot: Bool, passwordAuth: Bool) -> String {
        bridge.sshConfigSaveCmd(permitRoot: permitRoot, passwordAuth: passwordAuth)
    }

    func hostnameChangeCmd(hostname: String) -> String {
        bridge.hostnameChangeCmd(hostname: hostname)
    }

    func timezoneChangeCmd(timezone: String) -> String {
        bridge.timezoneChangeCmd(timezone: timezone)
    }

    // MARK: - Users

    func usersSnapshotCmd() -> String {
        bridge.usersSnapshotCmd()
    }

    func userAddCmd(username: String, password: String) -> String {
        bridge.userAddCmd(username: username, password: password)
    }

    func userDeleteCmd(username: String) -> String {
        bridge.userDeleteCmd(username: username)
    }

    func userAdvancedSnapshotCmd() -> String {
        bridge.userAdvancedSnapshotCmd()
    }

    func userKillSessionCmd(terminal: String) -> String {
        bridge.userKillSessionCmd(terminal: terminal)
    }

    func userGroupAddCmd(group: String) -> String {
        bridge.userGroupAddCmd(group: group)
    }

    func userGroupDeleteCmd(group: String) -> String {
        bridge.userGroupDeleteCmd(group: group)
    }

    func userAddToGroupCmd(username: String, group: String) -> String {
        bridge.userAddToGroupCmd(username: username, group: group)
    }

    func userRemoveFromGroupCmd(username: String, group: String) -> String {
        bridge.userRemoveFromGroupCmd(username: username, group: group)
    }

    func userGrantSudoCmd(username: String) -> String {
        bridge.userGrantSudoCmd(username: username)
    }

    func userRevokeSudoCmd(username: String) -> String {
        bridge.userRevokeSudoCmd(username: username)
    }

    func userChangeShellCmd(username: String, shell: String) -> String {
        bridge.userChangeShellCmd(username: username, shell: shell)
    }

    func userLockCmd(username: String) -> String {
        bridge.userLockCmd(username: username)
    }

    func userUnlockCmd(username: String) -> String {
        bridge.userUnlockCmd(username: username)
    }

    // MARK: - Services

    func servicesListCmd(initSystem: String) -> String {
        bridge.servicesListCmd(initSystem: initSystem)
    }

    func servicesFullListCmd(initSystem: String) -> String {
        bridge.servicesFullListCmd(initSystem: initSystem)
    }

    func serviceControlCmd(initSystem: String, operation: String, service: String) -> String {
        bridge.serviceControlCmd(initSystem: initSystem, operation: operation, service: service)
    }

    func serviceLogsCmd(initSystem: String, service: String, lines: Int32 = 50) -> String {
        bridge.serviceLogsCmd(initSystem: initSystem, service: service, lines: lines)
    }

    func serviceRestartSSHCmd(initSystem: String) -> String {
        bridge.serviceRestartSSHCmd(initSystem: initSystem)
    }

    // MARK: - Updates

    func updateCheckCmd(pkgManager: String) -> String {
        bridge.updateCheckCmd(pkgManager: pkgManager)
    }

    func updateCheckWithListCmd(pkgManager: String) -> String {
        bridge.updateCheckWithListCmd(pkgManager: pkgManager)
    }

    func updatePackageCmd(pkgManager: String, package: String) -> String {
        bridge.updatePackageCmd(pkgManager: pkgManager, package: `package`)
    }

    func updateSecurityOnlyCmd(pkgManager: String) -> String {
        bridge.updateSecurityOnlyCmd(pkgManager: pkgManager)
    }

    func updateUpgradeCmd(pkgManager: String) -> String {
        bridge.updateUpgradeCmd(pkgManager: pkgManager)
    }

    // MARK: - Timezone

    func timezoneListCmd() -> String {
        bridge.timezoneListCmd()
    }

    // MARK: - Passwords

    func rootPasswordCmd(password: String) -> String {
        bridge.rootPasswordCmd(password: password)
    }

    func mysqlPasswordCmd(password: String) -> String {
        bridge.mysqlPasswordCmd(password: password)
    }

    func postgresPasswordCmd(password: String) -> String {
        bridge.postgresPasswordCmd(password: password)
    }

    // MARK: - Network

    func networkFullSnapshotCmd() -> String {
        bridge.networkFullSnapshotCmd()
    }

    func saveDNSCmd(content: String) -> String {
        bridge.saveDNSCmd(content: content)
    }

    func saveHostsCmd(content: String) -> String {
        bridge.saveHostsCmd(content: content)
    }

    // MARK: - Resource Monitoring

    func resourceSnapshotCmd() -> String {
        bridge.resourceSnapshotCmd()
    }

    func killProcessCmd(pid: Int32) -> String {
        bridge.killProcessCmd(pid: pid)
    }

    func forceKillProcessCmd(pid: Int32) -> String {
        bridge.forceKillProcessCmd(pid: pid)
    }

    // MARK: - SSH Security

    func sshSecuritySnapshotCmd() -> String {
        bridge.sshSecuritySnapshotCmd()
    }

    func sshAddKeyCmd(pubKey: String) -> String {
        bridge.sshAddKeyCmd(pubKey: pubKey)
    }

    func sshDeleteKeyCmd(lineNum: Int32) -> String {
        bridge.sshDeleteKeyCmd(lineNum: lineNum)
    }

    // MARK: - Firewall

    func firewallSnapshotCmd() -> String {
        bridge.firewallSnapshotCmd()
    }

    func firewallEnableCmd(fwType: String) -> String {
        bridge.firewallEnableCmd(fwType: fwType)
    }

    func firewallDisableCmd(fwType: String) -> String {
        bridge.firewallDisableCmd(fwType: fwType)
    }

    func firewallAddRuleCmd(fwType: String, proto: String, port: String, action: String) -> String {
        bridge.firewallAddRuleCmd(fwType: fwType, proto: proto, port: port, action: action)
    }

    func firewallDeleteRuleCmd(fwType: String, ruleNum: Int32, proto: String, port: String) -> String {
        bridge.firewallDeleteRuleCmd(fwType: fwType, ruleNum: ruleNum, proto: proto, port: port)
    }

    func firewallBlockIPCmd(fwType: String, ip: String) -> String {
        bridge.firewallBlockIPCmd(fwType: fwType, ip: ip)
    }

    func firewallUnblockIPCmd(fwType: String, ip: String) -> String {
        bridge.firewallUnblockIPCmd(fwType: fwType, ip: ip)
    }

    // MARK: - Fail2Ban

    func fail2BanSnapshotCmd() -> String {
        bridge.fail2BanSnapshotCmd()
    }

    func fail2BanInstallCmd(pkgManager: String) -> String {
        bridge.fail2BanInstallCmd(pkgManager: pkgManager)
    }

    func fail2BanUnbanIPCmd(jail: String, ip: String) -> String {
        bridge.fail2BanUnbanIPCmd(jail: jail, ip: ip)
    }

    func fail2BanBanIPCmd(jail: String, ip: String) -> String {
        bridge.fail2BanBanIPCmd(jail: jail, ip: ip)
    }

    func fail2BanJailConfigCmd(jail: String, maxRetry: Int32, banTime: String, findTime: String) -> String {
        bridge.fail2BanJailConfigCmd(jail: jail, maxRetry: maxRetry, banTime: banTime, findTime: findTime)
    }

    func fail2BanRestartCmd() -> String {
        bridge.fail2BanRestartCmd()
    }

    // MARK: - System Control

    func systemControlSnapshotCmd() -> String {
        bridge.systemControlSnapshotCmd()
    }

    func systemRebootCmd() -> String {
        bridge.systemRebootCmd()
    }

    func systemShutdownCmd() -> String {
        bridge.systemShutdownCmd()
    }

    func systemScheduleRebootCmd(when: String) -> String {
        bridge.systemScheduleRebootCmd(when: when)
    }

    func systemCancelRebootCmd() -> String {
        bridge.systemCancelRebootCmd()
    }

    func systemSwapResizeCmd(sizeMB: Int32) -> String {
        bridge.systemSwapResizeCmd(sizeMB: sizeMB)
    }

    func systemSetKernelParamCmd(key: String, value: String) -> String {
        bridge.systemSetKernelParamCmd(key: key, value: value)
    }

    // MARK: - System Logs

    func systemLogsSnapshotCmd() -> String {
        bridge.systemLogsSnapshotCmd()
    }

    func systemLogsQueryCmd(source: String, priority: String, service: String, search: String, lines: Int32) -> String {
        bridge.systemLogsQueryCmd(source: source, priority: priority, service: service, search: search, lines: lines)
    }

    func systemLogsClearCmd(source: String) -> String {
        bridge.systemLogsClearCmd(source: source)
    }

    // MARK: - Cron

    func cronSnapshotCmd() -> String {
        bridge.cronSnapshotCmd()
    }

    func cronAddCmd(user: String, schedule: String, command: String) -> String {
        bridge.cronAddCmd(user: user, schedule: schedule, command: command)
    }

    func cronDeleteCmd(user: String, lineNum: Int32) -> String {
        bridge.cronDeleteCmd(user: user, lineNum: lineNum)
    }

    func cronToggleCmd(user: String, lineNum: Int32, enable: Bool) -> String {
        bridge.cronToggleCmd(user: user, lineNum: lineNum, enable: enable)
    }

    // MARK: - Parsing Helpers

    func parseSections(_ output: String) -> [String: String] {
        var sections: [String: String] = [:]
        let parts = output.components(separatedBy: "===")
        // Output format: ===KEY===\nvalue\n===KEY2===\nvalue2\n===END===
        // Split by === gives: ["", "KEY", "\nvalue\n", "KEY2", "\nvalue2\n", "END", "\n"]
        // Keys are at odd indices (1, 3, 5...), values at even indices (2, 4, 6...)
        var i = 1
        while i < parts.count - 1 {
            let key = parts[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty && key != "END" {
                let value = parts[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                sections[key] = value
            }
            i += 2
        }
        return sections
    }
}
