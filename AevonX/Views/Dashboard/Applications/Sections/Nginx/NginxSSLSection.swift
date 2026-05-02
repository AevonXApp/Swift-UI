//
//  NginxSSLSection.swift
//  AevonX
//
//  SSL/TLS certificate management for Nginx — install, upload,
//  renew certificates per domain, configure global TLS settings.
//

import SwiftUI
import AevonXCoreBridge

struct NginxSSLSection: View {
    let serverId: String

    // Data
    @State private var sslCerts: [NginxSSLCertEntry] = []
    @State private var sslProtocols = ""
    @State private var sslPreferCiphers = false
    @State private var sslStapling = false
    @State private var sites: [NginxSSLSiteEntry] = []

    // UI state
    @State private var isLoading = true
    @State private var searchText = ""

    // Sheets
    @State private var showLetsEncryptSheet = false
    @State private var showUploadSheet = false
    @State private var selectedDomain = ""

    // Let's Encrypt state
    @State private var leDomain = ""
    @State private var isIssuingLE = false

    // Upload state
    @State private var uploadDomain = ""
    @State private var uploadCert = ""
    @State private var uploadKey = ""
    @State private var uploadChain = ""
    @State private var isUploading = false

    // SSL settings save state
    @State private var isSavingSettings = false
    @State private var selectedProtocols = Set<String>()

    // Renewal
    @State private var renewingDomain = ""

    private let appBridge = ApplicationBridge.shared
    private let webBridge = WebsitesBridge.shared
    private let toast = GlobalToastManager.shared
    private let log = CoreLogger.shared
    private let module = "NginxSSL"

    private var filteredSites: [NginxSSLSiteEntry] {
        guard !searchText.isEmpty else { return sites }
        return sites.filter { $0.domain.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if isLoading {
                skeletonContent
            } else {
                mainContent
            }
        }
        .task { await loadData() }
        .sheet(isPresented: $showLetsEncryptSheet) {
            letsEncryptSheet
        }
        .sheet(isPresented: $showUploadSheet) {
            uploadCertSheet
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                globalSettingsCard
                certificatesOverviewCard
                domainListCard
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    // MARK: - Global SSL Settings

    private var globalSettingsCard: some View {
        accentCard(title: "Global TLS Settings", icon: "lock.shield.fill", color: .green) {
            VStack(spacing: 1) {
                protocolsRow
                Divider().background(Color.axBorder.opacity(0.15))
                sslToggleRow("Prefer Server Ciphers", hint: "Server selects the cipher suite", isOn: $sslPreferCiphers)
                Divider().background(Color.axBorder.opacity(0.15))
                sslToggleRow("OCSP Stapling", hint: "Faster TLS handshake with stapled response", isOn: $sslStapling)
            }

            saveSettingsButton
        }
    }

    private var protocolsRow: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Apps.tlsProtocols)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Apps.selectMinimumTlsVersions)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                protocolChip("TLSv1.2")
                protocolChip("TLSv1.3")
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private func protocolChip(_ proto: String) -> some View {
        let isSelected = selectedProtocols.contains(proto)
        return Button(action: {
            if isSelected {
                selectedProtocols.remove(proto)
            } else {
                selectedProtocols.insert(proto)
            }
        }) {
            Text(proto)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(isSelected ? .white : .axTextSecondary)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 4)
                .background(isSelected ? Color.green : Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(isSelected ? Color.green : Color.axBorder.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var saveSettingsButton: some View {
        HStack {
            Spacer()
            gradientButton(
                icon: "checkmark.shield.fill",
                label: "Apply TLS Settings",
                color: .green,
                isLoading: isSavingSettings,
                action: { Task { await saveGlobalSettings() } }
            )
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.bottom, AXSpacing.md)
    }

    // MARK: - Certificates Overview

    private var certificatesOverviewCard: some View {
        accentCard(title: "Installed Certificates", icon: "lock.fill", color: .axAccentBlue) {
            if sslCerts.isEmpty {
                noCertsPlaceholder
            } else {
                certsList
            }
        }
    }

    private var noCertsPlaceholder: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.axWarning)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Apps.noSslCertificatesDetected)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                Text(L10n.Apps.issueALetsEncryptCertificateOrUploadYourOwn)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(AXSpacing.lg)
    }

    private var certsList: some View {
        VStack(spacing: 0) {
            ForEach(sslCerts.indices, id: \.self) { i in
                certEntryRow(sslCerts[i])
                if i < sslCerts.count - 1 {
                    Divider().background(Color.axBorder.opacity(0.15))
                }
            }
        }
    }

    private func certEntryRow(_ cert: NginxSSLCertEntry) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 28, height: 28)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(cert.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)

                if !cert.subject.isEmpty {
                    Text(cert.subject)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                }
            }

            Spacer()

            if !cert.expiresAt.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                    Text(cert.expiresAt)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.axWarning)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.axWarning.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }

    // MARK: - Domain List (Install/Manage per domain)

    private var domainListCard: some View {
        accentCard(title: "Domain Certificates", icon: "globe", color: .cyan) {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextMuted)
                        .font(.system(size: 11))
                    TextField("Search domains...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 6)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
                .padding(AXSpacing.lg)

                if filteredSites.isEmpty {
                    noSitesPlaceholder
                } else {
                    domainRows
                }
            }

            // Quick actions
            quickActionsBar
        }
    }

    private var noSitesPlaceholder: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "globe")
                .font(.system(size: 24))
                .foregroundColor(.axTextMuted.opacity(0.5))
            Text(L10n.Apps.noSitesFound)
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.xl)
    }

    private var domainRows: some View {
        VStack(spacing: 0) {
            ForEach(filteredSites.indices, id: \.self) { i in
                domainRow(filteredSites[i])
                if i < filteredSites.count - 1 {
                    Divider().background(Color.axBorder.opacity(0.15))
                }
            }
        }
    }

    private func domainRow(_ site: NginxSSLSiteEntry) -> some View {
        HStack(spacing: AXSpacing.md) {
            // SSL status indicator
            Image(systemName: site.hasSSL ? "lock.fill" : "lock.slash")
                .font(.system(size: 13))
                .foregroundColor(site.hasSSL ? .axSuccess : .axTextMuted)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(site.domain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

                Text(site.hasSSL ? "SSL Active" : "No SSL")
                    .font(.system(size: 10))
                    .foregroundColor(site.hasSSL ? .axSuccess : .axTextMuted)
            }

            Spacer()

            HStack(spacing: AXSpacing.xs) {
                if site.hasSSL {
                    // Renew button
                    Button(action: {
                        Task { await renewCert(domain: site.domain) }
                    }) {
                        HStack(spacing: 3) {
                            if renewingDomain == site.domain {
                                ProgressView().scaleEffect(0.5).frame(width: 10, height: 10)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 10))
                            }
                            Text(L10n.Apps.renew)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!renewingDomain.isEmpty)
                }

                // Upload custom cert
                Button(action: {
                    uploadDomain = site.domain
                    showUploadSheet = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.doc")
                            .font(.system(size: 10))
                        Text(L10n.Apps.upload)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())

                // Issue LE
                if !site.hasSSL {
                    Button(action: {
                        leDomain = site.domain
                        showLetsEncryptSheet = true
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 10))
                            Text(L10n.Apps.letsEncrypt)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.axSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.axSuccess.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    private var quickActionsBar: some View {
        HStack(spacing: AXSpacing.md) {
            Spacer()
            gradientButton(
                icon: "lock.shield.fill",
                label: "Issue Let's Encrypt",
                color: .axSuccess,
                isLoading: false,
                action: {
                    leDomain = ""
                    showLetsEncryptSheet = true
                }
            )
            gradientButton(
                icon: "arrow.up.doc.fill",
                label: "Upload Certificate",
                color: .purple,
                isLoading: false,
                action: {
                    uploadDomain = ""
                    uploadCert = ""
                    uploadKey = ""
                    uploadChain = ""
                    showUploadSheet = true
                }
            )
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.bottom, AXSpacing.md)
    }

    // MARK: - Let's Encrypt Sheet

    private var letsEncryptSheet: some View {
        VStack(spacing: AXSpacing.xl) {
            sheetHeader(title: "Issue Let's Encrypt Certificate", icon: "lock.shield.fill", color: .axSuccess)

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text(L10n.Apps.domain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextSecondary)

                TextField("example.com", text: $leDomain)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.4), lineWidth: 1))

                Text(L10n.Apps.certbotWillVerifyDomainOwnershipViaHttpChallenge)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.xl)

            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { showLetsEncryptSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())

                Button(action: {
                    Task { await issueLetsEncrypt() }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if isIssuingLE {
                            ProgressView().scaleEffect(0.7)
                        }
                        Text(L10n.Apps.issueCertificate)
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(leDomain.isEmpty || isIssuingLE)
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.xl)
        }
        .frame(width: 460)
        .background(Color.axSurface)
    }

    // MARK: - Upload Certificate Sheet

    private var uploadCertSheet: some View {
        VStack(spacing: AXSpacing.lg) {
            sheetHeader(title: "Upload Custom Certificate", icon: "arrow.up.doc.fill", color: .purple)

            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Domain
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Apps.domain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                    TextField("example.com", text: $uploadDomain)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(AXSpacing.sm)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.4), lineWidth: 1))
                }

                // Certificate PEM
                pemField(title: "Certificate (PEM)", placeholder: "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----", text: $uploadCert)

                // Private Key PEM
                pemField(title: "Private Key (PEM)", placeholder: "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----", text: $uploadKey)

                // Chain (optional)
                pemField(title: "Chain / CA Bundle (Optional)", placeholder: "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----", text: $uploadChain)
            }
            .padding(.horizontal, AXSpacing.xl)

            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { showUploadSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())

                Button(action: {
                    Task { await uploadCustomCert() }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if isUploading {
                            ProgressView().scaleEffect(0.7)
                        }
                        Text(L10n.Apps.uploadApply)
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(uploadDomain.isEmpty || uploadCert.isEmpty || uploadKey.isEmpty || isUploading)
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.xl)
        }
        .frame(minWidth: 560, minHeight: 500)
        .background(Color.axSurface)
    }

    private func pemField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)

            TextEditor(text: text)
                .font(.system(size: 11, design: .monospaced))
                .frame(minHeight: 80, maxHeight: 120)
                .padding(AXSpacing.xs)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.4), lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextMuted.opacity(0.5))
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.sm)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func sheetHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.axTextPrimary)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
    }

    // MARK: - Shared Row Builders

    private func sslToggleRow(_ label: String, hint: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.85)
                .labelsHidden()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    // MARK: - Accent Card

    private func accentCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(color.opacity(0.05))

            Divider().background(color.opacity(0.2))

            content()
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [color, color.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    // MARK: - Gradient Button

    private func gradientButton(icon: String, label: String, color: Color, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                if isLoading {
                    ProgressView().scaleEffect(0.65).frame(width: 14, height: 14)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(AXCornerRadius.sm)
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack(spacing: AXSpacing.sm) {
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(Color.axSurface).frame(width: 14, height: 14).shimmer()
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(Color.axSurface).frame(width: 140, height: 14).shimmer()
                        }
                        VStack(spacing: 1) {
                            ForEach(0..<3, id: \.self) { _ in
                                AXSkeletonSettingRow().background(Color.axSurface)
                            }
                        }
                        .cornerRadius(AXCornerRadius.md)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        log.debug("Loading Nginx SSL data...", module: module)

        // Load security info and sites list in parallel
        async let securityJSON = appBridge.getSecurity(serverID: serverId, appID: "nginx")
        async let sitesJSON = appBridge.listSites(serverID: serverId, appID: "nginx")

        let (secResult, sitesResult) = await (securityJSON, sitesJSON)

        // Parse security data
        if let data = secResult.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {

            if let v = info["ssl_protocols"] as? String {
                sslProtocols = v
                // Parse existing protocols into selection set
                selectedProtocols = Set(v.components(separatedBy: " ").filter { !$0.isEmpty })
            }
            if let v = info["ssl_prefer_server_ciphers"] as? Bool { sslPreferCiphers = v }
            if let v = info["ssl_stapling"] as? Bool { sslStapling = v }

            if let certs = info["ssl_certs"] as? [[String: Any]] {
                sslCerts = certs.map { cert in
                    NginxSSLCertEntry(
                        path: cert["path"] as? String ?? "",
                        subject: cert["subject"] as? String ?? "",
                        expiresAt: cert["expires_at"] as? String ?? "",
                        issuer: cert["issuer"] as? String ?? ""
                    )
                }
            }
            log.debug("Loaded \(sslCerts.count) certs, protocols: \(sslProtocols)", module: module)
        }

        // Parse sites data
        if let data = sitesResult.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let sitesList = resp["data"] as? [[String: Any]] {

            sites = sitesList.compactMap { site in
                guard let name = site["name"] as? String else { return nil }
                let domain = site["domain"] as? String ?? name.replacingOccurrences(of: ".conf", with: "")
                let hasSSL = site["ssl"] as? Bool ?? false
                return NginxSSLSiteEntry(domain: domain, hasSSL: hasSSL)
            }
            log.debug("Loaded \(sites.count) sites", module: module)
        }

        isLoading = false
    }

    // MARK: - Actions

    private func saveGlobalSettings() async {
        isSavingSettings = true
        let protocols = selectedProtocols.sorted().joined(separator: " ")
        log.debug("Saving global SSL: protocols=\(protocols) ciphers=\(sslPreferCiphers) stapling=\(sslStapling)", module: module)

        // Build commands to update nginx.conf ssl settings
        let cmds = [
            "sudo sed -i 's/ssl_protocols .*/ssl_protocols \(protocols);/' /etc/nginx/nginx.conf",
            "sudo sed -i 's/ssl_prefer_server_ciphers .*/ssl_prefer_server_ciphers \(sslPreferCiphers ? "on" : "off");/' /etc/nginx/nginx.conf",
            "sudo sed -i 's/ssl_stapling .*/ssl_stapling \(sslStapling ? "on" : "off");/' /etc/nginx/nginx.conf",
            "sudo nginx -t 2>&1",
        ]

        var lastResult = ""
        for cmd in cmds {
            lastResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            log.debug("SSL settings cmd result: \(lastResult.prefix(200))", module: module)
        }

        if lastResult.contains("syntax is ok") || lastResult.contains("test is successful") {
            let _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo systemctl reload nginx 2>&1 || sudo nginx -s reload 2>&1")
            toast.showSuccess("TLS settings applied & nginx reloaded")
        } else {
            toast.showError("Nginx config test failed — settings not applied")
        }

        isSavingSettings = false
    }

    private func issueLetsEncrypt() async {
        guard !leDomain.isEmpty else { return }
        isIssuingLE = true
        log.debug("Issuing Let's Encrypt for \(leDomain)...", module: module)

        let cmds = webBridge.issueSSLCmd(engine: "nginx", domain: leDomain)
        var lastOutput = ""
        for (i, cmd) in cmds.enumerated() {
            log.debug("LE cmd[\(i)]: \(cmd.prefix(120))", module: module)
            lastOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            log.debug("LE result[\(i)]: \(lastOutput.prefix(300))", module: module)
        }

        if lastOutput.lowercased().contains("successfully") || lastOutput.contains("Congratulations") || lastOutput.contains("fullchain.pem") {
            toast.showSuccess("Let's Encrypt certificate issued for \(leDomain)")
            showLetsEncryptSheet = false
            await loadData()
        } else if lastOutput.contains("AEVON_CERT_FAILED") || lastOutput.lowercased().contains("error") || lastOutput.lowercased().contains("failed") {
            toast.showError("Failed to issue certificate — check domain DNS")
            log.debug("LE failed: \(lastOutput)", module: module)
        } else {
            toast.showSuccess("Certificate command completed for \(leDomain)")
            showLetsEncryptSheet = false
            await loadData()
        }

        isIssuingLE = false
    }

    private func uploadCustomCert() async {
        guard !uploadDomain.isEmpty, !uploadCert.isEmpty, !uploadKey.isEmpty else { return }
        isUploading = true
        log.debug("Uploading custom cert for \(uploadDomain)...", module: module)

        let chain: String? = uploadChain.isEmpty ? nil : uploadChain
        let cmds = webBridge.uploadCustomCertCmds(
            engine: "nginx",
            domain: uploadDomain,
            cert: uploadCert,
            key: uploadKey,
            chain: chain,
            configPath: ""  // Auto-detect
        )

        var lastOutput = ""
        for (i, cmd) in cmds.enumerated() {
            log.debug("Upload cmd[\(i)]: \(cmd.prefix(120))", module: module)
            lastOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            log.debug("Upload result[\(i)]: \(lastOutput.prefix(300))", module: module)
        }

        if lastOutput.contains("AEVON_CERT_FAILED") {
            toast.showError("Failed to upload certificate — check logs")
            log.debug("Upload failed: \(lastOutput)", module: module)
        } else {
            // Verify cert on port 443
            let verifyCmd = "echo | openssl s_client -connect \(uploadDomain):443 -servername \(uploadDomain) 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null"
            let verifyResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: verifyCmd)
            log.debug("Verify after upload: \(verifyResult.prefix(300))", module: module)

            toast.showSuccess("Certificate uploaded for \(uploadDomain)")
            showUploadSheet = false
            await loadData()
        }

        isUploading = false
    }

    private func renewCert(domain: String) async {
        renewingDomain = domain
        log.debug("Renewing cert for \(domain)...", module: module)

        let cmd = webBridge.renewSSLCmd(engine: "nginx", domain: domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        log.debug("Renew result: \(result.prefix(300))", module: module)

        if result.lowercased().contains("error") || result.lowercased().contains("failed") {
            toast.showError("Failed to renew certificate for \(domain)")
        } else {
            toast.showSuccess("Certificate renewed for \(domain)")
            await loadData()
        }

        renewingDomain = ""
    }
}

// MARK: - Models

struct NginxSSLCertEntry: Identifiable {
    let id = UUID()
    let path: String
    let subject: String
    let expiresAt: String
    let issuer: String
}

struct NginxSSLSiteEntry: Identifiable {
    let id = UUID()
    let domain: String
    let hasSSL: Bool
}
