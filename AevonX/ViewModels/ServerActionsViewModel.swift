//
//  ServerActionsViewModel.swift
//  AevonX
//
//  Handles server-level actions: restart services, reboot, shutdown.
//  Extracted from ServerConnectionViewModel for single-responsibility.
//

import SwiftUI
import Combine
import AevonXCore
import AevonXCoreBridge

@MainActor
public class ServerActionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether a server reboot confirmation is showing
    @Published var isRestartConfirming: Bool = false
    
    /// Whether a server shutdown confirmation is showing
    @Published var isShutdownConfirming: Bool = false
    
    // MARK: - Private Properties
    
    private let serverId: String
    private let sshService: any SSHServiceProtocol = SSHBridge.shared
    
    /// Callback to trigger disconnect (set by parent)
    var onDisconnectNeeded: (() async -> Void)?
    
    /// Callback to show error (set by parent)
    var onError: ((String) -> Void)?
    
    /// Callback to refresh stats after action (set by parent)
    var onRefreshStats: (() async -> Void)?
    
    /// Connection check (set by parent)
    var isConnected: Bool = false
    
    // MARK: - Init
    
    init(serverId: String) {
        self.serverId = serverId
    }
    
    // MARK: - Actions
    
    /// Restart server services (nginx, mysql, etc)
    func restartServices() async {
        guard isConnected else { return }
        
        AevonXCoreBridge.CoreLogger.shared.info("Restarting services...", module: "ServerActions")
        
        do {
            _ = try await executeCommand(CommandTemplate.services(.restartNginx))
            _ = try? await executeCommand(CommandTemplate.services(.restartMySQL))
            _ = try? await executeCommand(CommandTemplate.services(.restartPHPFPM))
            
            AevonXCoreBridge.CoreLogger.shared.info("Services restarted successfully", module: "ServerActions")
            await onRefreshStats?()
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to restart services: \(error.localizedDescription)", module: "ServerActions")
        }
    }
    
    /// Reboots the entire server host
    func rebootServer() async {
        guard isConnected else { return }
        
        AevonXCoreBridge.CoreLogger.shared.warning("Initiating server reboot...", module: "ServerActions")
        
        do {
            try await SystemControlService.shared.reboot(serverId: serverId)
            await onDisconnectNeeded?()
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to reboot server: \(error.localizedDescription)", module: "ServerActions")
            onError?("Reboot failed: \(error.localizedDescription)")
        }
    }
    
    /// Shuts down the entire server host
    func shutdownServer() async {
        guard isConnected else { return }
        
        AevonXCoreBridge.CoreLogger.shared.warning("Initiating server shutdown...", module: "ServerActions")
        
        do {
            try await SystemControlService.shared.shutdown(serverId: serverId)
            await onDisconnectNeeded?()
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to shutdown server: \(error.localizedDescription)", module: "ServerActions")
            onError?("Shutdown failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private
    
    private func executeCommand(_ command: CommandTemplate) async throws -> AevonXCore.SSHCommandResult {
        let commandString = command.build()
        return try await sshService.execute(commandString, serverId: serverId)
    }
}
