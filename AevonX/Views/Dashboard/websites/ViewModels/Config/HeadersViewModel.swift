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
    private let bridge = WebsitesBridge.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadHeaders() async {
        do {
            let configPath = "/etc/nginx/sites-available/\(domain)"
            let cmd = bridge.loadHeadersCmd(configPath: configPath)
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
        } catch {
            headers = []
        }
    }

    func runSecurityAudit() async {
        isAuditing = true
        defer { isAuditing = false }
        do {
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
        } catch {
            auditResults = []
        }
    }

    func applyRecommendedHeaders() async {
        do {
            let configPath = "/etc/nginx/sites-available/\(domain)"
            let cmd = bridge.applyRecommendedHeadersCmd(configPath: configPath)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess("Security headers applied & Nginx reloaded")
            await loadHeaders()
            await runSecurityAudit()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }
}
