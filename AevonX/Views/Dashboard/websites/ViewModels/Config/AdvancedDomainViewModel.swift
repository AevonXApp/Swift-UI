//
//  AdvancedDomainViewModel.swift
//  AevonX
//
//  ViewModel for advanced domain management — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class AdvancedDomainViewModel: ObservableObject {
    @Published var aliases: [String] = []
    @Published var subdomains: [SubdomainItem] = []
    @Published var dnsRecords: [DNSRecordItem] = []
    @Published var newAlias = ""
    @Published var newSubdomain = ""
    @Published var isLoading = false
    @Published var selectedTab: DomainTab = .aliases

    enum DomainTab: String, CaseIterable, Identifiable {
        case aliases = "Aliases"
        case subdomains = "Subdomains"
        case dns = "DNS Records"
        case redirects = "Redirects"
        var id: String { rawValue }
    }

    let serverId: String
    let domain: String
    let docRoot: String
    let engine: String
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String, docRoot: String, engine: String = "nginx") {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
        self.engine = engine
    }

    func loadAliases() async {
        isLoading = true; defer { isLoading = false }
        let cmd = bridge.listAliasesCmd(domain: domain)
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseAliases(output: output)
        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let aliasList = resp["data"] as? [String] {
            aliases = aliasList
        }
    }

    func addAlias() async {
        guard !newAlias.isEmpty else { return }
        let cmd = bridge.addAliasCmd(alias: newAlias, domain: domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartEngineCmdRouted(engine: engine))
        aliases.append(newAlias); newAlias = ""
        GlobalToastManager.shared.showSuccess("Alias added")
    }

    func removeAlias(_ alias: String) async {
        let cmd = bridge.removeAliasCmd(alias: alias, domain: domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartEngineCmdRouted(engine: engine))
        aliases.removeAll { $0 == alias }
        GlobalToastManager.shared.showSuccess("Alias removed")
    }

    func loadSubdomains() async {
        isLoading = true; defer { isLoading = false }
        await detectPathsIfNeeded()
        let cmd = bridge.listSubdomainsCmd(domain: domain, sitesEnabled: serverPaths.nginxSitesEnabled)
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        subdomains = lines.map { name in
            SubdomainItem(name: name, fullDomain: "\(name).\(domain)", isActive: true)
        }
    }

    func createSubdomain() async {
        guard !newSubdomain.isEmpty else { return }
        isLoading = true; defer { isLoading = false }
        await detectPathsIfNeeded()
        let cmds = bridge.createSubdomainCmds(subdomain: newSubdomain, domain: domain, docRoot: docRoot, sitesAvailable: serverPaths.nginxSitesAvailable, sitesEnabled: serverPaths.nginxSitesEnabled, webOwnership: serverPaths.webOwnership)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartEngineCmdRouted(engine: engine))
        subdomains.append(SubdomainItem(name: newSubdomain, fullDomain: "\(newSubdomain).\(domain)", isActive: true))
        newSubdomain = ""
        GlobalToastManager.shared.showSuccess("Subdomain created")
    }

    func lookupDNS() async {
        isLoading = true; defer { isLoading = false }
        let cmd = bridge.dnsLookupCmd(domain: domain)
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseDNSRecords(domain: domain, output: output)
        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let records = resp["data"] as? [[String: String]] {
            dnsRecords = records.compactMap { dict in
                guard let type = dict["type"], let name = dict["name"], let value = dict["value"] else { return nil }
                return DNSRecordItem(type: type, name: name, value: value)
            }
        }
    }

    func setWWWRedirect(toWWW: Bool) async {
        isLoading = true; defer { isLoading = false }
        let cmd = bridge.setWWWRedirectCmd(domain: domain, toWWW: toWWW)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartEngineCmdRouted(engine: engine))
        GlobalToastManager.shared.showSuccess(toWWW ? "Redirecting to www" : "Redirecting to non-www")
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}

// MARK: - UI Models

struct SubdomainItem: Identifiable {
    let id = UUID()
    let name: String
    let fullDomain: String
    let isActive: Bool
}

struct DNSRecordItem: Identifiable {
    let id = UUID()
    let type: String
    let name: String
    let value: String
}
