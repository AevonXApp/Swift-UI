//
//  SiteSecurityViewModel.swift
//  AevonX
//
//  ViewModel for per-site security — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class SiteSecurityViewModel: ObservableObject {
    @Published var securityStatuses: [SiteSecurityStatus] = []
    @Published var permissionResults: [PermissionAuditResult] = []
    @Published var malwareResults: [MalwareScanResult] = []
    @Published var isScanning = false
    @Published var scanProgress = ""

    let serverId: String
    let domain: String
    let docRoot: String
    private let bridge = WebsitesBridge.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func loadSecurityStatus() async {
        do {
            let cmd = bridge.securityScanCmd(domain: domain, docRoot: docRoot)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            let parsedJSON = bridge.parseSecurityScan(output: result)

            if let data = parsedJSON.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               resp["success"] as? Bool == true,
               let statuses = resp["data"] as? [[String: Any]] {
                securityStatuses = statuses.compactMap { dict in
                    guard let feature = dict["feature"] as? String else { return nil }
                    return SiteSecurityStatus(
                        feature: SiteSecurityFeature(rawValue: feature) ?? .directoryListing,
                        enabled: dict["enabled"] as? Bool ?? false,
                        issues: []
                    )
                }
            }
        } catch {
            securityStatuses = []
        }
    }

    func toggleHotlinkProtection(enable: Bool) async {
        isScanning = true; scanProgress = "Toggling hotlink protection..."
        defer { isScanning = false; scanProgress = "" }
        do {
            let configPath = "/etc/nginx/sites-available/\(domain)"
            let cmd = bridge.toggleHotlinkCmd(enable: enable, domain: domain, configPath: configPath)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess(enable ? "Hotlink protection enabled" : "Hotlink protection disabled")
            await loadSecurityStatus()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func toggleSensitiveFilesBlock(enable: Bool) async {
        isScanning = true; scanProgress = "Configuring sensitive files block..."
        defer { isScanning = false; scanProgress = "" }
        do {
            let cmd = bridge.toggleSensitiveBlockCmd(enable: enable, domain: domain)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess("Sensitive files block applied")
            await loadSecurityStatus()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func runPermissionAudit() async {
        isScanning = true; scanProgress = "Auditing file permissions..."
        defer { isScanning = false; scanProgress = "" }
        do {
            let cmd = bridge.permissionAuditCmd(docRoot: docRoot)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            let parsedJSON = bridge.parsePermissionAudit(output: result)

            if let data = parsedJSON.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               resp["success"] as? Bool == true,
               let results = resp["data"] as? [[String: Any]] {
                permissionResults = results.compactMap { dict in
                    guard let path = dict["path"] as? String,
                          let perms = dict["permissions"] as? String else { return nil }
                    let owner = dict["owner"] as? String ?? ""
                    return PermissionAuditResult(
                        path: path,
                        permissions: perms,
                        owner: owner,
                        severity: perms.contains("7") ? .critical : .warning
                    )
                }
            }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func fixPermissions() async {
        isScanning = true; scanProgress = "Fixing permissions..."
        defer { isScanning = false; scanProgress = "" }
        do {
            let cmd = bridge.fixPermissionsCmd(docRoot: docRoot)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            GlobalToastManager.shared.showSuccess("Permissions fixed: dirs=755, files=644, owner=www-data")
            await runPermissionAudit()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func runMalwareScan() async {
        isScanning = true; scanProgress = "Scanning for malicious code..."
        defer { isScanning = false; scanProgress = "" }
        do {
            let cmd = bridge.malwareScanCmd(docRoot: docRoot)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            let parsedJSON = bridge.parseMalwareScan(output: result)

            if let data = parsedJSON.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               resp["success"] as? Bool == true,
               let results = resp["data"] as? [[String: Any]] {
                malwareResults = results.compactMap { dict in
                    guard let filePath = dict["file_path"] as? String else { return nil }
                    return MalwareScanResult(
                        filePath: filePath,
                        matchedPattern: "suspicious",
                        lineNumber: dict["line_number"] as? Int ?? 0,
                        lineContent: dict["line_content"] as? String ?? "",
                        severity: .critical
                    )
                }
                if results.isEmpty {
                    GlobalToastManager.shared.showSuccess("No suspicious code found!")
                }
            }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }
}
