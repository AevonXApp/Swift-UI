//
//  SiteCloningViewModel.swift
//  AevonX
//
//  ViewModel for site cloning and migration — delegates to SiteCloningService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class SiteCloningViewModel: ObservableObject {
    @Published var targetDomain = ""
    @Published var isCloning = false
    @Published var cloningProgress = ""
    @Published var lastCloneResult: CloneResultItem?
    @Published var exportPath: String?
    @Published var includeDBInExport = true

    let serverId: String
    let domain: String
    let docRoot: String
    private let service = SiteCloningService.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func cloneSite() async {
        guard !targetDomain.isEmpty else { return }
        isCloning = true; cloningProgress = "Cloning files..."
        defer { isCloning = false; cloningProgress = "" }
        do {
            let result = try await service.cloneSite(sourceDomain: domain, targetDomain: targetDomain, sourceDocRoot: docRoot, serverId: serverId)
            lastCloneResult = CloneResultItem(domain: result.targetDomain, docRoot: result.targetDocRoot, size: result.size)
            GlobalToastManager.shared.showSuccess("Site cloned to \(result.targetDomain)")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func createStaging() async {
        isCloning = true; cloningProgress = "Creating staging..."
        defer { isCloning = false; cloningProgress = "" }
        do {
            let result = try await service.createStaging(domain: domain, docRoot: docRoot, serverId: serverId)
            lastCloneResult = CloneResultItem(domain: result.targetDomain, docRoot: result.targetDocRoot, size: result.size)
            GlobalToastManager.shared.showSuccess("Staging created: staging.\(domain)")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func exportForMigration() async {
        isCloning = true; cloningProgress = "Exporting for migration..."
        defer { isCloning = false; cloningProgress = "" }
        do {
            exportPath = try await service.exportForMigration(domain: domain, docRoot: docRoot, includeDB: includeDBInExport, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Migration export ready")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }
}

// MARK: - UI Models

struct CloneResultItem: Identifiable {
    let id = UUID()
    let domain: String
    let docRoot: String
    let size: String
}
