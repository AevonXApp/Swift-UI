//
//  ServerSettingsVM+Actions.swift
//  AevonX
//
//  Action methods for ServerSettingsViewModel.
//  All commands come from ServerManagementService (Bridge-backed).
//

import Foundation
import AevonXCoreBridge

extension ServerSettingsViewModel {

    func changeHostname() async {
        guard guardOperation("hostname") else { return }
        defer { endOperation("hostname") }
        guard !newHostname.isEmpty, newHostname != hostname else { return }
        let safeHostname = ShellSanitizer.sanitizeIdentifier(newHostname)
        guard !safeHostname.isEmpty else { hostnameMsg = ("Invalid hostname", false); return }
        isChangingHostname = true; defer { isChangingHostname = false }

        let cmd = await service.hostnameChangeCmd(hostname: safeHostname)
        let out = await ssh(cmd)
        if out.contains("OK") {
            hostname = safeHostname; isEditingHostname = false
            hostnameMsg = ("Hostname changed", true)
            logActivity(type: "ssh_command", description: "Changed hostname to \(safeHostname)")
        } else {
            hostnameMsg = ("Failed", false)
        }
        clearMsg(after: 4) { self.hostnameMsg = nil }
    }

    func changeTimezone() async {
        guard guardOperation("timezone") else { return }
        defer { endOperation("timezone") }
        guard !selectedTimezone.isEmpty, selectedTimezone != currentTimezone else { return }
        let safeTZ = String(selectedTimezone.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "/" || scalar == "_" || scalar == "-"
        })
        guard !safeTZ.isEmpty else { return }
        isChangingTimezone = true; defer { isChangingTimezone = false }

        let cmd = await service.timezoneChangeCmd(timezone: safeTZ)
        let out = await ssh(cmd)
        if !out.isEmpty {
            currentTimezone = safeTZ; isEditingTimezone = false
            logActivity(type: "ssh_command", description: "Changed timezone to \(safeTZ)")
        }
    }

    func saveSSHConfig() async {
        guard guardOperation("sshConfig") else { return }
        defer { endOperation("sshConfig") }
        isSavingSSH = true; defer { isSavingSSH = false }

        let cmd = await service.sshConfigSaveCmd(permitRoot: permitRootLogin, passwordAuth: passwordAuthEnabled)
        let out = await ssh(cmd)
        if out.contains("OK") {
            sshMsg = ("SSH config saved & reloaded", true)
            logActivity(type: "ssh_command", description: "Updated SSH config (root=\(permitRootLogin), pwd=\(passwordAuthEnabled))")
        } else {
            sshMsg = ("Failed to save", false)
        }
        clearMsg(after: 5) { self.sshMsg = nil }
    }

    func addUser() async {
        guard guardOperation("addUser") else { return }
        defer { endOperation("addUser") }
        guard !newUsername.isEmpty, !newUserPassword.isEmpty else { return }
        let safeUser = ShellSanitizer.sanitizeIdentifier(newUsername)
        guard !safeUser.isEmpty else { userMsg = ("Invalid username", false); return }
        isAddingUser = true; defer { isAddingUser = false }

        let cmd = await service.userAddCmd(username: safeUser, password: newUserPassword)
        let out = await ssh(cmd)
        if out.contains("OK") {
            userMsg = ("User '\(safeUser)' created", true)
            newUsername = ""; newUserPassword = ""
            logActivity(type: "ssh_command", description: "Created user: \(safeUser)")
            await loadUsers()
        } else {
            userMsg = ("Failed: \(out)", false)
        }
        clearMsg(after: 5) { self.userMsg = nil }
    }

    func deleteUser(_ name: String) async {
        guard guardOperation("deleteUser.\(name)") else { return }
        defer { endOperation("deleteUser.\(name)") }
        let cmd = await service.userDeleteCmd(username: name)
        let out = await ssh(cmd)
        if !out.lowercased().contains("error") {
            logActivity(type: "ssh_command", description: "Deleted user: \(name)")
        }
        await loadUsers()
    }

    func toggleService(_ name: String, start: Bool) async {
        guard guardOperation("svc.\(name)") else { return }
        defer { endOperation("svc.\(name)") }
        operatingServices.insert(name)
        defer { operatingServices.remove(name) }
        let op = start ? "start" : "stop"
        let cmd = await service.serviceControlCmd(initSystem: initSystem, operation: op, service: name)
        let _ = await ssh(cmd)
        logActivity(type: "ssh_command", description: "\(op.capitalized) service: \(name)")
        await loadServices()
    }

    func restartService(_ name: String) async {
        guard guardOperation("svc.\(name)") else { return }
        defer { endOperation("svc.\(name)") }
        operatingServices.insert(name)
        defer { operatingServices.remove(name) }
        let cmd = await service.serviceControlCmd(initSystem: initSystem, operation: "restart", service: name)
        let _ = await ssh(cmd)
        logActivity(type: "ssh_command", description: "Restarted service: \(name)")
        await loadServices()
    }

    func restartSSH() async {
        guard guardOperation("restartSSH") else { return }
        defer { endOperation("restartSSH") }
        let cmd = await service.serviceRestartSSHCmd(initSystem: initSystem)
        let _ = await ssh(cmd)
        logActivity(type: "ssh_command", description: "Restarted SSH daemon")
    }

    func checkUpdates() async {
        await checkUpdatesWithList()
    }

    func upgradeSystem() async {
        guard guardOperation("upgrade") else { return }
        defer { endOperation("upgrade") }
        isUpgrading = true; defer { isUpgrading = false }

        let cmd = await service.updateUpgradeCmd(pkgManager: pkgManager)
        let out = await ssh(cmd)
        if out.contains("OK") {
            updateMessage = ("Upgrade complete", true)
        } else {
            updateMessage = (out.isEmpty ? "Upgrade complete" : out, true)
        }
        logActivity(type: "ssh_command", description: "System upgrade executed")
        await checkUpdatesWithList()
        clearMsg(after: 8) { self.updateMessage = nil }
    }

    // MARK: - Helpers

    func validatePwd(_ pwd: String, _ confirm: String, setMsg: @escaping ((String, Bool)?) -> Void) -> Bool {
        validatePassword(pwd, confirm, setMsg: setMsg)
    }

    func clearMsg(after seconds: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { action() }
    }

    // MARK: - Activity Logging (NOTE.md §10)

    func logActivity(type: String, description: String) {
        Task {
            guard let token = await AevonXCoreBridge.AuthService.shared.getToken() else { return }
            let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
            _ = await APIBridge.shared.logActivityAsync(
                baseURL: baseURL, token: token,
                type: type, description: description,
                context: "server_settings"
            )
        }
    }
}
