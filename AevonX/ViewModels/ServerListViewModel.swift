//
//  ServerListViewModel.swift
//  AevonX
//
//  ViewModel for managing the server list with zero-knowledge encryption
//  Real-time updates via polling
//

import SwiftUI
import AevonXCoreBridge

import Combine

/// View model for server list management with real-time status updates
@MainActor
class ServerListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var servers: [AccessibleServer] = []
    @Published var decryptedServers: [ServerViewModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isAuthenticated = false
    @Published var needsLogin = false
    
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var canAddServer = false
    @Published var remainingSlots = 0
    
    @Published var connectionProgress: [String: ConnectionProgress] = [:]
    @Published var connectionResults: [String: ConnectionTestResult] = [:]
    
    // MARK: - Encryption Error Handling
    
    @Published var showEncryptionKeyInput = false
    @Published var encryptionError: String?
    @Published var failedServerIds: Set<String> = []
    
    // MARK: - Properties
    
    private var isInitialized = false
    private var statusPollingTask: Task<Void, Never>?
    private let statusPollInterval: TimeInterval = 600 // 10 minutes (matches permit TTL)
    private var isInForeground = true
    
    // MARK: - Initialization
    
    func initialize() async {
        AevonXCoreBridge.CoreLogger.shared.info("🔵 initialize() called - isInitialized: \(isInitialized)", module: "ServerList")

        guard !isInitialized else {
            AevonXCoreBridge.CoreLogger.shared.warning("⚠️ Already initialized — skipping", module: "ServerList")
            return
        }

        AevonXCoreBridge.CoreLogger.shared.info("🟢 Starting initialization...", module: "ServerList")
        isInitialized = true

        await setupEncryption()
        await refresh()
        startStatusPolling()
        
        AevonXCoreBridge.CoreLogger.shared.info("✅ Initialization complete", module: "ServerList")
    }

    private func setupEncryption() async {
        let hasKey = EncryptionKeyStore.shared.hasKey()
        
        if !hasKey {
            AevonXCoreBridge.CoreLogger.shared.warning("⚠️ No encryption key — user needs to set up", module: "ServerList")
            return
        }
        
        // Load key into memory cache (instant file read, no prompts)
        do {
            _ = try await EncryptionKeyStore.shared.getKey()
            AevonXCoreBridge.CoreLogger.shared.info("✅ Encryption key ready", module: "ServerList")
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to load encryption key: \(error.localizedDescription)", module: "ServerList")
        }
    }
    
    deinit {
        statusPollingTask?.cancel()
    }
    
    // MARK: - Data Refresh
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        // Check authentication first
        let token = await AevonXCoreBridge.AuthService.shared.getToken()
        if token == nil {
            isAuthenticated = false
            needsLogin = true
            return
        }
        isAuthenticated = true
        let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL

        // 1. Fetch subscription status (separate error handling)
        do {
            let status = try await SubscriptionManager.shared.getSubscriptionStatus(forceRefresh: true)
            self.subscriptionStatus = status
            self.canAddServer = await SubscriptionManager.shared.canAddServer()
            self.remainingSlots = await SubscriptionManager.shared.remainingServerSlots()
        } catch {
            AevonXCoreBridge.CoreLogger.shared.warning("Subscription check failed: \(error.localizedDescription)", module: "ServerList")
        }

        // 2. Fetch servers (always runs regardless of subscription check)
        do {
            let resultJSON = await APIBridge.shared.fetchServersAsync(baseURL: baseURL, token: token!)
            guard let serversData = parseGoServers(resultJSON) else {
                errorMessage = extractGoError(resultJSON)
                showError = true
                return
            }
            self.servers = await SubscriptionManager.shared.getAccessibleServers(from: serversData)

            // Only decrypt if we have encryption key
            let hasKey = EncryptionKeyStore.shared.hasKey()
            if hasKey {
                await decryptServersForDisplay()
            } else {
                AevonXCoreBridge.CoreLogger.shared.warning("Encryption key not available, skipping server decryption", module: "ServerList")
                self.decryptedServers = []
            }
        } catch {
            errorMessage = "Failed to load servers: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Real-Time Status Polling
    
    private func startStatusPolling() {
        let settings = AppSettingsManager.shared
        guard settings.autoRefreshStatus else { return }

        statusPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let interval = AppSettingsManager.shared.statusCheckInterval
                    try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)

                    guard let self = self else { break }
                    guard self.isInForeground, !self.servers.isEmpty else { continue }

                    await self.refreshServerStatuses()
                } catch {
                    break
                }
            }
        }
    }
    
    func onEnterForeground() { isInForeground = true }
    func onEnterBackground() { isInForeground = false }
    
    private func refreshServerStatuses() async {
        // 1. Refresh subscription status
        do {
            let status = try await SubscriptionManager.shared.getSubscriptionStatus(forceRefresh: true)
            self.subscriptionStatus = status
            self.canAddServer = await SubscriptionManager.shared.canAddServer()
            self.remainingSlots = await SubscriptionManager.shared.remainingServerSlots()
        } catch {
            AevonXCoreBridge.CoreLogger.shared.warning("Subscription poll failed: \(error.localizedDescription)", module: "ServerList")
        }
        
        // 2. Refresh server list
        do {
            let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
            let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let resultJSON = await APIBridge.shared.fetchServersAsync(baseURL: baseURL, token: token)
            if let serversData = parseGoServers(resultJSON) {
                self.servers = await SubscriptionManager.shared.getAccessibleServers(from: serversData)
            }
        } catch {
            AevonXCoreBridge.CoreLogger.shared.warning("Server poll failed: \(error.localizedDescription)", module: "ServerList")
        }
    }
    
    // MARK: - Decryption
    
    /// Decrypts all accessible servers for display
    private func decryptServersForDisplay() async {
        var decrypted: [ServerViewModel] = []
        var hasDecryptionErrors = false
        
        failedServerIds.removeAll()
        
        for accessibleServer in servers {
            do {
                let payload = EncryptedServerPayload(
                    encryptedData: accessibleServer.server.encryptedPayload,
                    nonce: accessibleServer.server.payloadNonce,
                    authTag: accessibleServer.server.payloadAuthTag,
                    metadata: accessibleServer.server.encryptionMetadata
                )
                
                // Decrypt using new ServerEncryptionService
                let serverData = try await ServerEncryptionService.shared.decryptServer(
                    EncryptedServerData.self,
                    from: payload
                )
                
                let viewModel = ServerViewModel(
                    id: accessibleServer.id,
                    name: serverData.serverIdentity.name,
                    host: serverData.connectionDetails.host,
                    port: serverData.connectionDetails.port,
                    username: serverData.connectionDetails.username,
                    iconName: serverData.serverIdentity.iconName,
                    customColor: serverData.serverIdentity.customColor,
                    tags: serverData.serverIdentity.tags,
                    osType: serverData.metadata.osType,
                    location: serverData.metadata.location,
                    createdAt: accessibleServer.server.createdAt,
                    isAccessible: accessibleServer.server.isAccessible,
                    accessLevel: accessibleServer.accessLevel
                )
                
                decrypted.append(viewModel)
                AevonXCoreBridge.CoreLogger.shared.info("Decrypted server: \(serverData.serverIdentity.name)", module: "ServerList")
                
            } catch {
                AevonXCoreBridge.CoreLogger.shared.error("Failed to decrypt server \(accessibleServer.id): \(error.localizedDescription)", module: "ServerList")
                hasDecryptionErrors = true
                failedServerIds.insert(accessibleServer.id)
                
                let placeholder = ServerViewModel(
                    id: accessibleServer.id,
                    name: "🔒 Decryption Failed",
                    host: error.localizedDescription,
                    port: 22,
                    username: "---",
                    createdAt: accessibleServer.server.createdAt,
                    isAccessible: false,
                    accessLevel: accessibleServer.accessLevel
                )
                decrypted.append(placeholder)
            }
        }
        
        self.decryptedServers = decrypted
        
        if hasDecryptionErrors {
            self.encryptionError = "Some servers could not be decrypted. Your encryption key may have changed."
            self.showEncryptionKeyInput = true
        }
    }
    
    /// Retry decryption after entering encryption key
    func retryDecryptionWithKey(_ key: String) async {
        AevonXCoreBridge.CoreLogger.shared.info("Retrying decryption with provided key...", module: "ServerList")
        
        do {
            try await EncryptionKeyStore.shared.saveKey(key)
            showEncryptionKeyInput = false
            encryptionError = nil
            
            // Retry decryption
            await decryptServersForDisplay()
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to save key: \(error.localizedDescription)", module: "ServerList")
            encryptionError = "Failed to save encryption key: \(error.localizedDescription)"
        }
    }
    
    func dismissEncryptionError() {
        showEncryptionKeyInput = false
        encryptionError = nil
    }
    
    // MARK: - Server Management
    
    func addServer(_ request: AddServerRequest) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let serverData = request.toEncryptedServerData()
            let encryptedPayload = try await ServerEncryptionService.shared.encryptServer(serverData)
            
            // Encode payload as JSON for Go
            let payloadDict: [String: Any] = [
                "server_name": request.name,
                "encrypted_payload": encryptedPayload.encryptedData,
                "payload_nonce": encryptedPayload.nonce,
                "payload_auth_tag": encryptedPayload.authTag,
                "encryption_metadata": try JSONSerialization.jsonObject(with: JSONEncoder().encode(encryptedPayload.metadata))
            ]
            let payloadJSON = String(data: try JSONSerialization.data(withJSONObject: payloadDict), encoding: .utf8) ?? "{}"
            
            let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
            let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let resultJSON = await APIBridge.shared.createServerAsync(baseURL: baseURL, token: token, payloadJSON: payloadJSON)
            
            // Check for errors
            if let data = resultJSON.data(using: .utf8),
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               result["success"] as? Bool != true {
                let errorMsg = extractGoError(resultJSON)
                if errorMsg.contains("limit") {
                    errorMessage = "Server limit reached. Upgrade your plan to add more servers."
                } else {
                    errorMessage = "Failed to add server: \(errorMsg)"
                }
                showError = true
                return
            }
            
            await refresh()
            
        } catch {
            errorMessage = "Failed to add server: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func deleteServer(id: String) async {
        isLoading = true
        defer { isLoading = false }

        // Clear stored TOFU host key before deleting.
        // After server reinstall the host key changes, so stale keys must not persist.
        if let vm = decryptedServers.first(where: { $0.id == id }) {
            let hostPort = "\(vm.host):\(vm.port)"
            UserDefaults.standard.removeObject(forKey: "hostkey:\(hostPort)")
            SSHBridge.shared.removeHostKey(hostPort: hostPort)
        }

        let token = await AevonXCoreBridge.AuthService.shared.getToken() ?? ""
        let baseURL = AevonXCoreBridge.ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let resultJSON = await APIBridge.shared.deleteServerAsync(baseURL: baseURL, token: token, serverID: id)

        if let data = resultJSON.data(using: .utf8),
           let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           result["success"] as? Bool != true {
            errorMessage = "Failed to delete server: \(extractGoError(resultJSON))"
            showError = true
            return
        }

        await refresh()
    }
    
    // MARK: - Connection Testing
    
    func testConnection(serverId: String) async {
        guard let accessibleServer = servers.first(where: { $0.id == serverId }) else {
            return
        }
        
        connectionProgress[serverId] = ConnectionProgress(
            stage: .decrypting,
            message: "Decrypting credentials...",
            percentComplete: 0.2
        )
        
        do {
            let details = try await EphemeralDecryptionService.shared.decryptServerDetails(
                from: accessibleServer.server.toEncryptedPayload()
            )
            
            guard let connectionDetails = details["connection_details"] as? [String: Any],
                  let host = connectionDetails["host"] as? String,
                  let port = connectionDetails["port"] as? Int,
                  let username = connectionDetails["username"] as? String else {
                throw SSHConnectionError.invalidCredentials
            }
            
            let authDetails = details["authentication"] as? [String: Any]
            let password = authDetails?["password"] as? String ?? ""
            let privateKey = authDetails?["private_key"] as? String ?? ""
            let passphrase = authDetails?["key_passphrase"] as? String ?? ""
            
            connectionProgress[serverId] = ConnectionProgress(
                stage: .establishingSSH,
                message: "Connecting...",
                percentComplete: 0.5
            )
            
            let startTime = Date()
            
            // Connect via Go SSH Bridge
            let connectResult = await SSHBridge.shared.connectAsync(
                serverID: serverId,
                host: host,
                port: Int32(port),
                username: username,
                password: password,
                privateKey: privateKey,
                passphrase: passphrase
            )
            
            guard let rd = connectResult.data(using: .utf8),
                  let rj = try? JSONSerialization.jsonObject(with: rd) as? [String: Any],
                  rj["success"] as? Bool == true else {
                connectionResults[serverId] = ConnectionTestResult(
                    success: false, message: "SSH connection failed", stage: .failed
                )
                return
            }
            
            // Quick test command
            let _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "echo 1")
            let latencyMs = Date().timeIntervalSince(startTime) * 1000
            
            // Disconnect test session
            SSHBridge.shared.disconnect(serverID: serverId)
            
            connectionResults[serverId] = ConnectionTestResult(
                success: true,
                message: "Connection successful",
                stage: .complete,
                latencyMs: latencyMs
            )
            
        } catch {
            connectionResults[serverId] = ConnectionTestResult(
                success: false,
                message: "Failed to test connection: \(error.localizedDescription)",
                stage: .failed
            )
        }
    }
    
    // MARK: - Access Control
    
    func canModifyServer(id: String) -> Bool {
        guard let server = servers.first(where: { $0.id == id }) else {
            return false
        }
        return server.accessLevel == .full
    }
    
    func accessLevel(for id: String) -> ServerAccessLevel {
        return servers.first(where: { $0.id == id })?.accessLevel ?? .none
    }
    
    // MARK: - Server Status
    
    func serverStatus(for serverId: String) -> ServerStatus {
        guard let server = servers.first(where: { $0.id == serverId }) else {
            return .offline
        }
        return server.server.isAccessible ? .online : .offline
    }
    
    // MARK: - Go Bridge Helpers
    
    /// Parses Go AuthServiceResult → extracts servers array from "data.servers".
    private func parseGoServers(_ json: String) -> [ServerResponse]? {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              result["success"] as? Bool == true,
              let dataVal = result["data"] as? [String: Any],
              let serversArray = dataVal["servers"] as? [[String: Any]] else {
            return nil
        }
        
        // Re-encode and decode via JSONDecoder (handles date parsing properly)
        guard let serversJSON = try? JSONSerialization.data(withJSONObject: serversArray) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) { return date }
            let laravelFmt = DateFormatter()
            laravelFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            laravelFmt.locale = Locale(identifier: "en_US_POSIX")
            if let date = laravelFmt.date(from: dateString) { return date }
            laravelFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = laravelFmt.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
        
        return try? decoder.decode([ServerResponse].self, from: serversJSON)
    }
    
    /// Extracts error message from Go AuthServiceResult.
    private func extractGoError(_ json: String) -> String {
        guard let rawData = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              let error = result["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return "An unexpected error occurred"
        }
        return message
    }
}

// MARK: - Connection Progress

struct ConnectionProgress {
    let stage: ConnectionStage
    let message: String
    let percentComplete: Double
}
