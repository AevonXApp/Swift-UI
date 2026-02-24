//
//  ServerListViewModel.swift
//  AevonX
//
//  ViewModel for managing the server list with zero-knowledge encryption
//  Real-time updates via polling
//

import SwiftUI
import AevonXCore
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
        CoreLogger.shared.info("🔵 initialize() called - isInitialized: \(isInitialized)", module: "ServerList")

        guard !isInitialized else {
            CoreLogger.shared.warning("⚠️ Already initialized — skipping", module: "ServerList")
            return
        }

        CoreLogger.shared.info("🟢 Starting initialization...", module: "ServerList")
        isInitialized = true

        await setupEncryption()
        await refresh()
        startStatusPolling()
        
        CoreLogger.shared.info("✅ Initialization complete", module: "ServerList")
    }

    private func setupEncryption() async {
        let hasKey = EncryptionKeyStore.shared.hasKey()
        
        if !hasKey {
            CoreLogger.shared.warning("⚠️ No encryption key — user needs to set up", module: "ServerList")
            return
        }
        
        // Load key into memory cache (instant file read, no prompts)
        do {
            _ = try await EncryptionKeyStore.shared.getKey()
            CoreLogger.shared.info("✅ Encryption key ready", module: "ServerList")
        } catch {
            CoreLogger.shared.error("Failed to load encryption key: \(error.localizedDescription)", module: "ServerList")
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

        do {
            // Fetch subscription status
            let status = try await SubscriptionManager.shared.getSubscriptionStatus(forceRefresh: true)
            self.subscriptionStatus = status
            self.canAddServer = await SubscriptionManager.shared.canAddServer()
            self.remainingSlots = await SubscriptionManager.shared.remainingServerSlots()

            // Fetch servers from Core - real data from backend
            let serverResponses = try await ServerAPIService.shared.fetchServers()
            self.servers = await SubscriptionManager.shared.getAccessibleServers(from: serverResponses)

            // Only decrypt if we have encryption key (simple file check, no actor hops)
            let hasKey = EncryptionKeyStore.shared.hasKey()
            if hasKey {
                await decryptServersForDisplay()
            } else {
                CoreLogger.shared.warning("Encryption key not available, skipping server decryption", module: "ServerList")
                self.decryptedServers = []
            }
            
        } catch let error as ServerAPIError {
            if case .serverNotAccessible = error {
                isAuthenticated = false
                errorMessage = "Session expired. Please log in again."
            } else {
                errorMessage = "Failed to load servers: \(error.localizedDescription)"
            }
            showError = true
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
            
            let serverResponses = try await ServerAPIService.shared.fetchServers()
            self.servers = await SubscriptionManager.shared.getAccessibleServers(from: serverResponses)
            
        } catch {
            CoreLogger.shared.warning("Status poll failed: \(error.localizedDescription)", module: "ServerList")
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
                CoreLogger.shared.info("Decrypted server: \(serverData.serverIdentity.name)", module: "ServerList")
                
            } catch {
                CoreLogger.shared.error("Failed to decrypt server \(accessibleServer.id): \(error.localizedDescription)", module: "ServerList")
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
        CoreLogger.shared.info("Retrying decryption with provided key...", module: "ServerList")
        
        do {
            try await EncryptionKeyStore.shared.saveKey(key)
            showEncryptionKeyInput = false
            encryptionError = nil
            
            // Retry decryption
            await decryptServersForDisplay()
        } catch {
            CoreLogger.shared.error("Failed to save key: \(error.localizedDescription)", module: "ServerList")
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
            // 1. Convert to encrypted data structure
            let serverData = request.toEncryptedServerData()
            
            // 2. Encrypt server data using new ServerEncryptionService
            //    (biometric is handled by EncryptionKeyStore on first access)
            let encryptedPayload = try await ServerEncryptionService.shared.encryptServer(serverData)
            
            // 3. Send encrypted payload to backend (with plaintext server_name for tracking)
            _ = try await ServerAPIService.shared.createServer(payload: encryptedPayload, serverName: request.name)
            
            // 4. Refresh list immediately to show new server
            await refresh()
            
        } catch ServerAPIError.serverLimitReached {
            errorMessage = "Server limit reached. Upgrade your plan to add more servers."
            showError = true
        } catch {
            errorMessage = "Failed to add server: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func deleteServer(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await ServerAPIService.shared.deleteServer(id: id)
            await refresh()
        } catch {
            errorMessage = "Failed to delete server: \(error.localizedDescription)"
            showError = true
        }
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
}

// MARK: - Connection Progress

struct ConnectionProgress {
    let stage: ConnectionStage
    let message: String
    let percentComplete: Double
}
