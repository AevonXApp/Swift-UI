//
//  PluginNotificationCenter.swift
//  AevonX
//
//  Persistent notification system for plugins. Tracks badge counts
//  and notification history. Plugins define polling commands in manifests.
//

import SwiftUI
import Combine
import AevonXCoreBridge

public struct PluginNotification: Identifiable {
    public let id = UUID()
    public let namespace: String
    public let title: String
    public let message: String
    public let severity: AevonXCoreBridge.HookAlertSeverity
    public let timestamp: Date
    public var isRead: Bool = false

    public init(namespace: String, title: String, message: String, severity: AevonXCoreBridge.HookAlertSeverity = .info) {
        self.namespace = namespace
        self.title = title
        self.message = message
        self.severity = severity
        self.timestamp = Date()
    }
}

// MARK: - Notification Center

@MainActor
public final class PluginNotificationCenter: ObservableObject {
    public static let shared = PluginNotificationCenter()

    @Published public private(set) var notifications: [PluginNotification] = []
    @Published public private(set) var unreadCount: Int = 0

    private init() {}

    /// Add a new notification
    public func post(namespace: String, title: String, message: String, severity: AevonXCoreBridge.HookAlertSeverity = .info) {
        let notification = PluginNotification(namespace: namespace, title: title, message: message, severity: severity)
        notifications.insert(notification, at: 0)

        // Keep max 100 notifications
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }

        updateUnreadCount()
    }

    /// Mark a specific notification as read
    public func markRead(_ id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            updateUnreadCount()
        }
    }

    /// Mark all notifications as read
    public func markAllRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
    }

    /// Clear all notifications for a namespace
    public func clear(namespace: String) {
        notifications.removeAll { $0.namespace == namespace }
        updateUnreadCount()
    }

    /// Clear all notifications
    public func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
    }

    /// Get notifications for a specific namespace
    public func notifications(for namespace: String) -> [PluginNotification] {
        notifications.filter { $0.namespace == namespace }
    }

    /// Get unread count for a specific namespace
    public func unreadCount(for namespace: String) -> Int {
        notifications.filter { $0.namespace == namespace && !$0.isRead }.count
    }

    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
}

// MARK: - Health Monitor

@MainActor
public final class PluginHealthMonitor: ObservableObject {
    public static let shared = PluginHealthMonitor()

    @Published public private(set) var healthStatuses: [String: HealthStatus] = [:]
    private var monitorTasks: [String: Task<Void, Never>] = [:]

    public enum HealthStatus: Equatable {
        case unknown
        case healthy
        case unhealthy(String)
        case checking
    }

    private init() {}

    /// Start monitoring health for a namespace
    public func startMonitoring(namespace: String, healthCheck: AevonXCoreBridge.HookHealthCheck, serverId: String) {
        stopMonitoring(namespace: namespace)

        let interval = healthCheck.interval ?? 30

        // Build the health check command based on type
        let command: String
        let pattern: String

        switch healthCheck.type {
        case "systemd":
            let svcName = healthCheck.serviceName ?? namespace
            command = "systemctl is-active \(svcName)"
            pattern = "active"
        case "http":
            // Plugin must provide URL in manifest (e.g. url: "http://127.0.0.1:9443/healthz")
            guard let url = healthCheck.url ?? healthCheck.command else { return }
            command = "curl -sf \(url)"
            pattern = healthCheck.successPattern ?? "ok"
        default:
            // Generic command type — plugin provides the full command
            guard let cmd = healthCheck.command else { return }
            command = cmd
            pattern = healthCheck.successPattern ?? "ok"
        }

        healthStatuses[namespace] = .checking

        monitorTasks[namespace] = Task {
            while !Task.isCancelled {
                await checkHealth(
                    namespace: namespace,
                    command: command,
                    pattern: pattern,
                    serverId: serverId
                )
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    /// Stop monitoring for a namespace
    public func stopMonitoring(namespace: String) {
        monitorTasks[namespace]?.cancel()
        monitorTasks[namespace] = nil
    }

    /// Stop all monitoring
    public func stopAll() {
        for (_, task) in monitorTasks {
            task.cancel()
        }
        monitorTasks.removeAll()
        healthStatuses.removeAll()
    }

    /// Get health status for a namespace
    public func status(for namespace: String) -> HealthStatus {
        healthStatuses[namespace] ?? .unknown
    }

    private func checkHealth(namespace: String, command: String, pattern: String, serverId: String) async {
        let raw = await SSHBridge.shared.executeAsync(serverID: serverId, command: command)
        let result = SSHResult.parse(raw)
        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        if output.contains(pattern) {
            healthStatuses[namespace] = .healthy
        } else {
            healthStatuses[namespace] = .unhealthy(output)
        }
    }
}
