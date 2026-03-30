//
//  ServerSettingsVM+Updates.swift
//  AevonX
//
//  Update management: check with list, single package, security-only, timezone.
//

import Foundation

extension ServerSettingsViewModel {

    func checkUpdatesWithList() async {
        guard guardOperation("checkUpdatesWithList") else { return }
        defer { endOperation("checkUpdatesWithList") }
        isCheckingUpdates = true
        defer { isCheckingUpdates = false }

        let cmd = await service.updateCheckWithListCmd(pkgManager: pkgManager)
        let output = await ssh(cmd)
        let sections = await service.parseSections(output)

        let listOutput = sections["LIST"] ?? ""
        let secCount = Int((sections["SECURITY"] ?? "0").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        securityUpdatesCount = secCount

        availablePackages = parsePackageList(listOutput, pkgManager: pkgManager)
        updatesAvailable = availablePackages.count
    }

    func updatePackage(_ name: String) async {
        guard guardOperation("updatePkg.\(name)") else { return }
        defer { endOperation("updatePkg.\(name)") }
        updatingPackages.insert(name)
        defer { updatingPackages.remove(name) }

        let cmd = await service.updatePackageCmd(pkgManager: pkgManager, package: name)
        let out = await ssh(cmd)
        if out.contains("OK") {
            logActivity(type: "ssh_command", description: "Updated package: \(name)")
            await checkUpdatesWithList()
        } else {
            updateMessage = ("Failed to update \(name)", false)
            clearMsg(after: 5) { self.updateMessage = nil }
        }
    }

    func updateSecurityOnly() async {
        guard guardOperation("updateSecurity") else { return }
        defer { endOperation("updateSecurity") }
        isUpgrading = true
        defer { isUpgrading = false }

        let cmd = await service.updateSecurityOnlyCmd(pkgManager: pkgManager)
        let out = await ssh(cmd)
        if out.contains("OK") {
            updateMessage = ("Security updates applied", true)
            logActivity(type: "ssh_command", description: "Security-only upgrade executed")
        } else {
            updateMessage = ("Security update failed", false)
        }
        await checkUpdatesWithList()
        clearMsg(after: 8) { self.updateMessage = nil }
    }

    func loadTimezones() async {
        guard isConnected, serverTimezones.isEmpty else { return }
        isLoadingTimezones = true
        defer { isLoadingTimezones = false }

        let cmd = await service.timezoneListCmd()
        let output = await ssh(cmd)
        serverTimezones = output.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }

    // MARK: - Package List Parsing

    private func parsePackageList(_ output: String, pkgManager: String) -> [PackageUpdate] {
        output.split(separator: "\n").compactMap { line in
            parsePackageLine(String(line), pkgManager: pkgManager)
        }
    }

    private func parsePackageLine(_ line: String, pkgManager: String) -> PackageUpdate? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        switch pkgManager {
        case "apt":
            return parseAptLine(trimmed)
        case "yum", "dnf":
            return parseYumLine(trimmed)
        case "apk":
            return parseApkLine(trimmed)
        default:
            return nil
        }
    }

    private func parseAptLine(_ line: String) -> PackageUpdate? {
        // Format: package/source version arch [upgradable from: old_version]
        let parts = line.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        let nameSource = String(parts[0]).split(separator: "/")
        guard !nameSource.isEmpty else { return nil }
        let name = String(nameSource[0])
        let source = nameSource.count > 1 ? String(nameSource[1]) : ""
        let version = String(parts[1])
        let isSecurity = line.lowercased().contains("security")
        var oldVersion = ""
        if let fromIdx = parts.firstIndex(where: { $0 == "from:" }), fromIdx + 1 < parts.count {
            oldVersion = String(parts[fromIdx + 1]).replacingOccurrences(of: "]", with: "")
        }
        return PackageUpdate(id: name, name: name, currentVersion: oldVersion, availableVersion: version, isSecurity: isSecurity, source: source)
    }

    private func parseYumLine(_ line: String) -> PackageUpdate? {
        // Format: package.arch    version    repo
        let parts = line.split(whereSeparator: { $0.isWhitespace })
        guard parts.count >= 2 else { return nil }
        let nameArch = String(parts[0]).split(separator: ".")
        let name = nameArch.dropLast().joined(separator: ".")
        guard !name.isEmpty else { return nil }
        let version = String(parts[1])
        let source = parts.count >= 3 ? String(parts[2]) : ""
        return PackageUpdate(id: name, name: name, currentVersion: "", availableVersion: version, isSecurity: false, source: source)
    }

    private func parseApkLine(_ line: String) -> PackageUpdate? {
        // Format: package-version < new-version
        let parts = line.split(separator: "<")
        guard parts.count >= 1 else { return nil }
        let left = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let name = left.split(separator: "-").dropLast().joined(separator: "-")
        guard !name.isEmpty else { return nil }
        let right = parts.count >= 2 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
        return PackageUpdate(id: name, name: name, currentVersion: "", availableVersion: right, isSecurity: false, source: "")
    }
}
