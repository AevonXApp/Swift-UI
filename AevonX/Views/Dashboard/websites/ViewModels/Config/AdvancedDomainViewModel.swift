//
//  AdvancedDomainViewModel.swift
//  AevonX
//
//  ViewModel for advanced domain management — delegates to SiteDomainService
//

import SwiftUI
import Combine
import AevonXCore

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
    private let service = SiteDomainService.shared

    init(serverId: String, domain: String, docRoot: String) {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
    }

    func loadAliases() async {
        isLoading = true; defer { isLoading = false }
        do { aliases = try await service.listAliases(domain: domain, serverId: serverId) }
        catch { aliases = [] }
    }

    func addAlias() async {
        guard !newAlias.isEmpty else { return }
        do {
            try await service.addAlias(alias: newAlias, domain: domain, serverId: serverId)
            aliases.append(newAlias); newAlias = ""
            GlobalToastManager.shared.showSuccess("Alias added")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func removeAlias(_ alias: String) async {
        do {
            try await service.removeAlias(alias: alias, domain: domain, serverId: serverId)
            aliases.removeAll { $0 == alias }
            GlobalToastManager.shared.showSuccess("Alias removed")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func loadSubdomains() async {
        isLoading = true; defer { isLoading = false }
        do {
            let subs = try await service.listSubdomains(domain: domain, serverId: serverId)
            subdomains = subs.map { SubdomainItem(name: $0.name, fullDomain: $0.fullDomain, isActive: $0.isActive) }
        } catch { subdomains = [] }
    }

    func createSubdomain() async {
        guard !newSubdomain.isEmpty else { return }
        isLoading = true; defer { isLoading = false }
        do {
            try await service.createSubdomain(subdomain: newSubdomain, domain: domain, docRoot: docRoot, serverId: serverId)
            subdomains.append(SubdomainItem(name: newSubdomain, fullDomain: "\(newSubdomain).\(domain)", isActive: true))
            newSubdomain = ""
            GlobalToastManager.shared.showSuccess("Subdomain created")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func lookupDNS() async {
        isLoading = true; defer { isLoading = false }
        do {
            let records = try await service.checkDNS(domain: domain, serverId: serverId)
            dnsRecords = records.map { DNSRecordItem(type: $0.type, name: $0.name, value: $0.value) }
        } catch { dnsRecords = [] }
    }

    func setWWWRedirect(toWWW: Bool) async {
        isLoading = true; defer { isLoading = false }
        do {
            try await service.setWWWRedirect(toWWW: toWWW, domain: domain, serverId: serverId)
            GlobalToastManager.shared.showSuccess(toWWW ? "Redirecting to www" : "Redirecting to non-www")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
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
