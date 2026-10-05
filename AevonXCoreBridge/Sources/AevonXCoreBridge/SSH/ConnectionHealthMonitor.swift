//
//  ConnectionHealthMonitor.swift
//  AevonXCore
//
//  Centralized connection health monitoring with automatic reconnection.
//  Detects connection loss from: network changes, keepalive failures,
//  device wake, and channel closure.
//

import Foundation

// MARK: - Connection Health Event

/// Events emitted by the health monitor for UI consumption
public enum ConnectionHealthEvent: Sendable {
    /// The SSH connection was lost, with a human-readable reason
    case connectionLost(serverId: String, reason: DisconnectReason)
    
    /// A reconnection attempt is in progress
    case reconnecting(serverId: String, attempt: Int, maxAttempts: Int, nextRetryIn: TimeInterval)
    
    /// Reconnection succeeded
    case reconnected(serverId: String)
    
    /// All reconnection attempts exhausted
    case reconnectionFailed(serverId: String, finalError: String)
    
    /// Network reachability changed (informational)
    case networkStatusChanged(NetworkStatus)
}

// MARK: - Disconnect Reason

/// The reason the connection was lost
public enum DisconnectReason: String, Sendable {
    case networkLost = "Network connection lost"
    case networkChanged = "Network interface changed"
    case serverUnreachable = "Server is unreachable"
    case keepaliveFailed = "Connection timed out"
    case deviceWoke = "Device woke from sleep"
    case sshChannelClosed = "SSH channel closed unexpectedly"
    case unknown = "Connection interrupted"
}

// MARK: - Reconnection State

/// Internal state for tracking reconnection per server
private struct ReconnectionState: Sendable {
    let serverId: String
    var attempt: Int = 0
    var isReconnecting: Bool = false
    var lastReason: DisconnectReason = .unknown
    var reconnectTask: Task<Void, Never>?
}

// MARK: - Connection Health Monitor

/// Actor that monitors SSH connection health and coordinates reconnection.
///
/// Responsibilities:
/// - Listens to `NetworkMonitor` for reachability changes
/// - Tracks keepalive failures from `SSHService`
/// - Handles device wake reconnection checks
/// - Orchestrates reconnection with exponential backoff
/// - Emits `ConnectionHealthEvent` for UI layer consumption
///
/// The monitor does NOT hold SSH credentials or perform the actual SSH handshake.
/// Instead, it calls a `reconnectionHandler` callback that the UI sets, which
/// triggers the full CAT-based connection flow.
public actor ConnectionHealthMonitor {
    
    // MARK: - Singleton
    
    public static let shared = ConnectionHealthMonitor()
    
    // MARK: - Configuration
    
    private let maxAttempts: Int = InternalConfiguration.reconnectionMaxAttempts
    private let baseDelay: TimeInterval = InternalConfiguration.reconnectionBaseDelay
    private let maxDelay: TimeInterval = InternalConfiguration.reconnectionMaxDelay
    private let keepAliveFailureThreshold: Int = InternalConfiguration.keepAliveFailureThreshold
    
    // MARK: - Properties
    
    /// Reconnection state per server
    private var states: [String: ReconnectionState] = [:]
    
    /// Keepalive failure counters per server
    private var keepAliveFailureCounts: [String: Int] = [:]
    
    /// Callback invoked when the monitor needs to reconnect.
    /// Set by the UI layer. Returns `true` if reconnection succeeded.
    private var reconnectionHandler: (@Sendable (String) async -> Bool)?
    
    /// Event continuations for broadcasting
    private var eventContinuations: [UUID: AsyncStream<ConnectionHealthEvent>.Continuation] = [:]
    
    /// Network monitoring task
    private var networkMonitorTask: Task<Void, Never>?
    
    /// Servers being actively monitored
    private var monitoredServers: Set<String> = []
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Sets the reconnection handler. Called by the UI layer to provide
    /// the actual reconnection logic (CAT request, SSH connect, etc.)
    ///
    /// - Parameter handler: Async closure that takes a serverId and returns
    ///   `true` if reconnection succeeded, `false` otherwise.
    public func setReconnectionHandler(_ handler: @escaping @Sendable (String) async -> Bool) {
        self.reconnectionHandler = handler
    }
    
    /// Starts monitoring a server's connection health.
    /// - Parameter serverId: The server to monitor
    public func startMonitoring(serverId: String) {
        monitoredServers.insert(serverId)
        keepAliveFailureCounts[serverId] = 0
        
        // Start network monitoring if not already running
        if networkMonitorTask == nil {
            startNetworkMonitoring()
        }
        
        CoreLogger.shared.info("Health monitoring started for server: \(serverId)", module: "HealthMonitor")
    }
    
    /// Stops monitoring a server's connection health.
    /// Also cancels any in-progress reconnection.
    /// - Parameter serverId: The server to stop monitoring
    public func stopMonitoring(serverId: String) {
        monitoredServers.remove(serverId)
        
        // Cancel any reconnection in progress
        states[serverId]?.reconnectTask?.cancel()
        states.removeValue(forKey: serverId)
        keepAliveFailureCounts.removeValue(forKey: serverId)
        
        // Stop network monitoring if no servers remain
        if monitoredServers.isEmpty {
            networkMonitorTask?.cancel()
            networkMonitorTask = nil
        }
        
        CoreLogger.shared.info("Health monitoring stopped for server: \(serverId)", module: "HealthMonitor")
    }
    
    /// Creates an async stream of health events.
    /// - Returns: Stream that yields `ConnectionHealthEvent` values
    public func eventStream() -> AsyncStream<ConnectionHealthEvent> {
        let id = UUID()
        
        return AsyncStream { continuation in
            self.eventContinuations[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeContinuation(id: id)
                }
            }
        }
    }
    
    /// Reports a keepalive failure from `SSHService`.
    /// After `keepAliveFailureThreshold` consecutive failures, triggers reconnection.
    /// - Parameter serverId: The affected server
    public func reportKeepAliveFailure(serverId: String) {
        guard monitoredServers.contains(serverId) else { return }
        
        let count = (keepAliveFailureCounts[serverId] ?? 0) + 1
        keepAliveFailureCounts[serverId] = count
        
        CoreLogger.shared.warning(
            "Keepalive failure #\(count)/\(keepAliveFailureThreshold) for \(serverId)",
            module: "HealthMonitor"
        )
        
        if count >= keepAliveFailureThreshold {
            CoreLogger.shared.error(
                "Keepalive failure threshold reached for \(serverId) — triggering reconnection",
                module: "HealthMonitor"
            )
            keepAliveFailureCounts[serverId] = 0
            
            Task {
                await attemptReconnection(serverId: serverId, reason: .keepaliveFailed)
            }
        }
    }
    
    /// Reports a successful keepalive, resetting the failure counter.
    /// - Parameter serverId: The server that responded
    public func reportKeepAliveSuccess(serverId: String) {
        keepAliveFailureCounts[serverId] = 0
    }
    
    /// Reports that an SSH command failed with a connection-level error.
    /// This triggers immediate reconnection (no threshold).
    /// - Parameters:
    ///   - serverId: The affected server
    ///   - error: The error that occurred
    public func reportCommandFailure(serverId: String, error: Error) {
        guard monitoredServers.contains(serverId) else { return }
        
        let message = String(describing: error).lowercased()
        
        // Only trigger reconnection for connection-level errors, not command failures
        let isConnectionError = message.contains("not connected")
            || message.contains("channel closed")
            || message.contains("connection reset")
            || message.contains("broken pipe")
            || message.contains("ioerror")
        
        guard isConnectionError else { return }
        
        CoreLogger.shared.warning(
            "Connection-level command failure for \(serverId): \(error.localizedDescription)",
            module: "HealthMonitor"
        )
        
        Task {
            await attemptReconnection(serverId: serverId, reason: .sshChannelClosed)
        }
    }
    
    /// Called when the device wakes from sleep. Triggers a health check
    /// on all monitored servers.
    public func deviceDidWake() {
        CoreLogger.shared.info("Device woke — checking health of \(monitoredServers.count) server(s)", module: "HealthMonitor")
        
        for serverId in monitoredServers {
            Task {
                await attemptReconnection(serverId: serverId, reason: .deviceWoke)
            }
        }
    }
    
    /// Cancels reconnection for a specific server.
    /// - Parameter serverId: The server to cancel reconnection for
    public func cancelReconnection(serverId: String) {
        states[serverId]?.reconnectTask?.cancel()
        states[serverId]?.isReconnecting = false
        states[serverId]?.attempt = 0
        
        CoreLogger.shared.info("Reconnection cancelled for \(serverId)", module: "HealthMonitor")
    }
    
    /// Whether a server is currently reconnecting
    public func isReconnecting(serverId: String) -> Bool {
        return states[serverId]?.isReconnecting ?? false
    }
    
    // MARK: - Reconnection Logic
    
    /// Initiates the reconnection flow with exponential backoff.
    ///
    /// Flow:
    /// 1. Emit `.connectionLost` event
    /// 2. Wait for network to be available (if network-triggered)
    /// 3. Attempt reconnection via handler
    /// 4. On failure: wait with exponential backoff, retry
    /// 5. After max attempts: emit `.reconnectionFailed`
    public func attemptReconnection(serverId: String, reason: DisconnectReason) async {
        // Don't reconnect if already reconnecting
        if let existing = states[serverId], existing.isReconnecting {
            CoreLogger.shared.debug("Already reconnecting \(serverId), skipping duplicate", module: "HealthMonitor")
            return
        }
        
        // Initialize state
        var state = ReconnectionState(serverId: serverId)
        state.isReconnecting = true
        state.lastReason = reason
        states[serverId] = state
        
        // Notify: connection lost
        emitEvent(.connectionLost(serverId: serverId, reason: reason))
        
        CoreLogger.shared.warning(
            "Connection lost for \(serverId): \(reason.rawValue) — starting reconnection",
            module: "HealthMonitor"
        )
        
        // Create the reconnection task
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            // Hoist actor-isolated constants to avoid 'await' in operator expressions
            let maxAttempts = await self.maxAttempts
            let baseDelay = await self.baseDelay
            let maxDelay = await self.maxDelay
            
            var attempt = 0
            
            while attempt < maxAttempts {
                guard !Task.isCancelled else {
                    await self.emitEvent(.reconnectionFailed(serverId: serverId, finalError: "Cancelled"))
                    return
                }
                
                attempt += 1
                
                // Calculate delay with exponential backoff
                let delay = min(
                    baseDelay * pow(2.0, Double(attempt - 1)),
                    maxDelay
                )
                
                // Update state
                await self.updateReconnectionState(serverId: serverId, attempt: attempt)
                
                // Emit reconnecting event
                await self.emitEvent(.reconnecting(
                    serverId: serverId,
                    attempt: attempt,
                    maxAttempts: maxAttempts,
                    nextRetryIn: delay
                ))
                
                CoreLogger.shared.info(
                    "Reconnection attempt \(attempt)/\(maxAttempts) for \(serverId) (delay: \(String(format: "%.1f", delay))s)",
                    module: "HealthMonitor"
                )
                
                // Wait for network if disconnected (no point in trying without network)
                let isReachable = await NetworkMonitor.shared.isReachable
                if !isReachable {
                    CoreLogger.shared.info("Waiting for network before reconnection attempt...", module: "HealthMonitor")
                    await self.waitForNetwork()
                    
                    guard !Task.isCancelled else { return }
                }
                
                // Wait for backoff delay
                if attempt > 1 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                } else {
                    // First attempt: short delay to avoid instant retry
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    guard !Task.isCancelled else { return }
                }
                
                // Attempt reconnection via handler
                if let handler = await self.reconnectionHandler {
                    let success = await handler(serverId)
                    
                    if success {
                        CoreLogger.shared.info(
                            "Reconnection succeeded for \(serverId) on attempt \(attempt)",
                            module: "HealthMonitor"
                        )
                        
                        // Reset state
                        await self.clearReconnectionState(serverId: serverId)
                        await self.emitEvent(.reconnected(serverId: serverId))
                        return
                    } else {
                        CoreLogger.shared.warning(
                            "Reconnection attempt \(attempt) failed for \(serverId)",
                            module: "HealthMonitor"
                        )
                    }
                } else {
                    CoreLogger.shared.error(
                        "No reconnection handler set — cannot reconnect \(serverId)",
                        module: "HealthMonitor"
                    )
                    await self.clearReconnectionState(serverId: serverId)
                    await self.emitEvent(.reconnectionFailed(
                        serverId: serverId,
                        finalError: "No reconnection handler configured"
                    ))
                    return
                }
            }
            
            // All attempts exhausted
            CoreLogger.shared.error(
                "All \(maxAttempts) reconnection attempts failed for \(serverId)",
                module: "HealthMonitor"
            )
            await self.clearReconnectionState(serverId: serverId)
            await self.emitEvent(.reconnectionFailed(
                serverId: serverId,
                finalError: "Maximum reconnection attempts (\(maxAttempts)) reached"
            ))
        }
        
        states[serverId]?.reconnectTask = task
    }
    
    // MARK: - Private Methods
    
    /// Updates the attempt counter in the state
    private func updateReconnectionState(serverId: String, attempt: Int) {
        states[serverId]?.attempt = attempt
    }
    
    /// Clears reconnection state after success or final failure
    private func clearReconnectionState(serverId: String) {
        states[serverId]?.isReconnecting = false
        states[serverId]?.attempt = 0
        states[serverId]?.reconnectTask = nil
    }
    
    /// Starts listening to NetworkMonitor for reachability changes
    private func startNetworkMonitoring() {
        networkMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Ensure NetworkMonitor is running
            await NetworkMonitor.shared.start()
            
            var previousStatus: NetworkStatus?
            
            for await status in await NetworkMonitor.shared.statusStream() {
                guard !Task.isCancelled else { break }
                
                // Emit network status change event
                await self.emitEvent(.networkStatusChanged(status))
                
                // Detect transitions
                if let previous = previousStatus {
                    switch (previous, status) {
                    case (.connected, .disconnected):
                        // Network just went down → trigger reconnection for all monitored servers
                        for serverId in await self.monitoredServers {
                            await self.attemptReconnection(serverId: serverId, reason: .networkLost)
                        }
                        
                    case (.connected(let oldIface), .connected(let newIface)) where oldIface != newIface:
                        // Network interface changed (e.g., WiFi → Ethernet)
                        // The SSH socket may or may not survive this — check health
                        for serverId in await self.monitoredServers {
                            await self.attemptReconnection(serverId: serverId, reason: .networkChanged)
                        }
                        
                    default:
                        break
                    }
                }
                
                previousStatus = status
            }
        }
    }
    
    /// Waits until the network becomes reachable again (max 60s)
    private func waitForNetwork() async {
        let deadline = Date().addingTimeInterval(60)
        
        while !Task.isCancelled && Date() < deadline {
            if await NetworkMonitor.shared.isReachable {
                return
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // Check every 0.5s
        }
    }
    
    /// Emits a health event to all subscribers
    private func emitEvent(_ event: ConnectionHealthEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }
    
    /// Removes a stream continuation
    private func removeContinuation(id: UUID) {
        eventContinuations.removeValue(forKey: id)
    }
}
