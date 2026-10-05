//
//  NetworkMonitor.swift
//  AevonXCore
//
//  Network reachability monitor using NWPathMonitor
//  Publishes network status changes for connection health tracking
//

import Foundation
import Network

// MARK: - Network Status

/// Current network reachability status
public enum NetworkStatus: Sendable, Equatable {
    /// Network is available via the given interface
    case connected(interfaceType: NetworkInterfaceType)
    /// No network connectivity
    case disconnected
    /// Network requires user action (e.g. captive portal)
    case requiresConnection
}

/// Type of network interface in use
public enum NetworkInterfaceType: String, Sendable {
    case wifi = "Wi-Fi"
    case cellular = "Cellular"
    case wiredEthernet = "Ethernet"
    case loopback = "Loopback"
    case other = "Other"
}

// MARK: - Network Monitor

/// Actor-based NWPathMonitor wrapper for tracking network reachability.
///
/// Usage:
/// ```swift
/// let monitor = NetworkMonitor.shared
/// await monitor.start()
///
/// for await status in await monitor.statusStream() {
///     switch status {
///     case .connected(let iface):
///         print("Connected via \(iface.rawValue)")
///     case .disconnected:
///         print("Network lost")
///     }
/// }
/// ```
public actor NetworkMonitor {
    
    // MARK: - Singleton
    
    public static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    /// The underlying NWPathMonitor
    private var monitor: NWPathMonitor?
    
    /// Dedicated queue for NWPathMonitor callbacks
    private let monitorQueue = DispatchQueue(label: "app.aevonx.network-monitor", qos: .utility)
    
    /// Current network status
    private var _currentStatus: NetworkStatus = .disconnected
    
    /// Whether the monitor is currently running
    private var isMonitoring: Bool = false
    
    /// Continuations for broadcasting status changes
    private var continuations: [UUID: AsyncStream<NetworkStatus>.Continuation] = [:]
    
    /// Previous network path for detecting interface changes
    private var previousInterfaceType: NetworkInterfaceType?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Current network status snapshot
    public var currentStatus: NetworkStatus {
        return _currentStatus
    }
    
    /// Whether the network is currently reachable
    public var isReachable: Bool {
        if case .connected = _currentStatus {
            return true
        }
        return false
    }
    
    /// Starts monitoring network reachability.
    /// Safe to call multiple times — subsequent calls are no-ops.
    public func start() {
        guard !isMonitoring else { return }
        
        let monitor = NWPathMonitor()
        self.monitor = monitor
        self.isMonitoring = true
        
        // NWPathMonitor requires its handler to be set before starting
        // We need to bridge from the callback world to actor world
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: monitorQueue)
        
        CoreLogger.shared.info("NetworkMonitor started", module: "NetworkMonitor")
    }
    
    /// Stops monitoring network reachability.
    public func stop() {
        guard isMonitoring else { return }
        
        monitor?.cancel()
        monitor = nil
        isMonitoring = false
        
        // Finish all active streams
        for (id, continuation) in continuations {
            continuation.finish()
            continuations.removeValue(forKey: id)
        }
        
        CoreLogger.shared.info("NetworkMonitor stopped", module: "NetworkMonitor")
    }
    
    /// Creates an async stream that yields network status changes.
    /// The stream immediately yields the current status on subscription.
    public func statusStream() -> AsyncStream<NetworkStatus> {
        let id = UUID()
        
        return AsyncStream { [weak self] continuation in
            Task { [weak self] in
                guard let self = self else {
                    continuation.finish()
                    return
                }
                
                // Register the continuation
                await self.registerContinuation(id: id, continuation: continuation)
                
                // Immediately yield current status
                let current = await self.currentStatus
                continuation.yield(current)
                
                continuation.onTermination = { _ in
                    Task { [weak self] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func registerContinuation(id: UUID, continuation: AsyncStream<NetworkStatus>.Continuation) {
        continuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    /// Processes an NWPath update from the monitor
    private func handlePathUpdate(_ path: NWPath) {
        let newStatus: NetworkStatus
        let newInterfaceType: NetworkInterfaceType
        
        switch path.status {
        case .satisfied:
            newInterfaceType = resolveInterfaceType(path)
            newStatus = .connected(interfaceType: newInterfaceType)
            
        case .unsatisfied:
            newInterfaceType = .other
            newStatus = .disconnected
            
        case .requiresConnection:
            newInterfaceType = .other
            newStatus = .requiresConnection
            
        @unknown default:
            newInterfaceType = .other
            newStatus = .disconnected
        }
        
        // Only emit if status actually changed
        guard newStatus != _currentStatus else { return }
        
        let oldStatus = _currentStatus
        _currentStatus = newStatus
        
        // Detect interface change (WiFi → Ethernet, etc.)
        let interfaceChanged = previousInterfaceType != nil && previousInterfaceType != newInterfaceType
        previousInterfaceType = newInterfaceType
        
        // Log the change
        CoreLogger.shared.info(
            "Network status changed: \(statusDescription(oldStatus)) → \(statusDescription(newStatus))\(interfaceChanged ? " (interface changed)" : "")",
            module: "NetworkMonitor"
        )
        
        // Broadcast to all subscribers
        for continuation in continuations.values {
            continuation.yield(newStatus)
        }
    }
    
    /// Resolves the primary network interface type from an NWPath
    private func resolveInterfaceType(_ path: NWPath) -> NetworkInterfaceType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .other
        }
    }
    
    /// Human-readable description for logging
    private func statusDescription(_ status: NetworkStatus) -> String {
        switch status {
        case .connected(let iface):
            return "Connected (\(iface.rawValue))"
        case .disconnected:
            return "Disconnected"
        case .requiresConnection:
            return "Requires Connection"
        }
    }
}
