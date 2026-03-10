//
//  ServerListViewModel.swift
//  AevonX
//
//  ViewModel for managing the server list with zero-knowledge encryption
//  Real-time updates via polling
//

import SwiftUI
import AevonXCore
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
    private let statusPollInterval: TimeInterval = 60
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
        let token = await AuthService.shared.getToken()
        if token == nil {
            isAuthenticated = false
            errorMessage = "Please log in to view your servers"
            showError = true
            return
        }
        isAuthenticated = true
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL

        do {
            // Fetch subscription status (still via SubscriptionManager for business logic)
            let status = try await SubscriptionManager.shared.getSubscriptionStatus(forceRefresh: true)
            self.subscriptionStatus = status
            self.canAddServer = await SubscriptionManager.shared.canAddServer()
            self.remainingSlots = await SubscriptionManager.shared.remainingServerSlots()

            // Fetch servers via Go HTTP
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
        statusPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(60 * 1_000_000_000))
                    
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
        do {
            let status = try await SubscriptionManager.shared.getSubscriptionStatus(forceRefresh: true)
            self.subscriptionStatus = status
            self.canAddServer = await SubscriptionManager.shared.canAddServer()
            self.remainingSlots = await SubscriptionManager.shared.remainingServerSlots()
            
            let token = await AuthService.shared.getToken() ?? ""
            let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
            let resultJSON = await APIBridge.shared.fetchServersAsync(baseURL: baseURL, token: token)
            if let serversData = parseGoServers(resultJSON) {
                self.servers = await SubscriptionManager.shared.getAccessibleServers(from: serversData)
            }
            
        } catch {
            AevonXCoreBridge.CoreLogger.shared.warning("Status poll failed: \(error.localizedDescription)", module: "ServerList")
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
            
            let token = await AuthService.shared.getToken() ?? ""
            let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
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
        
        let token = await AuthService.shared.getToken() ?? ""
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
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
        
        await SSHService.shared.setProgressHandler(for: serverId) { [weak self] stage, progress in
            Task { @MainActor [weak self] in
                self?.connectionProgress[serverId] = ConnectionProgress(
                    stage: stage,
                    message: stage.rawValue,
                    percentComplete: progress
                )
            }
        }
        
        do {
            let details = try await EphemeralDecryptionService.shared.decryptServerDetails(
                from: accessibleServer.server.toEncryptedPayload()
            )
            
            guard let connectionDetails = details["connection_details"] as? [String: Any],
                  let host = connectionDetails["host"] as? String,
                  let port = connectionDetails["port"] as? Int else {
                throw SSHConnectionError.invalidCredentials
            }
            
            let result = await SSHService.shared.testConnection(
                to: accessibleServer.server.toEncryptedPayload(),
                host: host,
                port: port,
                serverId: serverId
            )
            
            connectionResults[serverId] = result
            
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
