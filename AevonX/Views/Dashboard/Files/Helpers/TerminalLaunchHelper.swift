//
//  TerminalLaunchHelper.swift
//  AevonX
//
//  Open terminal at a specific server path
//  Integrates with the existing Terminal tab
//

import SwiftUI
import AevonXCore

// MARK: - Terminal Launch Helper

struct TerminalLaunchHelper {
    
    /// Open a terminal session cd'd to the given path
    /// Posts a notification that the Terminal tab can consume
    static func openTerminal(at path: String, serverId: String) {
        let safePath = ShellSanitizer.escapePath(path)
        let command = "cd \(safePath)"
        
        // Post notification for terminal integration
        NotificationCenter.default.post(
            name: .openTerminalAtPath,
            object: nil,
            userInfo: [
                "serverId": serverId,
                "path": path,
                "command": command
            ]
        )
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let openTerminalAtPath = Notification.Name("ax.openTerminalAtPath")
}
