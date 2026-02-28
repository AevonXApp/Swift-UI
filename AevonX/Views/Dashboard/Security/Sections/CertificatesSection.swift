//
//  CertificatesSection.swift
//  AevonX
//
//  SSL/TLS Certificate Monitor.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

struct CertificatesSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var certificates: [CertificateInfo] = []
    @State private var tlsVersion = "Unknown"

    private let securityManager = SecurityManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack(spacing: AXSpacing.lg) {
                    tlsCard(icon: "lock.shield.fill", label: "TLS Version", value: tlsVersion, color: .axAccentBlue)
                    tlsCard(icon: "doc.badge.clock.fill", label: "Certificates", value: "\(certificates.count)", color: .axAccentPurple)
                    Spacer()
                }

                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "lock.fill").font(.system(size: 14)).foregroundColor(.axAccentBlue)
                                Text("SSL Certificates").font(AXTypography.title3).foregroundColor(.axTextPrimary)
                            }
                            Spacer()
                            Button(action: { Task { await loadCertData() } }) {
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                                    Text("Refresh").font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.axTextSecondary)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)

                        Divider().background(Color.axBorder)

                        HStack(spacing: 0) {
                            Text("Domain").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Issuer").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 150, alignment: .leading)
                            Text("Expiry").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 120, alignment: .leading)
                            Text("Status").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 100, alignment: .center)
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axBackgroundTertiary.opacity(0.5))

                        Divider().background(Color.axBorder)

                        if isLoading {
                            VStack(spacing: AXSpacing.md) {
                                ProgressView()
                                Text("Checking certificates…").font(AXTypography.body).foregroundColor(.axTextMuted)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xxxl)
                        } else if certificates.isEmpty {
                            VStack(spacing: AXSpacing.md) {
                                Image(systemName: "lock.open").font(.system(size: 28)).foregroundColor(.axTextMuted)
                                Text("No SSL certificates found").font(AXTypography.body).foregroundColor(.axTextMuted)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xxxl)
                        } else {
                            ForEach(Array(certificates.enumerated()), id: \.offset) { index, cert in
                                HStack(spacing: 0) {
                                    Text(cert.domain).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(cert.issuer).font(.system(size: 11)).foregroundColor(.axTextSecondary)
                                        .frame(width: 150, alignment: .leading).lineLimit(1)
                                    Text(cert.expiry).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
                                        .frame(width: 120, alignment: .leading)
                                    certStatusBadge(daysLeft: cert.daysLeft).frame(width: 100, alignment: .center)
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                            }
                        }
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
