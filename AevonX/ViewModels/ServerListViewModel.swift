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

/// Decryption error types for better error handling
enum DecryptionErrorType: Equatable {
    case authenticationFailure  // CryptoKit error 3 - wrong key or corrupted data
    case missingDeviceKey       // Device key not found in Keychain
    case missingRecoveryKey     // Recovery key needed but not available
    case keyDerivationFailed    // Failed to derive encryption keys
    case corruptedData          // Data format is invalid
    case unknown(String)        // Other errors
    
    var localizedDescription: String {
        switch self {
        case .authenticationFailure:
            return "Authentication failed - incorrect key or corrupted data"
        case .missingDeviceKey:
            return "Device key not found - please re-setup encryption"
        case .missingRecoveryKey:
            return "Recovery key required to decrypt data"
        case .keyDerivationFailed:
            return "Failed to derive encryption keys"
        case .corruptedData:
            return "Encrypted data is corrupted"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var requiresRecoveryKey: Bool {
        switch self {
        case .authenticationFailure, .missingDeviceKey, .missingRecoveryKey:
            return true
        default:
            return false
        }
    }
}

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
    
    // MARK: - Decryption Error Handling
    
    @Published var decryptionError: DecryptionErrorType?
    @Published var showDecryptionError = false
    @Published var showRecoveryKeyInput = false
    @Published var failedServerIds: Set<String> = []
    
    // MARK: - Properties
    
    private var isInitialized = false
    private var statusPollingTask: Task<Void, Never>?
    private let statusPollInterval: TimeInterval = 60 // Poll every 60 seconds (was 30)
    private var hasPerformedBiometricAuthThisSession = false
    private var isInForeground = true
    
    // MARK: - Initialization
    
    func initialize() async {
        guard !isInitialized else { return }
        
        CoreLogger.shared.info("Initializing ServerListViewModel...", module: "ServerList")
        
        // Setup device key if needed
        do {
            _ = try await SplitKeyEncryptionService.shared.setupDeviceKey()
            CoreLogger.shared.info("Device key setup completed successfully", module: "ServerList")
            
            // Preload the key for the session (single biometric auth)
            _ = try await SplitKeyEncryptionService.shared.preloadKeys()
            CoreLogger.shared.info("Encryption keys preloaded for session", module: "ServerList")
        } catch {
            CoreLogger.shared.error("Device key setup/preload failed: \(error.localizedDescription)", module: "ServerList")
        }
        
        await refresh()
        isInitialized = true
        
        // Start polling for real-time status updates
        startStatusPolling()
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
            
            // Decrypt servers for display
            await decryptServersForDisplay()
            
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
            guard let self = self else { return }
            
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(self.statusPollInterval * 1_000_000_000))
                    
                    // Only refresh if we have servers AND app is in foreground
                    guard self.isInForeground, !self.servers.isEmpty else {
                        continue
                    }
                    
                    await self.refreshServerStatuses()
                } catch {
                    // Task was cancelled
                    break
                }
            }
        }
    }
    
    /// Call this when app enters foreground
    func onEnterForeground() {
        isInForeground = true
    }
    
    /// Call this when app enters background
    func onEnterBackground() {
        isInForeground = false
    }
    
    private func refreshServerStatuses() async {
        do {
            // Fetch just the subscription status to update server accessibility
            let status = try await SubscriptionManager.shared.getSubscriptionStatus(forceRefresh: true)
            self.subscriptionStatus = status
            self.canAddServer = await SubscriptionManager.shared.canAddServer()
            self.remainingSlots = await SubscriptionManager.shared.remainingServerSlots()
            
            // Update server access levels based on new subscription status
            let serverResponses = try await ServerAPIService.shared.fetchServers()
            self.servers = await SubscriptionManager.shared.getAccessibleServers(from: serverResponses)
            
        } catch {
            // Silent failure for polling - don't show error
            CoreLogger.shared.warning("Status poll failed: \(error.localizedDescription)", module: "ServerList")
        }
    }
    
    // MARK: - Decryption
    
    /// Analyzes a decryption error and returns the appropriate error type
    private func analyzeDecryptionError(_ error: Error) -> DecryptionErrorType {
        let errorDescription = error.localizedDescription.lowercased()
        let errorString = String(describing: error)
        
        // CryptoKit error 3 = authenticationFailure
        if errorString.contains("error 3") || errorDescription.contains("authentication") {
            return .authenticationFailure
        }
        
        // Check for missing key errors
        if errorDescription.contains("key not found") || errorDescription.contains("missing key") {
            if errorDescription.contains("device") {
                return .missingDeviceKey
            }
            if errorDescription.contains("recovery") {
                return .missingRecoveryKey
            }
        }
        
        // Check for derivation errors
        if errorDescription.contains("derivation") || errorDescription.contains("derive") {
            return .keyDerivationFailed
        }
        
        // Check for data corruption
        if errorDescription.contains("corrupt") || errorDescription.contains("invalid") || errorDescription.contains("format") {
            return .corruptedData
        }
        
        return .unknown(error.localizedDescription)
    }
    
    /// Decrypts all accessible servers for display
    private func decryptServersForDisplay() async {
        var decrypted: [ServerViewModel] = []
        var hasDecryptionErrors = false
        var firstError: DecryptionErrorType?
        
        // Reset failed servers tracking
        failedServerIds.removeAll()
        
        for accessibleServer in servers {
            do {
                // Build the encrypted payload from server response
                let payload = EncryptedServerPayload(
                    encryptedData: accessibleServer.server.encryptedPayload,
                    nonce: accessibleServer.server.payloadNonce,
                    authTag: accessibleServer.server.payloadAuthTag,
                    metadata: accessibleServer.server.encryptionMetadata
                )
                
                // Decrypt
                let serverData = try await SplitKeyEncryptionService.shared.decryptServer(
                    EncryptedServerData.self,
                    from: payload
                )
                
                // Create view model
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
                let errorType = analyzeDecryptionError(error)
                CoreLogger.shared.error("Failed to decrypt server \(accessibleServer.id): \(errorType.localizedDescription)", module: "ServerList")
                
                // Track the first error for user notification
                if firstError == nil {
                    firstError = errorType
                }
                hasDecryptionErrors = true
                failedServerIds.insert(accessibleServer.id)
                
                // Create placeholder for failed decryption with error info
                let placeholder = ServerViewModel(
                    id: accessibleServer.id,
                    name: "🔒 Decryption Failed",
                    host: errorType.localizedDescription,
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
        
        // Show error dialog if there were decryption failures
        if hasDecryptionErrors, let error = firstError {
            self.decryptionError = error
            self.showDecryptionError = true
            
            // If the error requires recovery key, show the input dialog
            if error.requiresRecoveryKey {
                self.showRecoveryKeyInput = true
            }
        }
    }
    
    /// Retry decryption with recovery key
    func retryDecryptionWithRecoveryKey(_ recoveryKey: String) async {
        CoreLogger.shared.info("Attempting to restore encryption with recovery key...", module: "ServerList")
        
        do {
            // Try to restore the encryption keys using recovery key
            let restored = try await SplitKeyEncryptionService.shared.restoreWithRecoveryKey(recoveryKey)
            
            if restored {
                CoreLogger.shared.info("Recovery key accepted, retrying decryption...", module: "ServerList")
                showRecoveryKeyInput = false
                showDecryptionError = false
                decryptionError = nil
                CoreLogger.shared.error("Recovery key was not accepted", module: "ServerList")
                decryptionError = .unknown("Invalid recovery key")
            }
        } catch {
            CoreLogger.shared.error("Failed to restore with recovery key: \(error.localizedDescription)", module: "ServerList")
            decryptionError = .unknown("Failed to restore keys: \(error.localizedDescription)")
        }
    }
    
    /// Dismiss decryption error
    func dismissDecryptionError() {
        showDecryptionError = false
        showRecoveryKeyInput = false
        decryptionError = nil
    }
    
    // MARK: - Server Management
    
    func addServer(_ request: AddServerRequest) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Convert to encrypted data structure
            let serverData = request.toEncryptedServerData()
            
            // 2. Require biometric authentication (with session caching)
            try await BiometricAuthManager.shared.authenticateIfNeeded(
                reason: "Encrypt and save server credentials"
            )
            
            // 3. Encrypt server data using Core encryption
            let encryptedPayload = try await SplitKeyEncryptionService.shared.encryptServer(serverData)
            
            // 4. Send encrypted payload to backend
            _ = try await ServerAPIService.shared.createServer(payload: encryptedPayload)
            
            // 5. Refresh list immediately to show new server
            await refresh()
            
        } catch ServerAPIError.serverLimitReached {
            errorMessage = "Server limit reached. Upgrade your plan to add more servers."
            showError = true
        } catch let error as EphemeralDecryptionError where error == .biometricAuthFailed {
            errorMessage = "Authentication failed. Please try again."
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
        
        // Set up progress tracking for UI
        await SSHService.shared.setProgressHandler(for: serverId) { [weak self] stage, progress in
            Task { @MainActor [weak self] in
                self?.connectionProgress[serverId] = ConnectionProgress(
                    stage: stage,
                    message: stage.rawValue,
                    percentComplete: progress
                )
            }
        }
        
        // Get server details from encrypted payload
        do {
            let details = try await EphemeralDecryptionService.shared.decryptServerDetails(
                from: accessibleServer.server.toEncryptedPayload()
            )
            
            guard let connectionDetails = details["connection_details"] as? [String: Any],
                  let host = connectionDetails["host"] as? String,
                  let port = connectionDetails["port"] as? Int else {
                throw SSHConnectionError.invalidCredentials
            }
            
            // Test SSH connection via Core service
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
