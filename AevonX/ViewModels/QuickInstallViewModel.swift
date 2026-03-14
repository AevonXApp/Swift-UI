//
//  QuickInstallViewModel.swift
//  AevonX
//
//  Bridge ViewModel for the Quick Environment Install feature.
//  View → ViewModel → Go Core (InfrastructureBridge) → SSH
//
//  Migrated from Swift Core (QuickInstallService) to Go Core.
//  All install logic now flows through AevonXCoreBridge.
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge
import Combine

// MARK: - Bridge Response Models

/// Decode Go Core bridge JSON responses
struct BridgeResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

/// QI models for decoding Go Core JSON — mirroring Go structs
struct BridgeQIPackage: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let icon: String
    let accent_hex: String
    let tagline: String
    let versions: [BridgeQIVersion]
    let conflicts: [String]?
    let dependencies: [String]?
    let requires_arm64: Bool
    let install_order: Int

    static func == (lhs: BridgeQIPackage, rhs: BridgeQIPackage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct BridgeQIVersion: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let is_lts: Bool
    let is_recommended: Bool
    let supported_distros: [String]?
}

struct BridgeQIPreset: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let accent_hex: String
    let tags: [String]
    let packages: [BridgePresetPair]
}

struct BridgePresetPair: Codable {
    let package_id: String
    let version_id: String
}

struct BridgeQIStep: Codable {
    let title: String
    let description: String
    let icon: String
    let package_id: String?
}

struct BridgeQISelection: Codable, Identifiable {
    var id: String { package_id }
    let package_id: String
    let package_name: String
    let version_id: String
    let version_label: String
}

struct BridgeQIConflict: Codable, Identifiable {
    var id: String { "\(package_a_id)_\(package_b_id)" }
    let package_a_id: String
    let package_b_id: String
    let reason: String
}

struct BridgeQueueState: Codable {
    let steps: [BridgeQueueStep]?
    let current_step_id: String?
    let recent_output: String?
    let is_done: Bool
    let is_done_with_errors: Bool
}

struct BridgeQueueStep: Codable {
    let id: String
    let status: String
    let message: String
}

// MARK: - ViewModel

@MainActor
public final class QuickInstallViewModel: ObservableObject {

    // MARK: - Catalog & Presets (loaded from Go Core)

    private(set) var bridgePackages: [BridgeQIPackage] = []
    private(set) var bridgePresets: [BridgeQIPreset] = []

    /// UI-facing accessors
    var allPackageIds: [String] { bridgePackages.map { $0.id } }
    var allPackageCount: Int { bridgePackages.count }

    // MARK: - Selection State

    @Published var selections: [BridgeQISelection] = []
    @Published var selectedCategory: String? = nil
    @Published var searchText: String = ""

    // MARK: - Server State

    let serverId: String
    var serverProfile: ServerProfile?

    @Published var isScanning: Bool = false
    @Published var serverScan: [String: String]? = nil  // packageId → version
    @Published var scanError: String?

    // MARK: - Installation State

    @Published var isInstalling: Bool = false
    @Published var isMinimized: Bool = false
    @Published var isComplete: Bool = false
    @Published var isFailed: Bool = false
    @Published var installerViewModel: AXStepInstallerViewModel?

    private var pollingTask: Task<Void, Never>?

    // MARK: - UI Visibility

    @Published var isVisible: Bool = true

    // MARK: - Bridge

    private let bridge = InfrastructureBridge.shared

    // MARK: - Init

    public init(serverId: String, profile: ServerProfile? = nil) {
        self.serverId = serverId
        self.serverProfile = profile
        loadCatalog()
    }

    // MARK: - Load Catalog from Go Core

    private func loadCatalog() {
        // Load packages
        let pkgJSON = bridge.getPackageCatalog()
        if let data = pkgJSON.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeResponse<[BridgeQIPackage]>.self, from: data),
           let packages = resp.data {
            bridgePackages = packages
        }

        // Load presets
        let presetJSON = bridge.getPresets()
        if let data = presetJSON.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeResponse<[BridgeQIPreset]>.self, from: data),
           let presets = resp.data {
            bridgePresets = presets
        }
    }

    // MARK: - Computed: Filtered Packages

    var filteredPackages: [BridgeQIPackage] {
        var list = bridgePackages
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

    // MARK: - Category helpers

    var categories: [(id: String, name: String, icon: String, count: Int)] {
        let cats: [(String, String)] = [
            ("Web Server", "network"),
            ("Language", "chevron.left.forwardslash.chevron.right"),
            ("Database", "cylinder.split.1x2"),
            ("Cache", "bolt.horizontal"),
            ("DevOps", "shippingbox"),
            ("Security", "lock.shield"),
        ]
        return cats.map { (id, icon) in
            let count = bridgePackages.filter { $0.category == id }.count
            return (id: id, name: id, icon: icon, count: count)
        }
    }

    // MARK: - Computed: Conflict Warnings

    var conflicts: [BridgeQIConflict] {
        guard !selections.isEmpty else { return [] }
        guard let jsonData = try? JSONEncoder().encode(selections),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return [] }
        let resultJSON = bridge.detectConflicts(selectionsJSON: jsonString)
        guard let data = resultJSON.data(using: .utf8),
              let resp = try? JSONDecoder().decode(BridgeResponse<[BridgeQIConflict]>.self, from: data),
              let result = resp.data else { return [] }
        return result
    }

    var hasConflicts: Bool { !conflicts.isEmpty }

    // MARK: - Computed: Estimated Time

    var estimatedMinutes: Int {
        guard let profile = serverProfile else { return selections.count * 2 }
        guard let jsonData = try? JSONEncoder().encode(selections),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return selections.count * 2 }
        let resultJSON = bridge.estimatedMinutes(selectionsJSON: jsonString, pkgMgr: profile.packageManager.rawValue)
        guard let data = resultJSON.data(using: .utf8),
              let resp = try? JSONDecoder().decode(BridgeResponse<Int>.self, from: data),
              let minutes = resp.data else { return selections.count * 2 }
        return minutes
    }

    // MARK: - Already Installed

    func isInstalled(_ packageId: String) -> Bool {
        serverScan?[packageId] != nil
    }

    func installedVersion(for packageId: String) -> String? {
        serverScan?[packageId]
    }

    // MARK: - Selection Management

    func isSelected(_ packageId: String) -> Bool {
        selections.contains(where: { $0.package_id == packageId })
    }

    func togglePackage(_ package: BridgeQIPackage) {
        if let idx = selections.firstIndex(where: { $0.package_id == package.id }) {
            selections.remove(at: idx)
        } else {
            let version = preferredVersion(for: package)
            selections.append(BridgeQISelection(
                package_id: package.id,
                package_name: package.name,
                version_id: version.id,
                version_label: version.label
            ))
        }
    }

    func updateVersion(for packageId: String, to versionId: String) {
        guard let idx = selections.firstIndex(where: { $0.package_id == packageId }),
              let pkg = bridgePackages.first(where: { $0.id == packageId }),
              let ver = pkg.versions.first(where: { $0.id == versionId }) else { return }
        selections[idx] = BridgeQISelection(
            package_id: pkg.id,
            package_name: pkg.name,
            version_id: ver.id,
            version_label: ver.label
        )
    }

    func removeSelection(_ packageId: String) {
        selections.removeAll(where: { $0.package_id == packageId })
    }

    // MARK: - Preset Application

    func applyPreset(_ preset: BridgeQIPreset) {
        selections.removeAll()
        for pair in preset.packages {
            guard let pkg = bridgePackages.first(where: { $0.id == pair.package_id }),
                  let ver = pkg.versions.first(where: { $0.id == pair.version_id }) ?? pkg.versions.first else { continue }
            selections.append(BridgeQISelection(
                package_id: pkg.id,
                package_name: pkg.name,
                version_id: ver.id,
                version_label: ver.label
            ))
        }
    }

    // MARK: - Server Scan

    func scanServer() async {
        isScanning = true
        scanError = nil

        // Get scan command from Go Core
        let scanCmdJSON = bridge.scanCommand()
        guard let scanData = scanCmdJSON.data(using: .utf8),
              let scanResp = try? JSONDecoder().decode(BridgeResponse<String>.self, from: scanData),
              let scanCmd = scanResp.data else {
            scanError = "Failed to get scan command"
            isScanning = false
            return
        }

        // Execute via SSH
        do {
            let result = try await SSHBridge.shared.execute(scanCmd, serverId: serverId)

            // Parse output via Go Core
            let parseJSON = bridge.parseScanOutput(stdout: result.stdout)
            if let parseData = parseJSON.data(using: .utf8),
               let parseResp = try? JSONDecoder().decode(BridgeResponse<[String: String]>.self, from: parseData),
               let installed = parseResp.data {
                serverScan = installed
            }
        } catch {
            scanError = error.localizedDescription
        }

        isScanning = false
    }

    // MARK: - Begin Installation (Resilient Queue)

    func beginInstallation() async {
        AevonXCoreBridge.CoreLogger.shared.info("beginInstallation() called — \(selections.count) packages selected", module: "QuickInstall")
        guard !selections.isEmpty else { return }

        let profile: ServerProfile
        if let existing = serverProfile {
            profile = existing
        } else {
            AevonXCoreBridge.CoreLogger.shared.info("serverProfile nil — detecting now", module: "QuickInstall")
            let detector = CapabilityDetector(sshService: SSHBridge.shared)
            do {
                let detected = try await detector.detect(serverId: serverId)
                serverProfile = detected
                profile = detected
            } catch {
                AevonXCoreBridge.CoreLogger.shared.error("Profile detection failed: \(error.localizedDescription)", module: "QuickInstall")
                scanError = "Could not detect server OS. Check your connection."
                return
            }
        }

        AevonXCoreBridge.CoreLogger.shared.info("Profile: \(profile.distro.rawValue), pkg: \(profile.packageManager.rawValue)", module: "QuickInstall")

        let installed = serverScan ?? [:]
        let pkgMgr = profile.packageManager.rawValue

        // Build steps via Go Core
        let buildInput: [String: Any] = [
            "selections": selections.map { [
                "package_id": $0.package_id,
                "package_name": $0.package_name,
                "version_id": $0.version_id,
                "version_label": $0.version_label
            ]},
            "package_manager": pkgMgr,
            "installed_packages": installed
        ]

        guard let buildData = try? JSONSerialization.data(withJSONObject: buildInput),
              let buildJSON = String(data: buildData, encoding: .utf8) else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to encode build steps input", module: "QuickInstall")
            return
        }

        let stepsResultJSON = bridge.buildSteps(json: buildJSON)
        guard let stepsData = stepsResultJSON.data(using: .utf8),
              let stepsResp = try? JSONDecoder().decode(BridgeResponse<[BridgeQIStep]>.self, from: stepsData),
              let coreSteps = stepsResp.data else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to decode build steps", module: "QuickInstall")
            return
        }

        AevonXCoreBridge.CoreLogger.shared.info("Built \(coreSteps.count) steps", module: "QuickInstall")

        // Build install command map via Go Core
        var installCommands: [String: String] = [:]
        for step in coreSteps {
            let versionId = selections.first(where: { $0.package_id == (step.package_id ?? "") })?.version_id ?? "latest"
            let cmdJSON = bridge.shellCommand(
                stepTitle: step.title,
                packageId: step.package_id ?? "",
                versionId: versionId,
                pkgMgr: pkgMgr
            )
            if let cmdData = cmdJSON.data(using: .utf8),
               let cmdResp = try? JSONDecoder().decode(BridgeResponse<String>.self, from: cmdData),
               let cmd = cmdResp.data {
                installCommands[step.title] = cmd
            }
        }
        AevonXCoreBridge.CoreLogger.shared.info("Built \(installCommands.count) shell commands", module: "QuickInstall")

        // Convert to AXInstallStep for UI
        let axSteps: [AXInstallStep] = coreSteps.map {
            AXInstallStep(title: $0.title, description: $0.description, icon: $0.icon)
        }

        let vm = AXStepInstallerViewModel(steps: axSteps)
        vm.isRunning = true
        installerViewModel = vm
        isInstalling = true
        isComplete = false
        isFailed = false

        AevonXCoreBridge.CoreLogger.shared.info("isInstalling=true, uploading script...", module: "QuickInstall")

        // Generate queue script via Go Core
        let stepEntries = coreSteps.enumerated().map { (i, step) -> [String: String] in
            let stepId = "\(String(axSteps[i].id.uuidString.prefix(8)))_\(step.package_id ?? "")"
            return ["id": stepId, "title": step.title, "package_id": step.package_id ?? ""]
        }
        let scriptInput: [String: Any] = [
            "steps": stepEntries,
            "install_commands": installCommands
        ]

        guard let scriptData = try? JSONSerialization.data(withJSONObject: scriptInput),
              let scriptJSON = String(data: scriptData, encoding: .utf8) else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to encode script input", module: "QuickInstall")
            return
        }

        let scriptResultJSON = bridge.queueGenerateScript(json: scriptJSON)
        guard let sData = scriptResultJSON.data(using: .utf8),
              let sResp = try? JSONDecoder().decode(BridgeResponse<String>.self, from: sData),
              let script = sResp.data else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to generate queue script", module: "QuickInstall")
            return
        }

        // Upload & launch using SSH
        do {
            let dir = "/tmp/aevonx_qi"
            let scriptPath = "\(dir)/install.sh"
            let pidPath = "\(dir)/pid.txt"

            // 1. mkdir
            let mkdirResult = try await SSHBridge.shared.execute("mkdir -p \(dir)", serverId: serverId)
            guard mkdirResult.isSuccess else {
                throw NSError(domain: "QI", code: 1, userInfo: [NSLocalizedDescriptionKey: "mkdir failed: \(mkdirResult.stderr)"])
            }

            // 2. Base64 encode and upload
            guard let scriptBytes = script.data(using: .utf8) else {
                throw NSError(domain: "QI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Script encoding failed"])
            }
            let b64 = scriptBytes.base64EncodedString()
            let chunkSize = 2000
            var chunks: [String] = []
            var start = b64.startIndex
            while start < b64.endIndex {
                let end = b64.index(start, offsetBy: min(chunkSize, b64.distance(from: start, to: b64.endIndex)))
                chunks.append(String(b64[start..<end]))
                start = end
            }

            let firstWrite = try await SSHBridge.shared.execute("printf '%s' '\(chunks[0])' > \(dir)/script.b64", serverId: serverId)
            guard firstWrite.isSuccess else {
                throw NSError(domain: "QI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Script write failed"])
            }
            for chunk in chunks.dropFirst() {
                let appendResult = try await SSHBridge.shared.execute("printf '%s' '\(chunk)' >> \(dir)/script.b64", serverId: serverId)
                guard appendResult.isSuccess else {
                    throw NSError(domain: "QI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Script append failed"])
                }
            }

            let decodeCmd = "base64 -d \(dir)/script.b64 > \(scriptPath) && chmod +x \(scriptPath) && rm \(dir)/script.b64"
            let decode = try await SSHBridge.shared.execute(decodeCmd, serverId: serverId)
            guard decode.isSuccess else {
                throw NSError(domain: "QI", code: 5, userInfo: [NSLocalizedDescriptionKey: "base64 decode failed: \(decode.stderr)"])
            }

            // 3. Launch with nohup
            let launchCmd = "nohup bash \(scriptPath) >/dev/null 2>&1 & echo $! > \(pidPath) && echo OK"
            let launch = try await SSHBridge.shared.execute(launchCmd, serverId: serverId)
            guard launch.isSuccess && launch.stdout.contains("OK") else {
                throw NSError(domain: "QI", code: 6, userInfo: [NSLocalizedDescriptionKey: "Launch failed: \(launch.stderr)"])
            }
            AevonXCoreBridge.CoreLogger.shared.info("Script launched in background on server", module: "QuickInstall")
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("uploadAndLaunch failed: \(error.localizedDescription)", module: "QuickInstall")
            isFailed = true
            isInstalling = false
            vm.isRunning = false
            vm.hasFailed = true
            if !vm.steps.isEmpty { vm.steps[0].status = .failed(error.localizedDescription) }
            return
        }

        // Build lookup map
        let stepIdToIndex: [String: Int] = Dictionary(
            uniqueKeysWithValues: coreSteps.enumerated().compactMap { (i, step) in
                let sid = "\(axSteps[i].id.uuidString.prefix(8))_\(step.package_id ?? "")"
                return (sid, i)
            }
        )

        // Get poll command from Go Core
        let pollCmdJSON = bridge.pollCommand()
        guard let pollData = pollCmdJSON.data(using: .utf8),
              let pollResp = try? JSONDecoder().decode(BridgeResponse<String>.self, from: pollData),
              let pollCmd = pollResp.data else {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to get poll command", module: "QuickInstall")
            return
        }

        // Start polling loop
        pollingTask = Task { @MainActor in
            var consecutiveErrors = 0
            while !Task.isCancelled {
                do {
                    let result = try await SSHBridge.shared.execute(pollCmd, serverId: self.serverId)
                    print("[QI-POLL] Raw stdout (first 200): \(String(result.stdout.prefix(200)))")

                    // Parse state via Go Core
                    let stateJSON = self.bridge.queueParseState(raw: result.stdout)
                    guard let stateData = stateJSON.data(using: .utf8),
                          let stateResp = try? JSONDecoder().decode(BridgeResponse<BridgeQueueState>.self, from: stateData),
                          let state = stateResp.data else {
                        print("[QI-POLL] ⚠️ Failed to parse state JSON")
                        continue
                    }

                    let stepsSummary = (state.steps ?? []).map { "\($0.id)=\($0.status)" }.joined(separator: ", ")
                    print("[QI-POLL] 📊 Steps: [\(stepsSummary)] | current: \(state.current_step_id ?? "nil") | done: \(state.is_done) | errors: \(state.is_done_with_errors)")
                    if let output = state.recent_output, !output.isEmpty {
                        print("[QI-POLL] 📝 Output: \(String(output.prefix(150)))")
                    }

                    consecutiveErrors = 0
                    self.applyQueueState(state, vm: vm, stepIdToIndex: stepIdToIndex)
                    print("[QI-POLL] 📈 Progress: \(Int(vm.overallProgress * 100))%")

                    if state.is_done {
                        let hasFails = state.is_done_with_errors
                        print("[QI-POLL] ✅ INSTALL DONE — hasFails: \(hasFails)")
                        AevonXCoreBridge.CoreLogger.shared.info("Install done — hasFails: \(hasFails)", module: "QuickInstall")
                        self.isInstalling = false
                        self.isComplete = !hasFails
                        self.isFailed = hasFails
                        vm.isRunning = false
                        vm.isComplete = !hasFails
                        vm.hasFailed = hasFails

                        // Cleanup after delay
                        Task {
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                            let cleanupCmdJSON = self.bridge.cleanupCommand()
                            if let d = cleanupCmdJSON.data(using: .utf8),
                               let r = try? JSONDecoder().decode(BridgeResponse<String>.self, from: d),
                               let cmd = r.data {
                                _ = try? await SSHBridge.shared.execute(cmd, serverId: self.serverId)
                            }
                        }
                        break
                    }
                } catch {
                    consecutiveErrors += 1
                    AevonXCoreBridge.CoreLogger.shared.warning("Poll error #\(consecutiveErrors): \(error.localizedDescription)", module: "QuickInstall")
                    if consecutiveErrors >= 30 {
                        self.isInstalling = false
                        self.isFailed = true
                        vm.hasFailed = true
                        vm.isRunning = false
                        break
                    }
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    // MARK: - Apply Poll State

    private func applyQueueState(
        _ state: BridgeQueueState,
        vm: AXStepInstallerViewModel,
        stepIdToIndex: [String: Int]
    ) {
        for qStep in state.steps ?? [] {
            guard let idx = stepIdToIndex[qStep.id], idx < vm.steps.count else { continue }
            switch qStep.status {
            case "done":    vm.steps[idx].status = .completed
            case "failed":  vm.steps[idx].status = .failed(qStep.message)
            case "skipped": vm.steps[idx].status = .skipped
            case "running":
                vm.steps[idx].status = .running
                vm.currentStepIndex = idx
            default: break
            }
        }
        if let currentId = state.current_step_id, currentId != "DONE",
           let idx = stepIdToIndex[currentId], idx < vm.steps.count {
            let output = state.recent_output ?? ""
            vm.steps[idx].output = output.isEmpty ? nil : output
        }
    }

    // MARK: - Cancel

    func cancelInstallation() {
        pollingTask?.cancel()
        pollingTask = nil
        let cancelCmdJSON = bridge.cancelCommand()
        if let d = cancelCmdJSON.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeResponse<String>.self, from: d),
           let cmd = r.data {
            Task {
                _ = try? await SSHBridge.shared.execute(cmd, serverId: serverId)
            }
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

    private func preferredVersion(for package: BridgeQIPackage) -> BridgeQIVersion {
        package.versions.first(where: { $0.is_recommended }) ?? package.versions[0]
    }
}
