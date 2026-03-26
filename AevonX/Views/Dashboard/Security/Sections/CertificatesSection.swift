//
//  CertificatesSection.swift
//  AevonX
//
//  SSL/TLS Certificate Monitor.
//  UI only — all data comes from SecurityManager in 
//

import SwiftUI
import AevonXCoreBridge

private struct IndexedCert: Identifiable {
    let id: Int
    let cert: CertificateInfo
    init(_ i: Int, _ c: CertificateInfo) { self.id = i; self.cert = c }
}

struct CertificatesSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var certificates: [CertificateInfo] = []
    @State private var tlsVersion = L10n.Status.unknown
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    private var filteredCerts: [CertificateInfo] {
        if searchText.isEmpty { return certificates }
        return certificates.filter {
            $0.domain.localizedCaseInsensitiveContains(searchText) ||
            $0.issuer.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack(spacing: AXSpacing.lg) {
                    tlsCard(icon: "lock.shield.fill", label: "TLS Version", value: tlsVersion, color: .axAccentBlue)
                    tlsCard(icon: "doc.badge.clock.fill", label: "Certificates", value: "\(certificates.count)", color: .axAccentPurple)
                    Spacer()
                }

                // Search
                AXSearchBar(text: $searchText, placeholder: "Search domains, issuers…")

                AXDataTable(
                    title: "SSL Certificates",
                    icon: "lock.fill",
                    accentColor: .axAccentBlue,
                    badgeText: "\(certificates.count) certificates",
                    columns: [
                        AXDataColumn(title: "Domain", width: nil),
                        AXDataColumn(title: "Issuer", width: 150),
                        AXDataColumn(title: "Expiry", width: 120),
                        AXDataColumn(title: "Status", width: 100, alignment: .center),
                    ],
                    items: filteredCerts.enumerated().map { IndexedCert($0.offset, $0.element) },
                    totalCount: certificates.count,
                    isLoading: isLoading,
                    emptyIcon: "lock.open",
                    emptyTitle: "No SSL certificates found"
                ) { item, _ in
                    HStack(spacing: 0) {
                        Text(item.cert.domain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(item.cert.issuer)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 150, alignment: .leading)
                            .lineLimit(1)
                        Text(item.cert.expiry)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 120, alignment: .leading)
                        certStatusBadge(daysLeft: item.cert.daysLeft)
                            .frame(width: 100, alignment: .center)
                    }
                } trailingContent: {
                    AXRefreshButton(isLoading: isLoading) {
                        Task { await loadCertData() }
                    }
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadCertData() }
    }

    private func certStatusBadge(daysLeft: Int) -> some View {
        let (text, color): (String, Color) = {
            if daysLeft < 0 { return ("Expired", .axError) }
            if daysLeft <= 7 { return ("Critical", .axError) }
            if daysLeft <= 30 { return ("\(daysLeft)d left", .axWarning) }
            return ("Valid", .axSuccess)
        }()

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
    }

    private func tlsCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.axTextPrimary)
                Text(label).font(.system(size: 11)).foregroundColor(.axTextSecondary)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Data (from Core)

    private func loadCertData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        async let certs = securityManager.scanCertificates(serverId: serverId)
        async let tls = securityManager.tlsVersion(serverId: serverId)

        let (c, t) = await (certs, tls)
        await MainActor.run {
            certificates = c
            tlsVersion = t
        }
    }
}
