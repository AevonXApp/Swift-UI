//
//  ServerWebsitesViewModel.swift
//  AevonX
//
//  Manages website listing and operations.
//  Extracted from ServerConnectionViewModel for single-responsibility.
//  Now uses Go Core via AevonXCoreBridge.
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore   // Still needed for AevonXCore.CoreWebsiteInfo (used by parent VM) and CoreLogger
import Combine

// MARK: - Server Websites ViewModel

/// Manages website listing and operations for a connected server.
@MainActor
public class ServerWebsitesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of websites on the server
    @Published private(set) var websites: [AevonXCore.CoreWebsiteInfo] = []
    
    /// Whether websites are being loaded
    @Published private(set) var isLoading: Bool = false
    
    /// Error from website loading, if any
    @Published private(set) var error: String?
    
    /// Count of websites
    var count: Int { websites.count }
    
    // MARK: - Private Properties
    
    private let serverId: String
    private let bridge = WebsitesBridge.shared
    
    // MARK: - Initialization
    
    init(serverId: String) {
        self.serverId = serverId
    }
    
    // MARK: - Website Loading
    
    /// Load all websites from the server via Go Core bridge.
    func loadWebsites() async {
        isLoading = true
        error = nil
        
        do {
            // Step 1: Get the list command from Go Core
            let listCmd = bridge.nginxListCmd(serverID: serverId)
            guard !listCmd.isEmpty else {
                throw NSError(domain: "Websites", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get list command"])
            }
            
            // Step 2: Execute via SSH (executeAsync now returns plain stdout)
            let stdout = await SSHBridge.shared.executeAsync(serverID: serverId, command: listCmd)
            
            // Step 3: Parse output via Go Core
            let parsedJSON = bridge.parseNginxSites(output: stdout)
            
            // Step 4: Decode into AevonXCore.CoreWebsiteInfo array
            if let data = parsedJSON.data(using: .utf8),
               let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               response["success"] as? Bool == true,
               let sitesData = response["data"],
               JSONSerialization.isValidJSONObject(sitesData) {
                let sitesJSON = try JSONSerialization.data(withJSONObject: sitesData)
                if let sites = try? JSONDecoder().decode([SimpleSiteInfo].self, from: sitesJSON) {
                    // Convert to AevonXCore.CoreWebsiteInfo for compatibility with parent VM
                    websites = sites.map { site in
                        AevonXCore.CoreWebsiteInfo(
                            name: site.domain,
                            domain: site.domain,
                            status: site.enabled ? .online : .offline,
                            sslEnabled: site.sslEnabled ?? false,
                            phpVersion: site.phpVersion,
                            documentRoot: site.documentRoot ?? "/var/www/\(site.domain)"
                        )
                    }
                }
            }
            
            AevonXCoreBridge.CoreLogger.shared.info("Loaded \(websites.count) websites via Go Core", module: "ServerWebsites")
        } catch {
            AevonXCoreBridge.CoreLogger.shared.error("Failed to load websites: \(error.localizedDescription)", module: "ServerWebsites")
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

// MARK: - Simple Site Info (bridge decode helper)

/// Lightweight struct to decode Go Core parsed site output.
private struct SimpleSiteInfo: Codable {
    let domain: String
    let enabled: Bool
    let serverType: String?
    let documentRoot: String?
    let phpVersion: String?
    let sslEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case domain
        case enabled
        case serverType = "server_type"
        case documentRoot = "document_root"
        case phpVersion = "php_version"
        case sslEnabled = "ssl_enabled"
    }
}
