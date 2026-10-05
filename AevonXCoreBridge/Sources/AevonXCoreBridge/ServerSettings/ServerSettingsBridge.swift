//
//  ServerSettingsBridge.swift
//  AevonXCoreBridge
//
//  Swift wrappers for Go Core server settings commands.
//  All methods return SSH command strings — no SSH execution here.
//

import Foundation
import AevonXCoreLib

/// Bridge to Go Core server settings command builders.
public final class ServerSettingsBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = ServerSettingsBridge()
    private init() {}

    // MARK: - Server Info

    /// Returns a batched SSH command to collect all server info in one call.
    public func serverInfoSnapshotCmd() -> String {
        let cStr = ServerSettingsInfoSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a batched SSH command to collect network info.
    public func networkInfoSnapshotCmd() -> String {
        let cStr = ServerSettingsNetworkSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to collect disk partition info.
    public func diskSnapshotCmd() -> String {
        let cStr = ServerSettingsDiskSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - SSH Config

    /// Returns a batched SSH command to read SSH configuration.
    public func sshConfigSnapshotCmd() -> String {
        let cStr = ServerSettingsSSHConfigSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to save SSH config (PermitRootLogin, PasswordAuth).
    public func sshConfigSaveCmd(permitRoot: Bool, passwordAuth: Bool) -> String {
        let cStr = ServerSettingsSSHConfigSaveCmd(
            permitRoot ? 1 : 0,
            passwordAuth ? 1 : 0
        )
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to change hostname.
    public func hostnameChangeCmd(hostname: String) -> String {
        let cStr = withCArgs { c in ServerSettingsHostnameChangeCmd(c.str(hostname)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to change timezone.
    public func timezoneChangeCmd(timezone: String) -> String {
        let cStr = withCArgs { c in ServerSettingsTimezoneChangeCmd(c.str(timezone)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Users

    /// Returns a batched SSH command to list users and last logins.
    public func usersSnapshotCmd() -> String {
        let cStr = ServerSettingsUsersSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to add a new user.
    public func userAddCmd(username: String, password: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserAddCmd(c.str(username), c.str(password)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to delete a user.
    public func userDeleteCmd(username: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserDeleteCmd(c.str(username)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Services

    /// Returns a command to list all services for the given init system.
    public func servicesListCmd(initSystem: String) -> String {
        let cStr = withCArgs { c in ServerSettingsServicesListCmd(c.str(initSystem)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a batched command to list ALL services with enabled/disabled state.
    public func servicesFullListCmd(initSystem: String) -> String {
        let cStr = withCArgs { c in ServerSettingsServicesFullListCmd(c.str(initSystem)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to control a service (start/stop/restart/enable/disable).
    public func serviceControlCmd(initSystem: String, operation: String, service: String) -> String {
        let cStr = withCArgs { c in
            ServerSettingsServiceControlCmd(c.str(initSystem), c.str(operation), c.str(service))
        }
        defer { CoreFreeString(cStr) }
        guard let ptr = cStr else { return "" }
        let result = String(cString: ptr)
        if result.hasPrefix("{") { return "" }
        return result
    }

    /// Returns a command to view service logs.
    public func serviceLogsCmd(initSystem: String, service: String, lines: Int32) -> String {
        let cStr = withCArgs { c in
            ServerSettingsServiceLogsCmd(c.str(initSystem), c.str(service), lines)
        }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to restart the SSH daemon.
    public func serviceRestartSSHCmd(initSystem: String) -> String {
        let cStr = withCArgs { c in ServerSettingsServiceRestartSSHCmd(c.str(initSystem)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Updates

    /// Returns a command to check for available updates (count only).
    public func updateCheckCmd(pkgManager: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUpdateCheckCmd(c.str(pkgManager)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a batched command to check updates with detailed package list.
    public func updateCheckWithListCmd(pkgManager: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUpdateCheckWithListCmd(c.str(pkgManager)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to update a single package.
    public func updatePackageCmd(pkgManager: String, package: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUpdatePackageCmd(c.str(pkgManager), c.str(`package`)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to apply security updates only.
    public func updateSecurityOnlyCmd(pkgManager: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUpdateSecurityOnlyCmd(c.str(pkgManager)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to upgrade all packages.
    public func updateUpgradeCmd(pkgManager: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUpdateUpgradeCmd(c.str(pkgManager)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Timezone

    /// Returns a command to list all available timezones from the server.
    public func timezoneListCmd() -> String {
        let cStr = ServerSettingsTimezoneListCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Passwords

    /// Returns a command to change root password.
    public func rootPasswordCmd(password: String) -> String {
        let cStr = withCArgs { c in ServerSettingsRootPasswordCmd(c.str(password)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to change MySQL root password.
    public func mysqlPasswordCmd(password: String) -> String {
        let cStr = withCArgs { c in ServerSettingsMySQLPasswordCmd(c.str(password)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to change PostgreSQL password.
    public func postgresPasswordCmd(password: String) -> String {
        let cStr = withCArgs { c in ServerSettingsPostgresPasswordCmd(c.str(password)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Network

    /// Returns a batched command for all network info.
    public func networkFullSnapshotCmd() -> String {
        let cStr = ServerSettingsNetworkFullSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to save DNS configuration.
    public func saveDNSCmd(content: String) -> String {
        let cStr = withCArgs { c in ServerSettingsSaveDNSCmd(c.str(content)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to save /etc/hosts.
    public func saveHostsCmd(content: String) -> String {
        let cStr = withCArgs { c in ServerSettingsSaveHostsCmd(c.str(content)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Resource Monitoring

    /// Returns a batched command for all real-time resource metrics.
    public func resourceSnapshotCmd() -> String {
        let cStr = ServerSettingsResourceSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to SIGTERM a process by PID.
    public func killProcessCmd(pid: Int32) -> String {
        let cStr = ServerSettingsKillProcessCmd(pid)
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    /// Returns a command to SIGKILL a process by PID.
    public func forceKillProcessCmd(pid: Int32) -> String {
        let cStr = ServerSettingsForceKillProcessCmd(pid)
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - SSH Security

    public func sshSecuritySnapshotCmd() -> String {
        let cStr = ServerSettingsSSHSecuritySnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func sshAddKeyCmd(pubKey: String) -> String {
        let cStr = withCArgs { c in ServerSettingsSSHAddKeyCmd(c.str(pubKey)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func sshDeleteKeyCmd(lineNum: Int32) -> String {
        let cStr = ServerSettingsSSHDeleteKeyCmd(lineNum)
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Firewall

    public func firewallSnapshotCmd() -> String {
        let cStr = ServerSettingsFirewallSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func firewallEnableCmd(fwType: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFirewallEnableCmd(c.str(fwType)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func firewallDisableCmd(fwType: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFirewallDisableCmd(c.str(fwType)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func firewallAddRuleCmd(fwType: String, proto: String, port: String, action: String) -> String {
        let cStr = withCArgs { c in
            ServerSettingsFirewallAddRuleCmd(c.str(fwType), c.str(proto), c.str(port), c.str(action))
        }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func firewallDeleteRuleCmd(fwType: String, ruleNum: Int32, proto: String, port: String) -> String {
        let cStr = withCArgs { c in
            ServerSettingsFirewallDeleteRuleCmd(c.str(fwType), ruleNum, c.str(proto), c.str(port))
        }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func firewallBlockIPCmd(fwType: String, ip: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFirewallBlockIPCmd(c.str(fwType), c.str(ip)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func firewallUnblockIPCmd(fwType: String, ip: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFirewallUnblockIPCmd(c.str(fwType), c.str(ip)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Fail2Ban

    public func fail2BanSnapshotCmd() -> String {
        let cStr = ServerSettingsFail2BanSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func fail2BanInstallCmd(pkgManager: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFail2BanInstallCmd(c.str(pkgManager)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func fail2BanUnbanIPCmd(jail: String, ip: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFail2BanUnbanIPCmd(c.str(jail), c.str(ip)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func fail2BanBanIPCmd(jail: String, ip: String) -> String {
        let cStr = withCArgs { c in ServerSettingsFail2BanBanIPCmd(c.str(jail), c.str(ip)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func fail2BanJailConfigCmd(jail: String, maxRetry: Int32, banTime: String, findTime: String) -> String {
        let cStr = withCArgs { c in
            ServerSettingsFail2BanJailConfigCmd(c.str(jail), maxRetry, c.str(banTime), c.str(findTime))
        }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func fail2BanRestartCmd() -> String {
        let cStr = ServerSettingsFail2BanRestartCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Advanced User Management

    public func userAdvancedSnapshotCmd() -> String {
        let cStr = ServerSettingsUserAdvancedSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userKillSessionCmd(terminal: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserKillSessionCmd(c.str(terminal)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userGroupAddCmd(group: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserGroupAddCmd(c.str(group)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userGroupDeleteCmd(group: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserGroupDeleteCmd(c.str(group)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userAddToGroupCmd(username: String, group: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserAddToGroupCmd(c.str(username), c.str(group)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userRemoveFromGroupCmd(username: String, group: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserRemoveFromGroupCmd(c.str(username), c.str(group)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userGrantSudoCmd(username: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserGrantSudoCmd(c.str(username)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userRevokeSudoCmd(username: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserRevokeSudoCmd(c.str(username)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userChangeShellCmd(username: String, shell: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserChangeShellCmd(c.str(username), c.str(shell)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userLockCmd(username: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserLockCmd(c.str(username)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func userUnlockCmd(username: String) -> String {
        let cStr = withCArgs { c in ServerSettingsUserUnlockCmd(c.str(username)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - System Control

    public func systemControlSnapshotCmd() -> String {
        let cStr = ServerSettingsSystemControlSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemRebootCmd() -> String {
        let cStr = ServerSettingsSystemRebootCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemShutdownCmd() -> String {
        let cStr = ServerSettingsSystemShutdownCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemScheduleRebootCmd(when: String) -> String {
        let cStr = withCArgs { c in ServerSettingsSystemScheduleRebootCmd(c.str(when)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemCancelRebootCmd() -> String {
        let cStr = ServerSettingsSystemCancelRebootCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemSwapResizeCmd(sizeMB: Int32) -> String {
        let cStr = ServerSettingsSystemSwapResizeCmd(sizeMB)
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemSetKernelParamCmd(key: String, value: String) -> String {
        let cStr = withCArgs { c in ServerSettingsSystemSetKernelParamCmd(c.str(key), c.str(value)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - System Logs

    public func systemLogsSnapshotCmd() -> String {
        let cStr = ServerSettingsSystemLogsSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemLogsQueryCmd(source: String, priority: String, service: String, search: String, lines: Int32) -> String {
        let cStr = withCArgs { c in
            ServerSettingsSystemLogsQueryCmd(c.str(source), c.str(priority), c.str(service), c.str(search), lines)
        }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func systemLogsClearCmd(source: String) -> String {
        let cStr = withCArgs { c in ServerSettingsSystemLogsClearCmd(c.str(source)) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    // MARK: - Cron

    public func cronSnapshotCmd() -> String {
        let cStr = ServerSettingsCronSnapshotCmd()
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func cronAddCmd(user: String, schedule: String, command: String) -> String {
        let cStr = withCArgs { c in
            ServerSettingsCronAddCmd(c.str(user), c.str(schedule), c.str(command))
        }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func cronDeleteCmd(user: String, lineNum: Int32) -> String {
        let cStr = withCArgs { c in ServerSettingsCronDeleteCmd(c.str(user), lineNum) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }

    public func cronToggleCmd(user: String, lineNum: Int32, enable: Bool) -> String {
        let cStr = withCArgs { c in ServerSettingsCronToggleCmd(c.str(user), lineNum, enable ? 1 : 0) }
        defer { CoreFreeString(cStr) }
        return cStr.map { String(cString: $0) } ?? ""
    }
}
