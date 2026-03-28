//
//  HeadersViewModel.swift
//  AevonX
//
//  ViewModel for per-site HTTP headers — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class HeadersViewModel: ObservableObject {
    @Published var headers: [SiteHeaderEntry] = []
    @Published var auditResults: [SecurityHeadersAudit] = []
    @Published var isAuditing = false

    let serverId: String
    let domain: String
    let engine: String
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, engine: String = "nginx") {
        self.serverId = serverId
        self.domain = domain
        self.engine = engine
    }

    func loadHeaders() async {
        await detectPathsIfNeeded()
        let configPath = resolveConfigPath()
        let cmd = bridge.loadHeadersCmdRouted(engine: engine, configPath: configPath)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseHeaders(output: result)
        
        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let headerList = resp["data"] as? [[String: Any]] {
            headers = headerList.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let value = dict["value"] as? String else { return nil }
                return SiteHeaderEntry(
                    type: HTTPHeaderType.allCases.first { $0.headerName == name } ?? .custom,
                    headerName: name,
                    headerValue: value,
                    enabled: true
                )
            }
        }
    }

    func runSecurityAudit() async {
        isAuditing = true
        defer { isAuditing = false }
        let cmd = bridge.auditHeadersCmd(domain: domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseHeaderAudit(output: result)
        
        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let auditList = resp["data"] as? [[String: Any]] {
            auditResults = auditList.compactMap { dict in
                guard let name = dict["header_name"] as? String else { return nil }
                let present = dict["present"] as? Bool ?? false
                let value = dict["value"] as? String
                return SecurityHeadersAudit(
                    headerName: name,
                    isPresent: present,
                    value: value,
                    grade: present ? .good : .missing
                )
            }
        }
    }

    func applyRecommendedHeaders() async {
        await detectPathsIfNeeded()
        let configPath = resolveConfigPath()
        let cmd = bridge.applyRecommendedHeadersCmdRouted(engine: engine, configPath: configPath)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        // Note: Go ApplyRecommendedHeadersCmd already includes nginx -t && reload
        GlobalToastManager.shared.showSuccess("Security headers applied")
        await loadHeaders()
        await runSecurityAudit()
    }

    /// Resolves the config path for the domain, checking both standard and BT Panel formats
    private func resolveConfigPath() -> String {
        let sa = engine == "apache" ? serverPaths.apacheSitesAvailable : serverPaths.nginxSitesAvailable
        if engine == "apache" {
            return "\(sa)/\(domain).conf"
        }
        if serverPaths.serverType == "bt_panel" || sa.contains("/www/server") {
            return "\(sa)/\(domain).conf"
        }
        return "\(sa)/\(domain)"
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
