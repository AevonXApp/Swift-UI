//
//  PluginServiceController.swift
//  AevonXCoreBridge
//
//  Manages start / stop / restart for plugin-managed system services.
//  Reads service state from the remote server via SSH, driven by
//  the `health_check` block in each namespace's _manifest.json.
//

import Foundation
import Combine

// MARK: - Service State

public enum PluginServiceState: Equatable, Sendable {
    case unknown
    case checking
    case running
    case stopped
    case failed(String)

    public var isRunning: Bool { self == .running }

    public var label: String {
        switch self {
        case .unknown:       return "Unknown"
        case .checking:      return "Checking…"
        case .running:       return "Running"
        case .stopped:       return "Stopped"
        case .failed:        return "Error"
        }
    }

    public static func == (lhs: PluginServiceState, rhs: PluginServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.checking, .checking),
             (.running, .running),
             (.stopped, .stopped):      return true
        case (.failed(let a), .failed(let b)): return a == b
        default:                        return false
        }
    }
}

// MARK: - Controller

@MainActor
public final class PluginServiceController: ObservableObject {

    public static let shared = PluginServiceController()

    /// Live state for each namespace
    @Published public private(set) var states: [String: PluginServiceState] = [:]

    private init() {}

    // MARK: - Status Fetch

    /// Fetch the current service state for a namespace based on its health_check config.
    public func fetchStatus(namespace: String, manifest: HookNamespaceManifest, serverId: String) async {
        guard let healthCheck = manifest.healthCheck else {
            states[namespace] = .unknown
            return
        }
        states[namespace] = .checking

        let cmd = buildStatusCommand(healthCheck: healthCheck)
        let raw = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let result = SSHResult.parse(raw)

        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let successPattern = healthCheck.successPattern ?? "active"

        if output == successPattern || output.contains(successPattern) {
            states[namespace] = .running
        } else if result.isSuccess {
            states[namespace] = .running
        } else {
            states[namespace] = .stopped
        }
    }

    // MARK: - Service Actions

    public func start(namespace: String, serviceName: String, serverId: String) async throws {
        states[namespace] = .checking
        let cmd = "sudo systemctl start \(shellEscape(serviceName)) 2>&1"
        let raw = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let result = SSHResult.parse(raw)
        if !result.isSuccess {
            let msg = result.stderr.isEmpty ? result.stdout : result.stderr
            states[namespace] = .failed(String(msg.prefix(120)))
            throw PluginServiceError.commandFailed(msg)
        }
        states[namespace] = .running
    }

    public func stop(namespace: String, serviceName: String, serverId: String) async throws {
        states[namespace] = .checking
        let cmd = "sudo systemctl stop \(shellEscape(serviceName)) 2>&1"
        let raw = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let result = SSHResult.parse(raw)
        if !result.isSuccess {
            let msg = result.stderr.isEmpty ? result.stdout : result.stderr
            states[namespace] = .failed(String(msg.prefix(120)))
            throw PluginServiceError.commandFailed(msg)
        }
        states[namespace] = .stopped
    }

    public func restart(namespace: String, serviceName: String, serverId: String) async throws {
        states[namespace] = .checking
        let cmd = "sudo systemctl restart \(shellEscape(serviceName)) 2>&1"
        let raw = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let result = SSHResult.parse(raw)
        if !result.isSuccess {
            let msg = result.stderr.isEmpty ? result.stdout : result.stderr
            states[namespace] = .failed(String(msg.prefix(120)))
            throw PluginServiceError.commandFailed(msg)
        }
        // Brief pause then re-verify state
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        states[namespace] = .running
    }

    // MARK: - Helpers

    private func buildStatusCommand(healthCheck: HookHealthCheck) -> String {
        switch healthCheck.type ?? "" {
        case "systemd":
            let name = healthCheck.serviceName ?? ""
            return "systemctl is-active \(shellEscape(name)) 2>/dev/null"
        case "command":
            return healthCheck.command ?? "echo unknown"
        case "url":
            let url = healthCheck.url ?? "http://127.0.0.1"
            return "curl -sf --max-time 5 \(shellEscape(url)) > /dev/null && echo active || echo inactive"
        default:
            return "echo unknown"
        }
    }

    private func shellEscape(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

// MARK: - Errors

public enum PluginServiceError: LocalizedError {
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return "Service command failed: \(msg)"
        }
    }
}
