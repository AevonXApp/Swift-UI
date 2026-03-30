//
//  ServerSettingsVM+Load.swift
//  AevonX
//
//  Data loading methods for ServerSettingsViewModel.
//  All commands come from ServerManagementService (Bridge-backed).
//

import Foundation

extension ServerSettingsViewModel {

    func loadServerInfo() async {
        guard isConnected else { isLoadingInfo = false; return }
        isLoadingInfo = true
        defer { isLoadingInfo = false }

        let cmd = await service.serverInfoSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)

        hostname = sections["HOSTNAME"] ?? ""
        newHostname = hostname
        osInfo = sections["OS"] ?? ""
        kernelVersion = sections["KERNEL"] ?? ""
        architecture = sections["ARCH"] ?? ""
        serverUptime = sections["UPTIME"] ?? ""
        currentTimezone = sections["TIMEZONE"] ?? ""
        selectedTimezone = currentTimezone
        cpuModel = sections["CPU"] ?? ""
        totalRAM = sections["RAM"] ?? ""

        let swpStr = sections["SWAP"] ?? ""
        parseSwap(swpStr)
    }

    func loadNetworkInfo() async {
        guard isConnected else { return }
        let cmd = await service.networkInfoSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)

        publicIP = sections["PUBIP"] ?? ""
        privateIP = sections["PRIVIP"] ?? ""
        defaultGateway = sections["GATEWAY"] ?? ""
        dnsServers = sections["DNS"] ?? ""
    }

    func loadSSHConfig() async {
        guard isConnected else { isLoadingSSH = false; return }
        isLoadingSSH = true
        defer { isLoadingSSH = false }

        let cmd = await service.sshConfigSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)

        let rootVal = (sections["ROOTLOGIN"] ?? "").lowercased()
        permitRootLogin = (rootVal == "yes" || rootVal == "without-password" || rootVal == "prohibit-password")

        let pwdVal = (sections["PWDAUTH"] ?? "").lowercased()
        passwordAuthEnabled = (pwdVal == "yes")

        sshPort = sections["PORT"] ?? "22"
        if sshPort.isEmpty { sshPort = "22" }

        maxAuthTries = sections["MAXAUTH"] ?? "6"
        if maxAuthTries.isEmpty { maxAuthTries = "6" }

        authorizedKeysCount = Int(sections["KEYS"] ?? "0") ?? 0
    }

    func loadUsers() async {
        guard isConnected else { isLoadingUsers = false; return }
        isLoadingUsers = true
        defer { isLoadingUsers = false }

        let cmd = await service.usersSnapshotCmd()
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)

        let usersOutput = sections["USERS"] ?? ""
        let lastOutput = sections["LASTLOG"] ?? ""

        var lastLogins: [String: String] = [:]
        for line in lastOutput.split(separator: "\n") {
            let parts = line.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                let user = String(parts[0])
                let rest = String(parts[1]).trimmingCharacters(in: .whitespaces)
                lastLogins[user] = rest.hasPrefix("**Never") ? "Never" : String(rest.prefix(30))
            }
        }

        systemUsers = usersOutput.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count == 3 else { return nil }
            let name = String(parts[0])
            guard name != "nobody" && name != "nfsnobody" else { return nil }
            return (name: name, uid: String(parts[1]), shell: String(parts[2]), lastLogin: lastLogins[name] ?? "Unknown")
        }
    }

    func loadServices() async {
        guard isConnected else { isLoadingServices = false; return }
        isLoadingServices = true
        defer { isLoadingServices = false }

        let cmd = await service.servicesFullListCmd(initSystem: initSystem)
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)

        // Parse enabled states into lookup
        let enabledOutput = sections["ENABLED"] ?? ""
        var enabledMap: [String: ServiceEnabledState] = [:]
        for line in enabledOutput.split(separator: "\n") {
            let parts = line.split(separator: "|")
            guard parts.count >= 2 else { continue }
            let name = String(parts[0])
            let state = ServiceEnabledState(rawValue: String(parts[1])) ?? .unknown
            enabledMap[name] = state
        }

        // Parse unit list
        let unitsOutput = sections["UNITS"] ?? ""
        allServices = unitsOutput.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count >= 3 else { return nil }
            let rawName = String(parts[0])
            let active = ServiceActiveState(rawValue: String(parts[1])) ?? .inactive
            let sub = String(parts[2])
            let enabled = enabledMap[rawName] ?? .unknown
            return ServiceInfo(name: rawName, activeState: active, subState: sub, enabledState: enabled)
        }
    }

    func loadDisk() async {
        guard isConnected else { isLoadingDisk = false; return }
        isLoadingDisk = true
        defer { isLoadingDisk = false }

        let cmd = await service.diskSnapshotCmd()
        let output = await ssh(cmd)

        diskPartitions = output.split(separator: "\n").compactMap { line in
            let cols = String(line).split(separator: " ").map(String.init)
            guard cols.count >= 5 else { return nil }
            let pct = Int(cols[4].replacingOccurrences(of: "%", with: "")) ?? 0
            return (mount: cols[0], size: cols[1], used: cols[2], avail: cols[3], percent: pct)
        }
    }

    // MARK: - Private

    private func parseSwap(_ swpStr: String) {
        let parts = swpStr.split(separator: "|")
        if parts.count == 2 {
            let totalMB = Int(parts[0]) ?? 0
            let usedMB = Int(parts[1]) ?? 0
            swapEnabled = totalMB > 0
            swapTotal = totalMB >= 1024 ? String(format: "%.1f GB", Double(totalMB) / 1024.0) : "\(totalMB) MB"
            swapUsed = usedMB >= 1024 ? String(format: "%.1f GB", Double(usedMB) / 1024.0) : "\(usedMB) MB"
        }
    }
}
