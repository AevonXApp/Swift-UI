//
//  PerformanceTuningViewModel.swift
//  AevonX
//
//  ViewModel for performance tuning — delegates to SitePerformanceTuningService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class PerformanceTuningViewModel: ObservableObject {
    @Published var directives: [DirectiveItem] = []
    @Published var workerInfo: WorkerInfoItem?
    @Published var isLoading = false
    @Published var selectedPreset = "balanced"

    let serverId: String
    let domain: String
    private let service = SitePerformanceTuningService.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadSettings() async {
        isLoading = true; defer { isLoading = false }
        do {
            let settings = try await service.readSettings(domain: domain, serverId: serverId)
            directives = settings.map { DirectiveItem(name: $0.name, value: $0.value, isSet: $0.isSet) }
            let info = try await service.readNginxWorkerInfo(serverId: serverId)
            workerInfo = WorkerInfoItem(cpuCores: info.cpuCores, workerProcesses: info.workerProcesses, workerConnections: info.workerConnections)
        } catch { directives = [] }
    }

    func applyDirective(_ name: String, value: String) async {
        isLoading = true; defer { isLoading = false }
        do {
            try await service.applySetting(directive: name, value: value, domain: domain, serverId: serverId)
            if let idx = directives.firstIndex(where: { $0.name == name }) {
                directives[idx] = DirectiveItem(name: name, value: value, isSet: true)
            }
            GlobalToastManager.shared.showSuccess("\(name) updated")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func applyPreset() async {
        isLoading = true; defer { isLoading = false }
        do {
            try await service.applyPreset(selectedPreset, domain: domain, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(selectedPreset.capitalized) preset applied")
            await loadSettings()
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func toggleGzip(_ enable: Bool) async {
        do {
            try await service.toggleGzip(enable: enable, domain: domain, serverId: serverId)
            GlobalToastManager.shared.showSuccess(enable ? "Gzip enabled" : "Gzip disabled")
            await loadSettings()
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }
}

// MARK: - UI Models

struct DirectiveItem: Identifiable {
    let id: String
    let name: String
    var value: String
    let isSet: Bool

    init(name: String, value: String, isSet: Bool) {
        self.id = name
        self.name = name
        self.value = value
        self.isSet = isSet
    }

    var category: String {
        if name.contains("gzip") || name.contains("http2") { return "Compression" }
        if name.contains("timeout") || name.contains("keepalive") { return "Timeouts" }
        if name.contains("buffer") || name.contains("body_size") { return "Buffers" }
        return "Other"
    }
}

struct WorkerInfoItem {
    let cpuCores: Int
    let workerProcesses: String
    let workerConnections: Int
}
