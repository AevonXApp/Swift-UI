//
//  SystemControlService.swift
//  AevonXCoreBridge
//
//  Created on 2026-02-16.
//  Core Service for host-level operations
//

import Foundation

public actor SystemControlService {
    
    // MARK: - Singleton
    
    public static let shared = SystemControlService()
    
    // MARK: - Properties
    
    public var sshService: (any SSHServiceProtocol)?
    
    private init() {}
    
    /// Set SSH service from app layer (inject Go SSH).
    public func setSSHService(_ service: any SSHServiceProtocol) {
        self.sshService = service
    }
    
    // MARK: - Host Operations
    
    /// Reboots the host server
    /// - Parameter serverId: Target server identifier
    /// - Throws: SSH error if command execution fails
    public func reboot(serverId: String) async throws {
        CoreLogger.shared.warning("[SystemControlService] Initiating system REBOOT for server: \(serverId)", module: "SystemControl")
        
        guard let ssh = sshService else {
            CoreLogger.shared.error("[SystemControlService] SSH service not configured", module: "SystemControl")
            return
        }
        let command = "sudo reboot"
        do {
            _ = try await ssh.execute(command, serverId: serverId)
        } catch {
            // Check if error is due to connection closure (expected for reboot)
            CoreLogger.shared.info("[SystemControlService] Reboot command issued. Connection closure expected.", module: "SystemControl")
            // We still propagate for the UI to handle the disconnection
            throw error
        }
    }
    
    /// Shuts down the host server
    /// - Parameter serverId: Target server identifier
    /// - Throws: SSH error if command execution fails
    public func shutdown(serverId: String) async throws {
        CoreLogger.shared.warning("[SystemControlService] Initiating system SHUTDOWN for server: \(serverId)", module: "SystemControl")
        
        guard let ssh = sshService else {
            CoreLogger.shared.error("[SystemControlService] SSH service not configured", module: "SystemControl")
            return
        }
        let command = "sudo shutdown -h now"
        do {
            _ = try await ssh.execute(command, serverId: serverId)
        } catch {
            CoreLogger.shared.info("[SystemControlService] Shutdown command issued. Connection closure expected.", module: "SystemControl")
            throw error
        }
    }
}
