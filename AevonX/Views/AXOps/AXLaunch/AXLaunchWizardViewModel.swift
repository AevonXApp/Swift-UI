//
//  AXLaunchWizardViewModel.swift
//  AevonX
//
//  ViewModel for the AXLaunch deployment wizard.
//

import SwiftUI
import Combine
import AevonXCoreBridge

/// Identifiable key-value pair for env variable editing.
/// Using a stable UUID prevents ForEach index-mismatch crashes on deletion.
struct EnvEntry: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

@MainActor
class AXLaunchWizardViewModel: ObservableObject {

    // MARK: - Step

    enum Step: Int, CaseIterable {
        case source = 0
        case detect = 1
        case configure = 2
        case domain = 3
        case database = 4
        case review = 5
        case progress = 6

        var title: String {
            switch self {
            case .source: return L10n.AXLaunch.stepSelectSource
            case .detect: return L10n.AXLaunch.stepDetect
            case .configure: return L10n.AXLaunch.stepConfigure
            case .domain: return L10n.AXLaunch.stepDomain
            case .database: return L10n.AXLaunch.stepDatabase
            case .review: return L10n.AXLaunch.stepReview
            case .progress: return L10n.AXLaunch.stepProgress
            }
        }

        static let wizardSteps: [Step] = [.source, .detect, .configure, .domain, .database, .review]
    }

    // MARK: - Database Mode

    enum DBMode: String, CaseIterable {
        case autoCreate, manual, existing, none
    }

    // MARK: - Domain Mode

    enum DomainMode: String {
        case newDomain, existingDomain, skip
    }

    // MARK: - Published State

    @Published var currentStep: Step = .source
    @Published var server: Server
    @Published var isUpdate = false

    // Step 1 — Source
    @Published var localPath: String = ""
    @Published var localFolderName: String = ""

    // Step 2 — Detection
    @Published var isDetecting = false
    @Published var projectInfo: AXProjectInfo?
    @Published var detectionError: String?
    @Published var manualFramework: String?
    @Published var ignoreList: [String] = []

    // Step 3 — Configure
    @Published var remotePath: String = "/var/www/"
    @Published var remoteAppName: String = ""
    @Published var envValues: [EnvEntry] = []
    @Published var postSteps = AXPostStepConfig()

    // Step 4 — Domain
    @Published var domainMode: DomainMode = .newDomain
    @Published var domainName: String = ""
    @Published var webServer: String = "nginx"
    @Published var useSSL = true
    @Published var forceHTTPS = true

    // Step 5 — Database
    @Published var dbMode: DBMode = .autoCreate
    @Published var dbEngine: String = "mysql"
    @Published var dbName: String = ""
    @Published var dbUsername: String = ""
    @Published var dbPassword: String = ""
    @Published var dbHost: String = ""
    @Published var dbPort: String = ""
    @Published var dbTestResult: AXDBTestResult?
    @Published var isTestingDB = false
    @Published var existingDatabases: [String] = []

    // Step 6 — Review
    @Published var saveConfig = false

    // Progress
    @Published var launchID: String?
    @Published var launchProgress: AXLaunchProgress = .idle
    @Published var logLines: [AXLaunchLogLine] = []
    @Published var isLaunching = false
    @Published var launchComplete = false
    @Published var launchFailed = false
    @Published var launchError: String?

    // Update (diff)
    @Published var diff: AXLaunchDiff?
    @Published var isComputingDiff = false

    // Errors
    @Published var showError = false
    @Published var errorMessage: String?

    private let service = AXLaunchService.shared
    private var pollingTask: Task<Void, Never>?

    // MARK: - Init

    init(server: Server, localPath: String? = nil) {
        self.server = server
        if let path = localPath {
            self.localPath = path
            self.localFolderName = URL(fileURLWithPath: path).lastPathComponent
        }
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Navigation

    var isFirstStep: Bool { currentStep == .source }
    var isLastWizardStep: Bool { currentStep == .review }
    var isProgressStep: Bool { currentStep == .progress }
    var wizardStepIndex: Int { min(currentStep.rawValue, 5) }
    var totalWizardSteps: Int { 6 }

    func nextStep() {
        guard let next = Step(rawValue: currentStep.rawValue + 1), next != .progress else { return }
        withAnimation(.spring(response: 0.35)) { currentStep = next }
    }

    func prevStep() {
        guard let prev = Step(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.35)) { currentStep = prev }
    }

    var isCurrentStepValid: Bool {
        switch currentStep {
        case .source: return !localPath.isEmpty
        case .detect: return projectInfo != nil || manualFramework != nil
        case .configure: return !remoteAppName.isEmpty
        case .domain: return domainMode == .skip || !domainName.isEmpty
        case .database: return true
        case .review: return true
        case .progress: return true
        }
    }

    // MARK: - Step 1: Source

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = L10n.AXLaunch.chooseFolder

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setLocalPath(url.path)
    }

    func setLocalPath(_ path: String) {
        localPath = path
        localFolderName = URL(fileURLWithPath: path).lastPathComponent
        remoteAppName = localFolderName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }

    // MARK: - Step 2: Detection

    func detectProject() async {
        guard !localPath.isEmpty else { return }
        isDetecting = true
        detectionError = nil
        projectInfo = nil

        do {
            let info = try await service.detectProject(localPath: localPath)
            projectInfo = info
            ignoreList = info.ignoreDefaults
            prefillFromDetection(info)
        } catch {
            detectionError = error.localizedDescription
        }
        isDetecting = false
    }

    private func prefillFromDetection(_ info: AXProjectInfo) {
        if info.hasDatabase {
            dbMode = .autoCreate
            dbEngine = info.databaseType ?? "mysql"
        } else {
            dbMode = .none
        }
        dbName = remoteAppName.replacingOccurrences(of: "-", with: "_") + "_db"
        dbUsername = remoteAppName.replacingOccurrences(of: "-", with: "_") + "_user"
        dbPassword = generateRandomPassword()
    }

    // MARK: - Step 3: Env

    func loadEnvExample() {
        let envPath = URL(fileURLWithPath: localPath)
            .appendingPathComponent(projectInfo?.envSamplePath ?? ".env.example")
        guard let content = try? String(contentsOf: envPath, encoding: .utf8) else { return }
        envValues = content
            .components(separatedBy: .newlines)
            .compactMap { line -> EnvEntry? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return EnvEntry(key: String(parts[0]), value: "") }
                return EnvEntry(key: String(parts[0]), value: String(parts[1]))
            }
    }

    func addEnvVariable() {
        envValues.append(EnvEntry(key: "", value: ""))
    }

    func removeEnvVariable(id: UUID) {
        envValues.removeAll { $0.id == id }
    }

    // MARK: - Step 5: Database

    func testDBConnection() async {
        isTestingDB = true
        dbTestResult = nil
        let config = AXDatabaseConfig(
            mode: dbMode.rawValue,
            engine: dbEngine,
            host: dbHost.isEmpty ? nil : dbHost,
            port: Int(dbPort),
            dbName: dbName,
            dbUsername: dbUsername,
            dbPassword: dbPassword,
            autoGenCreds: dbMode == .autoCreate
        )
        let result = await service.testDBConnection(serverID: server.id.uuidString, config: config)
        dbTestResult = result
        isTestingDB = false
    }

    func loadExistingDatabases() async {
        existingDatabases = await service.listDatabases(serverID: server.id.uuidString, engine: dbEngine)
    }

    func regenerateDBPassword() {
        dbPassword = generateRandomPassword()
    }

    // MARK: - Build Config

    func buildConfig() -> AXLaunchConfig {
        let framework = manualFramework ?? projectInfo?.type ?? "unknown"
        let fullRemotePath = remotePath + remoteAppName
        let envDict: [String: String]? = envValues.isEmpty ? nil :
            Dictionary(uniqueKeysWithValues: envValues.filter { !$0.key.isEmpty }.map { ($0.key, $0.value) })

        return AXLaunchConfig(
            localPath: localPath,
            remotePath: fullRemotePath,
            framework: framework,
            domainName: domainMode == .skip ? nil : domainName,
            createDomain: domainMode == .newDomain,
            useSSL: useSSL,
            forceHTTPS: forceHTTPS,
            webServer: webServer,
            dbConfig: buildDBConfig(),
            envValues: envDict,
            postSteps: postSteps,
            useDocker: framework == "docker",
            transferMode: "auto",
            saveConfig: saveConfig
        )
    }

    private func buildDBConfig() -> AXDatabaseConfig {
        switch dbMode {
        case .none:
            return .none
        case .autoCreate:
            return AXDatabaseConfig(
                mode: "auto_create", engine: dbEngine,
                dbName: dbName, dbUsername: dbUsername, dbPassword: dbPassword,
                autoGenCreds: true, createIfNotExists: true
            )
        case .manual:
            return AXDatabaseConfig(
                mode: "manual", engine: dbEngine,
                host: dbHost.isEmpty ? nil : dbHost,
                port: Int(dbPort),
                dbName: dbName, dbUsername: dbUsername, dbPassword: dbPassword,
                autoGenCreds: false
            )
        case .existing:
            return AXDatabaseConfig(
                mode: "existing", engine: dbEngine,
                host: dbHost.isEmpty ? nil : dbHost,
                port: Int(dbPort),
                dbName: dbName, dbUsername: dbUsername, dbPassword: dbPassword,
                autoGenCreds: false
            )
        }
    }

    // MARK: - Launch

    func startLaunch() async {
        isLaunching = true
        launchComplete = false
        launchFailed = false
        launchError = nil
        logLines = []

        withAnimation(.spring(response: 0.35)) { currentStep = .progress }

        do {
            let config = buildConfig()
            let id = if isUpdate {
                try await service.startUpdate(serverID: server.id.uuidString, config: config)
            } else {
                try await service.startLaunch(serverID: server.id.uuidString, config: config)
            }
            launchID = id
            startPolling(id: id)
        } catch {
            launchFailed = true
            launchError = error.localizedDescription
            isLaunching = false
        }
    }

    func cancelLaunch() async {
        guard let id = launchID else { return }
        await service.cancel(launchID: id)
        pollingTask?.cancel()
        isLaunching = false
    }

    // MARK: - Update (Diff)

    func computeDiff() async {
        isComputingDiff = true
        diff = nil
        do {
            let fullRemotePath = remotePath + remoteAppName
            diff = try await service.computeDiff(
                serverID: server.id.uuidString,
                localPath: localPath,
                remotePath: fullRemotePath
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isComputingDiff = false
    }

    // MARK: - Polling

    private func startPolling(id: String) {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            var logIndex = 0
            while !Task.isCancelled {
                guard let self else { return }
                let progress = await self.service.getProgress(launchID: id)
                self.launchProgress = progress

                let logsResult = await self.service.getLogs(launchID: id, fromIndex: logIndex)
                if !logsResult.lines.isEmpty {
                    self.logLines.append(contentsOf: logsResult.lines)
                    logIndex = logsResult.total
                }

                if progress.status == "completed" {
                    self.launchComplete = true
                    self.isLaunching = false
                    break
                } else if progress.status == "failed" || progress.status == "cancelled" {
                    self.launchFailed = true
                    self.launchError = progress.log
                    self.isLaunching = false
                    break
                }

                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    // MARK: - Helpers

    private func generateRandomPassword() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<32).map { _ in chars.randomElement()! })
    }
}
