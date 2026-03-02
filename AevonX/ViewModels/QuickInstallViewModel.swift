//
//  QuickInstallViewModel.swift
//  AevonX
//
//  Bridge ViewModel for the Quick Environment Install feature.
//  View → ViewModel → Core (QuickInstallService) → SSHService
//
//  Follows NOTE.md: ViewModel holds @Published state, calls Core services,
//  never contains SSH logic directly.
//

import SwiftUI
import AevonXCore
import Combine

@MainActor
public final class QuickInstallViewModel: ObservableObject {

    // MARK: - Catalog & Presets (read-only)

    let allPackages: [QIPackage] = QuickInstallService.allPackages
    let presets: [QIPreset] = QuickInstallService.presets

    // MARK: - Selection State

    @Published var selections: [QISelection] = []
    @Published var selectedCategory: QICategory? = nil
    @Published var searchText: String = ""

    // MARK: - Server State

    let serverId: String
    /// Set externally from ServerConnectionViewModel.serverProfile
    var serverProfile: ServerProfile?

    @Published var isScanning: Bool = false
    @Published var serverScan: QIServerScan?
    @Published var scanError: String?

    // MARK: - Installation State

    @Published var isInstalling: Bool = false
    @Published var isMinimized: Bool = false
    @Published var isComplete: Bool = false
    @Published var isFailed: Bool = false
    @Published var installerViewModel: AXStepInstallerViewModel?

    /// Background polling task — keeps reading server state.log every 3s
    private var pollingTask: Task<Void, Never>?

    // MARK: - UI Visibility

    @Published var isVisible: Bool = true  // false = fully closed, bubble gone

    // MARK: - Service

    private let service: QuickInstallService

    // MARK: - Init

    public init(serverId: String, profile: ServerProfile? = nil) {
        self.serverId = serverId
        self.serverProfile = profile
        self.service = QuickInstallService()
    }

    // MARK: - Computed: Filtered Packages

    var filteredPackages: [QIPackage] {
        var list = allPackages
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.tagline.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    // MARK: - Computed: Conflict Warnings

    var conflicts: [QIConflict] {
        QuickInstallService.detectConflicts(in: selections)
    }

    var hasConflicts: Bool { !conflicts.isEmpty }

    // MARK: - Computed: Estimated Time

    var estimatedMinutes: Int {
        guard let profile = serverProfile else { return selections.count * 2 }
        return QuickInstallService.estimatedMinutes(for: selections, profile: profile)
    }

    // MARK: - Already Installed

    func isInstalled(_ packageId: String) -> Bool {
        serverScan?.installed[packageId] != nil
    }

    func installedVersion(for packageId: String) -> String? {
        serverScan?.installed[packageId]
    }

    // MARK: - Selection Management

    func isSelected(_ packageId: String) -> Bool {
        selections.contains(where: { $0.packageId == packageId })
    }

    func togglePackage(_ package: QIPackage) {
        if let idx = selections.firstIndex(where: { $0.packageId == package.id }) {
            selections.remove(at: idx)
        } else {
            let version = preferredVersion(for: package)
            selections.append(QISelection(package: package, version: version))
        }
    }

    func updateVersion(for packageId: String, to versionId: String) {
        guard let idx = selections.firstIndex(where: { $0.packageId == packageId }),
              let pkg = allPackages.first(where: { $0.id == packageId }),
              let ver = pkg.versions.first(where: { $0.id == versionId }) else { return }
        let pkgCopy = pkg
        selections[idx] = QISelection(package: pkgCopy, version: ver)
    }

    func removeSelection(_ packageId: String) {
        selections.removeAll(where: { $0.packageId == packageId })
    }

    // MARK: - Preset Application

    func applyPreset(_ preset: QIPreset) {
        selections.removeAll()
        for pair in preset.packageVersionPairs {
            guard let pkg = allPackages.first(where: { $0.id == pair.packageId }),
                  let ver = pkg.versions.first(where: { $0.id == pair.versionId }) ?? pkg.versions.first else { continue }
            selections.append(QISelection(package: pkg, version: ver))
        }
    }

    // MARK: - Server Scan

    func scanServer() async {
        isScanning = true
        scanError = nil
        do {
            serverScan = try await service.scanServer(serverId: serverId)
        } catch {
            scanError = error.localizedDescription
        }
        isScanning = false
    }

    // MARK: - Begin Installation (Resilient Queue)

    func beginInstallation() async {
        CoreLogger.shared.info("beginInstallation() called — \(selections.count) packages selected", module: "QuickInstall")
        guard !selections.isEmpty else { return }

        // If profile wasn't injected yet, detect it now (handles race with capability detection)
        let profile: ServerProfile
        if let existing = serverProfile {
            profile = existing
        } else {
            CoreLogger.shared.info("serverProfile nil — detecting now", module: "QuickInstall")
            let detector = CapabilityDetector(sshService: service.sshService)
            do {
                let detected = try await detector.detect(serverId: serverId)
                serverProfile = detected
                profile = detected
                CoreLogger.shared.info("Auto-detected: \(profile.distro.rawValue)/\(profile.packageManager.rawValue)", module: "QuickInstall")
            } catch {
                CoreLogger.shared.error("Profile detection failed: \(error.localizedDescription)", module: "QuickInstall")
                scanError = "Could not detect server OS. Check your connection."
                return
            }
        }

        CoreLogger.shared.info("Profile: \(profile.distro.rawValue), pkg: \(profile.packageManager.rawValue)", module: "QuickInstall")

        let installed = serverScan?.installed ?? [:]

        // Build ordered Core steps
        let coreSteps = service.buildSteps(
            for: selections,
            profile: profile,
            installedPackages: installed
        )
        CoreLogger.shared.info("Built \(coreSteps.count) steps", module: "QuickInstall")

        // Build install command map: stepTitle → shell command
        var installCommands: [String: String] = [:]
        for step in coreSteps {
            if let cmd = try? service.shellCommand(
                stepTitle: step.title,
                packageId: step.packageId,
                versionId: selections.first(where: { $0.packageId == step.packageId })?.versionId ?? "latest",
                profile: profile
            ) {
                installCommands[step.title] = cmd
            }
        }
        CoreLogger.shared.info("Built \(installCommands.count) shell commands", module: "QuickInstall")

        // Convert to AXInstallStep for the UI
        let axSteps: [AXInstallStep] = coreSteps.map {
            AXInstallStep(title: $0.title, description: $0.description, icon: $0.icon)
        }

        let vm = AXStepInstallerViewModel(steps: axSteps)
        vm.isRunning = true                    // ← set early so UI shows active state
        installerViewModel = vm
        isInstalling = true
        isComplete = false
        isFailed = false

        CoreLogger.shared.info("isInstalling=true, uploading script...", module: "QuickInstall")

        // Build the queue service and script
        let queueService = QuickInstallQueueService(sshService: service.sshService)
        let script = queueService.generateScript(steps: coreSteps, installCommands: installCommands)

        do {
            // Upload script and launch in background (returns instantly)
            try await queueService.uploadAndLaunch(script: script, serverId: serverId)
            CoreLogger.shared.info("Script launched in background on server", module: "QuickInstall")
        } catch {
            CoreLogger.shared.error("uploadAndLaunch failed: \(error.localizedDescription)", module: "QuickInstall")
            isFailed = true
            isInstalling = false
            vm.isRunning = false
            vm.hasFailed = true
            if !vm.steps.isEmpty {
                vm.steps[0].status = .failed(error.localizedDescription)
            }
            return
        }

        // Build lookup: server step ID prefix → AXInstallStep index
        let stepIdToIndex: [String: Int] = Dictionary(
            uniqueKeysWithValues: coreSteps.enumerated().compactMap { (i, step) in
                let sid = "\(step.id.uuidString.prefix(8))_\(step.packageId)"
                return (sid, i)
            }
        )

        // Start polling loop — runs until done/failed/cancelled
        pollingTask = Task { @MainActor in
            var consecutiveErrors = 0
            while !Task.isCancelled {
                do {
                    let state = try await queueService.pollState(serverId: self.serverId)
                    consecutiveErrors = 0
                    self.applyQueueState(state, vm: vm, stepIdToIndex: stepIdToIndex)

                    if state.isDone {
                        let hasFails = state.isDoneWithErrors
                        CoreLogger.shared.info("Install done — hasFails: \(hasFails)", module: "QuickInstall")
                        self.isInstalling = false
                        self.isComplete = !hasFails
                        self.isFailed = hasFails
                        vm.isRunning = false
                        vm.isComplete = !hasFails
                        vm.hasFailed = hasFails
                        Task {
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                            try? await queueService.cleanup(serverId: self.serverId)
                        }
                        break
                    }
                } catch {
                    consecutiveErrors += 1
                    CoreLogger.shared.warning("Poll error #\(consecutiveErrors): \(error.localizedDescription)", module: "QuickInstall")
                    if consecutiveErrors >= 30 {
                        self.isInstalling = false
                        self.isFailed = true
                        vm.hasFailed = true
                        vm.isRunning = false
                        break
                    }
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000) // poll every 3s
            }
        }
    }

    // MARK: - Apply Poll State → AXStepInstallerViewModel

    private func applyQueueState(
        _ state: QIQueueState,
        vm: AXStepInstallerViewModel,
        stepIdToIndex: [String: Int]
    ) {
        for qStep in state.steps {
            guard let idx = stepIdToIndex[qStep.id], idx < vm.steps.count else { continue }
            switch qStep.status {
            case .done:    vm.steps[idx].status = .completed
            case .failed:  vm.steps[idx].status = .failed(qStep.message)
            case .skipped: vm.steps[idx].status = .skipped
            case .running:
                vm.steps[idx].status = .running
                vm.currentStepIndex = idx
            case .pending: break
            }
        }
        // Update live output on the currently running step
        if let currentId = state.currentStepId, currentId != "DONE",
           let idx = stepIdToIndex[currentId], idx < vm.steps.count {
            vm.steps[idx].output = state.recentOutput.isEmpty ? nil : state.recentOutput
        }
    }

    // MARK: - Cancel

    func cancelInstallation() {
        pollingTask?.cancel()
        pollingTask = nil
        let queueService = QuickInstallQueueService(sshService: service.sshService)
        Task {
            try? await queueService.cancelInstall(serverId: serverId)
        }
        isInstalling = false
        isFailed = true
    }

    // MARK: - Minimize / Restore

    func minimize() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isMinimized = true
        }
    }

    func restore() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isMinimized = false
        }
    }

    func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
        pollingTask?.cancel()
    }

    // MARK: - Private Helpers

    private func preferredVersion(for package: QIPackage) -> QIVersion {
        package.versions.first(where: { $0.isRecommended }) ?? package.versions[0]
    }
}

