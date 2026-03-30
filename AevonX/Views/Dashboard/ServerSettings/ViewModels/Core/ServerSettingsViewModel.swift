//
//  ServerSettingsViewModel.swift
//  AevonX
//
//  Coordinator ViewModel for server settings.
//  Uses ServerManagementService for commands + SSHBridge for execution.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class ServerSettingsViewModel: ObservableObject {
    let serverId: String
    let service = ServerManagementService.shared

    // MARK: - Connection Guard
    var isConnected: Bool {
        SSHBridge.shared.isConnected(serverID: serverId)
    }

    // Tracks in-flight operations to prevent concurrent SSH calls
    @Published var operationsInFlight: Set<String> = []

    func guardOperation(_ key: String) -> Bool {
        guard isConnected else { return false }
        guard !operationsInFlight.contains(key) else { return false }
        operationsInFlight.insert(key)
        return true
    }

    func endOperation(_ key: String) {
        operationsInFlight.remove(key)
    }

    // MARK: - Server Info
    @Published var hostname = ""
    @Published var osInfo = ""
    @Published var kernelVersion = ""
    @Published var architecture = ""
    @Published var serverUptime = ""
    @Published var currentTimezone = ""
    @Published var cpuModel = ""
    @Published var totalRAM = ""
    @Published var isLoadingInfo = true

    // MARK: - Network
    @Published var publicIP = ""
    @Published var privateIP = ""
    @Published var defaultGateway = ""
    @Published var dnsServers = ""

    // MARK: - Disk
    @Published var diskPartitions: [(mount: String, size: String, used: String, avail: String, percent: Int)] = []
    @Published var isLoadingDisk = true

    // MARK: - Swap
    @Published var swapTotal = ""
    @Published var swapUsed = ""
    @Published var swapEnabled = false

    // MARK: - SSH Security
    @Published var permitRootLogin = false
    @Published var passwordAuthEnabled = false
    @Published var sshPort = "22"
    @Published var authorizedKeysCount = 0
    @Published var maxAuthTries = "6"
    @Published var isLoadingSSH = true
    @Published var isSavingSSH = false
    @Published var sshMsg: (String, Bool)? = nil

    // MARK: - Users
    @Published var systemUsers: [(name: String, uid: String, shell: String, lastLogin: String)] = []
    @Published var isLoadingUsers = true
    @Published var newUsername = ""
    @Published var newUserPassword = ""
    @Published var isAddingUser = false
    @Published var userMsg: (String, Bool)? = nil

    // MARK: - Services
    @Published var allServices: [ServiceInfo] = []
    @Published var isLoadingServices = true
    @Published var serviceSearchText = ""
    @Published var serviceFilter: ServiceFilter = .all
    @Published var selectedServiceForLogs: String? = nil
    @Published var serviceLogs = ""
    @Published var isLoadingLogs = false
    @Published var operatingServices: Set<String> = []

    // MARK: - Updates
    @Published var updatesAvailable = 0
    @Published var securityUpdatesCount = 0
    @Published var availablePackages: [PackageUpdate] = []
    @Published var isCheckingUpdates = false
    @Published var isUpgrading = false
    @Published var updatingPackages: Set<String> = []
    @Published var updateMessage: (String, Bool)? = nil

    // MARK: - Passwords
    @Published var rootNewPwd = ""
    @Published var rootConfirmPwd = ""
    @Published var isChangingRoot = false
    @Published var rootMsg: (String, Bool)? = nil

    @Published var mysqlNewPwd = ""
    @Published var mysqlConfirmPwd = ""
    @Published var isChangingMySQL = false
    @Published var mysqlMsg: (String, Bool)? = nil

    @Published var pgNewPwd = ""
    @Published var pgConfirmPwd = ""
    @Published var isChangingPG = false
    @Published var pgMsg: (String, Bool)? = nil

    // MARK: - Hostname/Timezone Editing
    @Published var newHostname = ""
    @Published var isEditingHostname = false
    @Published var isChangingHostname = false
    @Published var hostnameMsg: (String, Bool)? = nil

    @Published var selectedTimezone = ""
    @Published var isEditingTimezone = false
    @Published var isChangingTimezone = false
    @Published var serverTimezones: [String] = []
    @Published var isLoadingTimezones = false

    // Server profile (detected once)
    var initSystem = "systemd"
    var pkgManager = "apt"

    let commonTimezones = [
        "UTC", "US/Eastern", "US/Central", "US/Mountain", "US/Pacific",
        "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Moscow",
        "Asia/Tokyo", "Asia/Shanghai", "Asia/Kolkata", "Asia/Dubai", "Asia/Riyadh",
        "Australia/Sydney", "Pacific/Auckland", "America/Sao_Paulo", "Africa/Cairo"
    ]

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - SSH Helper

    func ssh(_ cmd: String) async -> String {
        guard !cmd.isEmpty else { return "" }
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: cmd)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Load All

    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadServerInfo() }
            group.addTask { await self.loadNetworkInfo() }
            group.addTask { await self.loadDisk() }
            group.addTask { await self.loadUsers() }
        }
    }
}
