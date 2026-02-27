//
//  SiteSecurityViewModel.swift
//  AevonX
//
//  ViewModel for per-site security — delegates to SiteSecurityService
//

import SwiftUI
import Combine
import AevonXCore

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
    private let service = SiteSecurityService.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func loadSecurityStatus() async {
        do {
            let statuses = try await service.detectSecurityStatus(domain: domain, docRoot: docRoot, serverId: serverId)
            securityStatuses = statuses.map { status in
                SiteSecurityStatus(
                    feature: SiteSecurityFeature(rawValue: status.feature) ?? .directoryListing,
                    enabled: status.enabled,
                    issues: []
                )
            }
        } catch {
            securityStatuses = []
        }
    }

    func toggleHotlinkProtection(enable: Bool) async {
        isScanning = true; scanProgress = "Toggling hotlink protection..."
        defer { isScanning = false; scanProgress = "" }
        do {
            try await service.toggleHotlinkProtection(enable: enable, domain: domain, serverId: serverId)
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
            try await service.toggleSensitiveFilesBlock(enable: enable, domain: domain, serverId: serverId)
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
            let results = try await service.runPermissionAudit(docRoot: docRoot, serverId: serverId)
            permissionResults = results.map { PermissionAuditResult(path: $0.path, permissions: $0.permissions, owner: $0.owner, severity: $0.permissions.contains("7") ? .critical : .warning) }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    func fixPermissions() async {
        isScanning = true; scanProgress = "Fixing permissions..."
        defer { isScanning = false; scanProgress = "" }
        do {
            try await service.fixPermissions(docRoot: docRoot, serverId: serverId)
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
            let results = try await service.runMalwareScan(docRoot: docRoot, serverId: serverId)
            malwareResults = results.map { MalwareScanResult(filePath: $0.filePath, matchedPattern: "suspicious", lineNumber: $0.lineNumber, lineContent: $0.lineContent, severity: .critical) }
            if results.isEmpty {
                GlobalToastManager.shared.showSuccess("No suspicious code found!")
            }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }
}
