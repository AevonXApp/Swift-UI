//
//  AXLaunchWizardViewModel.swift
//  AevonX
//
//  ViewModel for the AXLaunch deployment wizard.
//  New flow: Source → Server → Domain & Path → Database → Review & Launch
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import AevonXCoreBridge

/// Identifiable key-value pair for env variable editing.
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
        case server = 1
        case domainPath = 2
        case database = 3
        case review = 4
        case progress = 5

        var title: String {
            switch self {
            case .source: return L10n.AXLaunch.stepSelectSource
            case .server: return L10n.AXLaunch.stepServer
            case .domainPath: return L10n.AXLaunch.stepDomainPath
            case .database: return L10n.AXLaunch.stepDatabase
            case .review: return L10n.AXLaunch.stepReview
            case .progress: return L10n.AXLaunch.stepProgress
            }
        }

        static let wizardSteps: [Step] = [.source, .server, .domainPath, .database, .review]
    }

    // MARK: - Database Mode

    enum DBMode: String, CaseIterable {
        case autoCreate, manual, existing, none
    }

    // MARK: - Domain Mode

    enum DomainMode: String {
        case newDomain, existingDomain, skip
    }

    // MARK: - Source Type

    enum SourceType: String {
        case folder, compressed
    }

    // MARK: - Connection Stage

    enum ConnectionStage: String {
        case idle, connecting, authenticating, detecting, connected, failed
    }

    // MARK: - Published State

    @Published var currentStep: Step = .source
    @Published var isUpdate = false

    // Step 1 — Source
    @Published var sourceType: SourceType = .folder
    @Published var localPath: String = ""
    @Published var localFolderName: String = ""
    @Published var compressedFilePath: String = ""
    @Published var compressedFileName: String = ""

    // Step 2 — Server
    @Published var selectedServer: Server?
    @Published var availableServers: [Server] = []
    @Published var connectionStage: ConnectionStage = .idle
    @Published var connectionError: String?
    @Published var isConnecting = false
    @Published var isDetecting = false
    @Published var projectInfo: AXProjectInfo?
    @Published var detectionError: String?
    @Published var manualFramework: String?
    @Published var ignoreList: [String] = []

    // Step 3 — Domain & Path
    @Published var domainMode: DomainMode = .newDomain
    @Published var domainName: String = ""
    @Published var existingDomains: [String] = []
    @Published var isLoadingDomains = false
    @Published var webServer: String = "nginx"
    @Published var useSSL = true
    @Published var forceHTTPS = true
    @Published var remotePath: String = "/var/www/"
    @Published var remoteAppName: String = ""
    @Published var serverDirectories: [RemoteFileItem] = []
    @Published var currentBrowsePath: String = "/var/www"
    @Published var isBrowsingServer = false

    // Step 4 — Database
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
    @Published var installedDBEngines: [String] = []
    @Published var isDetectingEngines = false

    // Step 5 — Review & Launch
    @Published var envValues: [EnvEntry] = []
    @Published var postSteps = AXPostStepConfig()
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
    weak var serverListViewModel: ServerListViewModel?

    // MARK: - Init

    init(servers: [Server] = [], selectedServer: Server? = nil, localPath: String? = nil, serverListViewModel: ServerListViewModel? = nil) {
        self.availableServers = servers
        self.selectedServer = selectedServer
        self.serverListViewModel = serverListViewModel
        if let path = localPath {
            self.localPath = path
            self.localFolderName = URL(fileURLWithPath: path).lastPathComponent
        }
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Computed

    var server: Server { selectedServer ?? Server.placeholder(name: "—") }
    /// The Bridge/Core server ID string used for SSH operations.
    var serverID: String { selectedServer?.coreID ?? "" }
    var isFirstStep: Bool { currentStep == .source }
    var isLastWizardStep: Bool { currentStep == .review }
    var isProgressStep: Bool { currentStep == .progress }
    var wizardStepIndex: Int { min(currentStep.rawValue, 4) }
    var totalWizardSteps: Int { 5 }

    var fullRemotePath: String {
        if remoteAppName.isEmpty {
            return remotePath.hasSuffix("/") ? String(remotePath.dropLast()) : remotePath
        }
        let base = remotePath.hasSuffix("/") ? remotePath : remotePath + "/"
        return base + remoteAppName
    }

    // MARK: - Validation Helpers

    private func isValidDomainName(_ domain: String) -> Bool {
        guard !domain.isEmpty else { return false }
        let pattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#
        return domain.range(of: pattern, options: .regularExpression) != nil
    }

    var isValidRemoteAppName: Bool {
        guard !remoteAppName.isEmpty else { return true } // empty is allowed (optional)
        let forbidden = CharacterSet(charactersIn: ";&|`$(){}[]!#~'\"\\<>?*\n\r\t ")
        guard remoteAppName.rangeOfCharacter(from: forbidden) == nil else { return false }
        guard !remoteAppName.contains("..") else { return false }
        guard !remoteAppName.hasPrefix("/") && !remoteAppName.hasPrefix("-") else { return false }
        return true
    }

    // MARK: - Navigation

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
        case .source:
            return sourceType == .folder ? !localPath.isEmpty : !compressedFilePath.isEmpty
        case .server:
            return selectedServer != nil && connectionStage == .connected && (projectInfo != nil || manualFramework != nil)
        case .domainPath:
            let hasPath = !remoteAppName.isEmpty || (domainMode == .existingDomain && !remotePath.isEmpty)
            let validDomain = domainMode == .skip || isValidDomainName(domainName)
            return hasPath && validDomain && isValidRemoteAppName
        case .database:
            switch dbMode {
            case .autoCreate, .manual:
                return !dbName.isEmpty && !dbUsername.isEmpty && !dbPassword.isEmpty
            case .existing, .none:
                return true
            }
        case .review:
            return true
        case .progress:
            return true
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

    func selectFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .init(filenameExtension: "zip")!,
            .init(filenameExtension: "tar")!,
            .init(filenameExtension: "gz")!,
            .init(filenameExtension: "tgz")!,
            .init(filenameExtension: "bz2")!,
            .init(filenameExtension: "xz")!,
            .init(filenameExtension: "rar")!,
            .init(filenameExtension: "7z")!,
        ].compactMap { $0 }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        compressedFilePath = url.path
        compressedFileName = url.lastPathComponent
        // Derive app name from archive filename
        let stem = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: ".tar", with: "")
        remoteAppName = stem.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    func setLocalPath(_ path: String) {
        localPath = path
        localFolderName = URL(fileURLWithPath: path).lastPathComponent
        remoteAppName = localFolderName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }

    // MARK: - Step 2: Server Connection

    func connectToServer() async {
        guard let server = selectedServer else { return }
        connectionStage = .connecting
        connectionError = nil
        isConnecting = true

        // 1. Hot path: Remote Fleet keeps a session warm the moment you open
        // a server, so in most cases isConnected returns true here and we
        // skip the expensive re-authentication + decrypt round trip.
        if SSHBridge.shared.isConnected(serverID: serverID) {
            connectionStage = .detecting
            if sourceType == .folder && !localPath.isEmpty {
                await detectProject()
            }
            connectionStage = .connected
            isConnecting = false
            return
        }

        // 2. No warm session — decrypt credentials and establish a fresh SSH.
        connectionStage = .authenticating

        // Accessible servers carry the encrypted credentials payload. A miss
        // here usually means the wizard was opened before the fleet finished
        // loading; surface the actual reason so operators can retry instead
        // of seeing the opaque "Could not connect to server".
        guard let serverListVM = serverListViewModel else {
            connectionStage = .failed
            connectionError = "\(L10n.AXLaunch.errorConnectionFailed): server list unavailable"
            isConnecting = false
            return
        }
        guard let accessible = serverListVM.servers.first(where: { $0.id == serverID }) else {
            connectionStage = .failed
            connectionError = "\(L10n.AXLaunch.errorConnectionFailed): server \(serverID.prefix(8))… not in access list"
            isConnecting = false
            return
        }

        do {
            let payload = EncryptedServerPayload(
                encryptedData: accessible.server.encryptedPayload,
                nonce: accessible.server.payloadNonce,
                authTag: accessible.server.payloadAuthTag,
                metadata: accessible.server.encryptionMetadata
            )

            let serverData = try await ServerEncryptionService.shared.decryptServer(
                EncryptedServerData.self,
                from: payload
            )

            // Trust stored host key (TOFU)
            let hostPort = "\(server.host):\(server.port)"
            if let storedFP = UserDefaults.standard.string(forKey: "hostkey:\(hostPort)") {
                SSHBridge.shared.trustHostKey(hostPort: hostPort, fingerprint: storedFP)
            }

            // Fetch a signed Connection Authorization Token (CAT) + the
            // device fingerprint — the Go Core rejects SSHConnect with
            // `CAT_REQUIRED: connection authorization token is mandatory`
            // when either is missing. This mirrors the main dashboard
            // connect flow in ServerConnectionViewModel so Launch Wizard
            // uses the same trust path as the normal "Connect" button.
            let deviceFingerprint = await DeviceIdentifier.shared.getDeviceID() ?? ""
            let signedCATToken = try await requestCAT(serverID: serverID, deviceFingerprint: deviceFingerprint)

            let connectResult = await SSHBridge.shared.connectAsync(
                serverID: serverID,
                host: server.host,
                port: Int32(server.port),
                username: serverData.connectionDetails.username,
                password: serverData.authentication.password ?? "",
                privateKey: serverData.authentication.privateKey ?? "",
                passphrase: serverData.authentication.keyPassphrase ?? "",
                catToken: signedCATToken,
                deviceFingerprint: deviceFingerprint
            )

            // Parse the Go-Core envelope. When success=false, extract the
            // underlying error (auth refused, network unreachable, host key
            // mismatch) — the previous generic "Could not connect to server"
            // made these indistinguishable and blocked debugging.
            let data = connectResult.data(using: .utf8) ?? Data()
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let success = json?["success"] as? Bool == true

            if !success {
                let reason = (json?["error"] as? String)
                    ?? (json?["message"] as? String)
                    ?? String(connectResult.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
                connectionStage = .failed
                connectionError = reason.isEmpty
                    ? L10n.AXLaunch.errorConnectionFailed
                    : "\(L10n.AXLaunch.errorConnectionFailed): \(reason)"
                AevonXCoreBridge.CoreLogger.shared.error("[AXLaunch] SSH connect failed for \(server.host):\(server.port) — \(reason)", module: "AXLaunch")
                isConnecting = false
                return
            }

            // 3. Connected — detect project
            connectionStage = .detecting
            if sourceType == .folder && !localPath.isEmpty {
                await detectProject()
            }

            connectionStage = .connected
        } catch {
            connectionStage = .failed
            connectionError = "\(L10n.AXLaunch.errorConnectionFailed): \(error.localizedDescription)"
            AevonXCoreBridge.CoreLogger.shared.error("[AXLaunch] SSH connect threw: \(error.localizedDescription)", module: "AXLaunch")
        }

        isConnecting = false
    }

    /// Requests a signed Connection Authorization Token from the backend.
    /// Mirrors ServerConnectionViewModel.requestCATFromBackend() so the
    /// Launch Wizard gets the same CAT the normal Connect button uses.
    private func requestCAT(serverID: String, deviceFingerprint: String) async throws -> String {
        guard !deviceFingerprint.isEmpty else {
            throw NSError(domain: "AXLaunch", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Device fingerprint unavailable"
            ])
        }
        guard let token = await AevonXCoreBridge.AuthService.shared.getToken() else {
            throw NSError(domain: "AXLaunch", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User session expired — please sign in again"
            ])
        }
        let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let resultJSON = await APIBridge.shared.requestCATAsync(
            baseURL: baseURL, token: token,
            serverID: serverID, fingerprint: deviceFingerprint
        )
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let responseData = result["data"] as? [String: Any],
              let catToken = responseData["token"] as? String else {
            // Surface the real reason so users see "CAT request failed: …"
            // instead of a silent CAT_REQUIRED fallback downstream.
            let errMsg = (try? JSONSerialization.jsonObject(with: resultJSON.data(using: .utf8) ?? Data()) as? [String: Any])
                .flatMap { ($0["error"] as? [String: Any])?["message"] as? String }
                ?? "CAT request failed"
            throw NSError(domain: "AXLaunch", code: -1, userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
        return catToken
    }

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

    // MARK: - Step 3: Domain & Path

    /// Domain → document root map (populated when loading existing domains).
    var domainRoots: [String: String] = [:]

    func loadExistingDomains() async {
        guard selectedServer != nil else { return }
        isLoadingDomains = true
        existingDomains = []
        domainRoots = [:]

        // Parse nginx/apache site configs to get domain=root pairs.
        // The awk must:
        //  - Match `server_name` directive (nginx) only when the value contains a dot
        //  - Match `root` directive only at the start of line (ignoring fastcgi_param lines)
        //  - Filter out placeholders: _, localhost, www.example.com, variables ($...)
        let raw = await SSHBridge.shared.executeAsync(
            serverID: serverID,
            command: #"""
            for f in /etc/nginx/sites-enabled/*; do
              [ -f "$f" ] && awk '
                /^\s*server_name\s/ {
                  for (i=2; i<=NF; i++) {
                    v=$i; gsub(/;/,"",v)
                    if (v ~ /^[a-zA-Z0-9].*\..*[a-zA-Z]$/ && v !~ /^www\.example\./ && v != "localhost")
                      name=v
                  }
                }
                /^\s*root\s/ {
                  v=$2; gsub(/;/,"",v)
                  if (v ~ /^\// && v !~ /\$/)
                    root=v
                }
                END { if (name && root) print name"="root }
              ' "$f" 2>/dev/null
            done
            for f in /etc/apache2/sites-enabled/*; do
              [ -f "$f" ] && awk '
                /^\s*ServerName\s/ {
                  v=$2; gsub(/;/,"",v)
                  if (v ~ /^[a-zA-Z0-9].*\..*[a-zA-Z]$/ && v !~ /^www\.example\./ && v != "localhost")
                    name=v
                }
                /^\s*DocumentRoot\s/ {
                  v=$2; gsub(/"/,"",v)
                  if (v ~ /^\// && v !~ /\$/)
                    root=v
                }
                END { if (name && root) print name"="root }
              ' "$f" 2>/dev/null
            done
            """#
        )

        var domains: [String] = []
        for line in raw.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            let domain = parts[0]
            let root = parts.dropFirst().joined(separator: "=") // root path may contain =
            // Extra safety: skip anything that looks like a variable or keyword
            let bogus: Set<String> = ["_", "default", "localhost", "server_name",
                                       "www.example.com", "SCRIPT_FILENAME", "root"]
            if !bogus.contains(domain), domain.contains("."), !domain.hasPrefix("$") {
                domains.append(domain)
                domainRoots[domain] = root
            }
        }

        existingDomains = Array(Set(domains)).sorted()
        isLoadingDomains = false
    }

    /// Called when user selects an existing domain — auto-fills remote path from its document root.
    func selectExistingDomain(_ domain: String) {
        domainName = domain
        if let root = domainRoots[domain] {
            remotePath = root.hasSuffix("/") ? root : root + "/"
            remoteAppName = ""
        }
    }

    func browseServerPath(_ path: String) async {
        guard selectedServer != nil else { return }
        isBrowsingServer = true
        currentBrowsePath = path

        do {
            serverDirectories = try await SFTPService.shared.listDirectory(
                path: path, serverId: serverID, showHidden: false
            ).filter { $0.isDirectory }
        } catch {
            serverDirectories = []
        }
        isBrowsingServer = false
    }

    func selectRemotePath(_ path: String) {
        remotePath = path.hasSuffix("/") ? path : path + "/"
    }

    // MARK: - Step 4: Database

    func detectInstalledDBEngines() async {
        guard selectedServer != nil else { return }
        isDetectingEngines = true
        installedDBEngines = []

        let raw = await SSHBridge.shared.executeAsync(
            serverID: serverID,
            command: """
            (command -v mysql >/dev/null 2>&1 && echo mysql) ; \
            (command -v psql >/dev/null 2>&1 && echo postgres) ; \
            (command -v mongod >/dev/null 2>&1 && echo mongodb) ; \
            (command -v redis-cli >/dev/null 2>&1 && echo redis)
            """
        )

        installedDBEngines = raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Auto-select first installed engine
        if let first = installedDBEngines.first, !installedDBEngines.isEmpty {
            if dbEngine.isEmpty || !installedDBEngines.contains(dbEngine) {
                dbEngine = first
            }
        }

        isDetectingEngines = false
    }

    func testDBConnection() async {
        dbTestResult = nil
        guard selectedServer != nil else { return }
        isTestingDB = true
        defer { isTestingDB = false }
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
        let result = await service.testDBConnection(serverID: serverID, config: config)
        dbTestResult = result
    }

    func loadExistingDatabases() async {
        guard selectedServer != nil else { return }
        existingDatabases = await service.listDatabases(serverID: serverID, engine: dbEngine)
    }

    func regenerateDBPassword() {
        dbPassword = generateRandomPassword()
    }

    // MARK: - Step 5: Env Vars

    func loadEnvExample() {
        let basePath = sourceType == .folder ? localPath : ""
        guard !basePath.isEmpty else { return }
        let envPath = URL(fileURLWithPath: basePath)
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

    // MARK: - Build Config

    func buildConfig() -> AXLaunchConfig {
        let framework = manualFramework ?? projectInfo?.type ?? "unknown"
        let envDict: [String: String]? = envValues.isEmpty ? nil :
            Dictionary(envValues.filter { !$0.key.isEmpty }.map { ($0.key, $0.value) }, uniquingKeysWith: { _, latest in latest })

        let sourcePath = sourceType == .folder ? localPath : compressedFilePath

        return AXLaunchConfig(
            localPath: sourcePath,
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
            transferMode: sourceType == .compressed ? "tar" : "auto",
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
        guard selectedServer != nil else { return }
        isLaunching = true
        launchComplete = false
        launchFailed = false
        launchError = nil
        logLines = []

        withAnimation(.spring(response: 0.35)) { currentStep = .progress }

        do {
            let config = buildConfig()
            debugLog("[AXLaunch] Starting launch — serverID: \(serverID), framework: \(config.framework), localPath: \(config.localPath), remotePath: \(config.remotePath)")
            let id = if isUpdate {
                try await service.startUpdate(serverID: serverID, config: config)
            } else {
                try await service.startLaunch(serverID: serverID, config: config)
            }
            debugLog("[AXLaunch] Launch started — launchID: \(id)")
            launchID = id
            startPolling(id: id)
        } catch {
            debugLog("[AXLaunch] Launch FAILED — error: \(error)")
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
        guard selectedServer != nil else { return }
        isComputingDiff = true
        diff = nil
        do {
            diff = try await service.computeDiff(
                serverID: serverID,
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
                debugLog("[AXLaunch] Poll — status: \(progress.status), step: \(progress.stepName), percent: \(progress.percent), log: \(progress.log)")
                self.launchProgress = progress

                let logsResult = await self.service.getLogs(launchID: id, fromIndex: logIndex)
                if !logsResult.lines.isEmpty {
                    self.logLines.append(contentsOf: logsResult.lines)
                    logIndex = logsResult.total
                }

                if progress.status == "success" {
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
