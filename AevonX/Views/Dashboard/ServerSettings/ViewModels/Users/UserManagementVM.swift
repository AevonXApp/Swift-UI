//
//  UserManagementVM.swift
//  AevonX
//
//  ViewModel for advanced user management — sessions, groups, sudo, lock.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class UserManagementVM: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - Sessions
    @Published var activeSessions: [ActiveSession] = []

    // MARK: - Groups
    @Published var groups: [SystemGroup] = []
    @Published var newGroupName = ""

    // MARK: - Sudo
    @Published var sudoUsers: [String] = []

    // MARK: - Password Status
    @Published var passwordStatuses: [PasswordStatus] = []

    // MARK: - Disk Usage
    @Published var diskUsages: [UserDiskUsage] = []

    // MARK: - Login History
    @Published var loginHistory: [SSHRecentLogin] = []

    // MARK: - State
    @Published var isLoading = true
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

    // MARK: - Load

    func loadAll() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        let cmd = await service.userAdvancedSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)
        parseSnapshot(sections)
    }

    // MARK: - Session Actions

    func killSession(_ terminal: String) async {
        let cmd = await service.userKillSessionCmd(terminal: terminal)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.sessionTerminated, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.sessionTerminateFailed, false)
        }
    }

    // MARK: - Group Actions

    func addGroup() async {
        guard !newGroupName.isEmpty else { return }
        let cmd = await service.userGroupAddCmd(group: newGroupName)
        let out = await ssh(cmd)
        if out.contains("OK") {
            newGroupName = ""
            showMsg(L10n.ServerSettings.groupCreated, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.groupCreateFailed, false)
        }
    }

    func deleteGroup(_ name: String) async {
        let cmd = await service.userGroupDeleteCmd(group: name)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.groupDeleted, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.groupDeleteFailed, false)
        }
    }

    func addUserToGroup(username: String, group: String) async {
        let cmd = await service.userAddToGroupCmd(username: username, group: group)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.userAddedToGroup, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.userAddToGroupFailed, false)
        }
    }

    func removeUserFromGroup(username: String, group: String) async {
        let cmd = await service.userRemoveFromGroupCmd(username: username, group: group)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.userRemovedFromGroup, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.userRemoveFromGroupFailed, false)
        }
    }

    // MARK: - Sudo Actions

    func grantSudo(_ username: String) async {
        let cmd = await service.userGrantSudoCmd(username: username)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.sudoGranted, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.sudoGrantFailed, false)
        }
    }

    func revokeSudo(_ username: String) async {
        let cmd = await service.userRevokeSudoCmd(username: username)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.sudoRevoked, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.sudoRevokeFailed, false)
        }
    }

    // MARK: - Shell / Lock Actions

    func changeShell(username: String, shell: String) async {
        let cmd = await service.userChangeShellCmd(username: username, shell: shell)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.shellChanged, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.shellChangeFailed, false)
        }
    }

    func lockUser(_ username: String) async {
        let cmd = await service.userLockCmd(username: username)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.userLocked, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.userLockFailed, false)
        }
    }

    func unlockUser(_ username: String) async {
        let cmd = await service.userUnlockCmd(username: username)
        let out = await ssh(cmd)
        if out.contains("OK") {
            showMsg(L10n.ServerSettings.userUnlocked, true)
            await loadAll()
        } else {
            showMsg(L10n.ServerSettings.userUnlockFailed, false)
        }
    }

    // MARK: - Helpers

    func isSudoUser(_ username: String) -> Bool {
        sudoUsers.contains(username)
    }

    private func showMsg(_ text: String, _ success: Bool) {
        saveMsg = (text, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.saveMsg = nil }
    }
}
