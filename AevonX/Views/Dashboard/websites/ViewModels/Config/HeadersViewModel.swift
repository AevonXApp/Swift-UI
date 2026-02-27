//
//  HeadersViewModel.swift
//  AevonX
//
//  ViewModel for per-site HTTP headers — delegates to SiteHeadersService
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
class HeadersViewModel: ObservableObject {
    @Published var headers: [SiteHeaderEntry] = []
    @Published var auditResults: [SecurityHeadersAudit] = []
    @Published var isAuditing = false

    let serverId: String
    let domain: String
    private let service = SiteHeadersService.shared

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadHeaders() async {
        do {
            let coreHeaders = try await service.loadHeaders(domain: domain, serverId: serverId)
            headers = coreHeaders.map { header in
                SiteHeaderEntry(
                    type: HTTPHeaderType.allCases.first { $0.headerName == header.name } ?? .custom,
                    headerName: header.name,
                    headerValue: header.value,
                    enabled: true
                )
            }
        } catch {
            headers = []
        }
    }

    func runSecurityAudit() async {
        isAuditing = true
        defer { isAuditing = false }
        do {
            let results = try await service.auditSecurityHeaders(domain: domain, serverId: serverId)
            auditResults = results.map { result in
                SecurityHeadersAudit(
                    headerName: result.headerName,
                    isPresent: result.present,
                    value: result.value,
                    grade: result.present ? .good : .missing
                )
            }
        } catch {
            auditResults = []
        }
    }

    func applyRecommendedHeaders() async {
        do {
            try await service.applyRecommendedHeaders(domain: domain, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Security headers applied & Nginx reloaded")
            await loadHeaders()
            await runSecurityAudit()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }
}
