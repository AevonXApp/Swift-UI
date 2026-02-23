//
//  FTPViewModel.swift
//  AevonX
//
//  ViewModel for the FTP Management tab
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class FTPViewModel: ObservableObject {
    let serverId: String
    
    // Data
    @Published var users: [FTPUser] = []
    @Published var serverInfo: FTPServerInfo = FTPServerInfo()
    @Published var logEntries: [FTPLogEntry] = []
    
    // State
    @Published var isLoading = true
    @Published var isInstalling = false
    @Published var isLoadingLogs = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var logSearchText = ""
    @Published var selectedLogType: FTPLogType? = nil
    
    // Sheets
    @Published var showAddSheet = false
    @Published var showSettingsSheet = false
    @Published var editingUser: FTPUser?
    
    // Install output
    @Published var installOutput: String?
    @Published var showInstallResult = false
    
    // Message
    @Published var toastMessage: (String, Bool)?
    
    var filteredUsers: [FTPUser] {
        guard !searchText.isEmpty else { return users }
        return users.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.documentRoot.localizedCaseInsensitiveContains(searchText) ||
            $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var activeUsersCount: Int { users.filter { $0.status == .active }.count }
    var inactiveUsersCount: Int { users.filter { $0.status == .inactive }.count }
    
    var filteredLogs: [FTPLogEntry] {
        var result = logEntries
        if let type = selectedLogType {
            result = result.filter { $0.type == type }
        }
        if !logSearchText.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(logSearchText) }
        }
        return result
    }
    
    var logTypeCounts: [FTPLogType: Int] {
        var counts: [FTPLogType: Int] = [:]
        for entry in logEntries {
            counts[entry.type, default: 0] += 1
        }
        return counts
    }
    
    init(serverId: String) {
        self.serverId = serverId
    }
    
    // MARK: - Load
    
    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            serverInfo = try await FTPService.shared.checkInstallation(serverId: serverId)
            if serverInfo.isInstalled {
                users = try await FTPService.shared.listUsers(serverId: serverId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refreshUsers() async {
        do {
            users = try await FTPService.shared.listUsers(serverId: serverId)
        } catch {
            showToast("Failed to refresh: \(error.localizedDescription)", success: false)
        }
    }
    
    // MARK: - Install
    
    func installFTP() async {
        isInstalling = true
        defer { isInstalling = false }
        do {
            let output = try await FTPService.shared.installPureFTPd(serverId: serverId)
            installOutput = output
            showToast("PureFTPd installed successfully", success: true)
            await loadAll()
        } catch {
            showToast("Installation failed: \(error.localizedDescription)", success: false)
        }
    }
    
    // MARK: - Add User
    
    func addUser(_ user: FTPUser) async {
        do {
            try await FTPService.shared.addUser(user, serverId: serverId)
            showToast("User added: \(user.username)", success: true)
            await refreshUsers()
        } catch {
            showToast("Failed: \(error.localizedDescription)", success: false)
        }
    }
    
    // MARK: - Delete User
    
    func deleteUser(_ user: FTPUser) async {
        do {
            try await FTPService.shared.deleteUser(user, serverId: serverId)
            showToast("Deleted: \(user.username)", success: true)
            await refreshUsers()
        } catch {
            showToast("Failed to delete", success: false)
        }
    }
    
    // MARK: - Toggle User
    
    func toggleUser(_ user: FTPUser) async {
        do {
            let enable = user.status == .inactive
            try await FTPService.shared.toggleUser(user, enable: enable, serverId: serverId)
            showToast("\(user.username) \(enable ? "enabled" : "disabled")", success: true)
            await refreshUsers()
        } catch {
            showToast("Failed to toggle", success: false)
        }
    }
    
    // MARK: - Change Password
    
    func changePassword(username: String, newPassword: String) async {
        do {
            try await FTPService.shared.changePassword(username: username, newPassword: newPassword, serverId: serverId)
            showToast("Password changed for \(username)", success: true)
        } catch {
            showToast("Failed to change password", success: false)
        }
    }
    
    // MARK: - Change Port
    
    func changePort(to port: Int) async {
        do {
            try await FTPService.shared.changeFTPPort(to: port, serverId: serverId)
            showToast("FTP port changed to \(port)", success: true)
            serverInfo.port = port
            // Update FTP address
            let components = serverInfo.ftpAddress.components(separatedBy: ":")
            if components.count >= 2 {
                serverInfo.ftpAddress = "\(components[0]):\(components[1]):\(port)"
            }
        } catch {
            showToast("Failed to change port", success: false)
        }
    }
    
    // MARK: - Service Control
    
    func startService() async {
        do {
            try await FTPService.shared.startService(serverId: serverId)
            serverInfo.isRunning = true
            showToast("FTP service started", success: true)
        } catch {
            showToast("Failed to start service", success: false)
        }
    }
    
    func stopService() async {
        do {
            try await FTPService.shared.stopService(serverId: serverId)
            serverInfo.isRunning = false
            showToast("FTP service stopped", success: true)
        } catch {
            showToast("Failed to stop service", success: false)
        }
    }
    
    func restartService() async {
        do {
            try await FTPService.shared.restartService(serverId: serverId)
            serverInfo.isRunning = true
            showToast("FTP service restarted", success: true)
        } catch {
            showToast("Failed to restart service", success: false)
        }
    }
    
    // MARK: - Logs
    
    func loadLogs() async {
        isLoadingLogs = true
        defer { isLoadingLogs = false }
        do {
            logEntries = try await FTPService.shared.getLogs(serverId: serverId)
        } catch {
            logEntries = []
        }
    }
    
    // MARK: - Generate Password
    
    func generatePassword() -> String {
        FTPService.shared.generatePassword()
    }
    
    // MARK: - Helpers
    
    private func showToast(_ msg: String, success: Bool) {
        toastMessage = (msg, success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.toastMessage = nil }
    }
}
