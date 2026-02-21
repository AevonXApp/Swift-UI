//
//  ServerWebsitesViewModel.swift
//  AevonX
//
//  Manages website listing and operations.
//  Extracted from ServerConnectionViewModel for single-responsibility.
//

import SwiftUI
import AevonXCore
import Combine

// MARK: - Server Websites ViewModel

/// Manages website listing and operations for a connected server.
@MainActor
public class ServerWebsitesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of websites on the server
    @Published private(set) var websites: [CoreWebsiteInfo] = []
    
    /// Whether websites are being loaded
    @Published private(set) var isLoading: Bool = false
    
    /// Error from website loading, if any
    @Published private(set) var error: String?
    
    /// Count of websites
    var count: Int { websites.count }
    
    // MARK: - Private Properties
    
    private let serverId: String
    
    // MARK: - Initialization
    
    init(serverId: String) {
        self.serverId = serverId
    }
    
    // MARK: - Website Loading
    
    /// Load all websites from the server.
    func loadWebsites() async {
        isLoading = true
        error = nil
        
        do {
            let loadedWebsites = try await WebsiteListService.shared.listWebsites(serverId: serverId)
            websites = loadedWebsites
            
            CoreLogger.shared.info("Loaded \(websites.count) websites", module: "ServerWebsites")
        } catch {
            CoreLogger.shared.error("Failed to load websites: \(error.localizedDescription)", module: "ServerWebsites")
            websites = []
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Reset website state.
    func reset() {
        websites = []
        error = nil
        isLoading = false
    }
}
