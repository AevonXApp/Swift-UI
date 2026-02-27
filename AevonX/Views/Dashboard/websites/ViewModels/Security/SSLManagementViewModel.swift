//
//  SSLManagementViewModel.swift
//  AevonX
//
//  ViewModel for SSL Management section
//

import SwiftUI
import Combine
import AevonXCore

@MainActor
public final class SSLManagementViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var certificateDetails: SSLCertificateDetails?
    @Published public var isLoading: Bool = false
    @Published public var error: String?

    // Let's Encrypt
    @Published public var showLetsEncryptSheet: Bool = false
    @Published public var letsEncryptEmail: String = ""
    @Published public var selectedChallengeType: SSLChallengeType = .http01
    @Published public var isIssuingCertificate: Bool = false

    // Custom Certificate
    @Published public var showCustomCertSheet: Bool = false
    @Published public var customCertificate: String = ""
    @Published public var customPrivateKey: String = ""
    @Published public var customChain: String = ""
    @Published public var isUploadingCertificate: Bool = false

    // Force SSL
    @Published public var isForceSSLEnabled: Bool = false
    @Published public var isEnablingForceSSL: Bool = false

    // HSTS
    @Published public var hstsConfig: HSTSConfiguration = HSTSConfiguration()
    @Published public var showHSTSSheet: Bool = false
    @Published public var isConfiguringHSTS: Bool = false

    // Renewal
    @Published public var isRenewing: Bool = false

    // Certificate Content (PEM data)
    @Published public var certificateContent: SSLCertificateContent?
    @Published public var isLoadingContent: Bool = false
    @Published public var showCertificateContent: Bool = false

    // DNS Challenge Records
    @Published public var dnsRecords: [SSLDNSRecord] = []
    @Published public var isLoadingDNSRecords: Bool = false

    private let website: WebsiteInfo
    private let serverId: String?
    private let sslService = WebsiteSSLService.shared
    private let toastManager = GlobalToastManager.shared

    // MARK: - Computed Properties

    /// The website domain for display
    public var domain: String { website.domain }

    // MARK: - Initialization

    public init(website: WebsiteInfo, serverId: String?) {
        self.website = website
        self.serverId = serverId
    }

    // MARK: - Data Loading

    public func load() async {
        guard let serverId = serverId else {
            error = "No server ID available"
            return
        }

        isLoading = true
        error = nil

        // Detect Force SSL state
        isForceSSLEnabled = await sslService.isForceSSLEnabled(domain: website.domain, serverId: serverId)

        // Always try to fetch certificate details from the server.
        // We cannot rely on website.sslEnabled because it's a stale snapshot
        // that doesn't update after issuing/uploading a certificate.
        do {
            certificateDetails = try await sslService.getSSLCertificateDetails(domain: website.domain, serverId: serverId)
            print("[SSLManagementVM] ✅ certificateDetails loaded: issuer=\(certificateDetails?.issuer ?? "nil"), brand=\(certificateDetails?.brand ?? "nil")")
        } catch {
            // No certificate found or unable to read — this is normal for sites without SSL
            certificateDetails = nil
            print("[SSLManagementVM] ⚠️ certificateDetails set to nil: \(error.localizedDescription)")
        }

        isLoading = false
        print("[SSLManagementVM] 🔄 isLoading=false, certificateDetails is \(certificateDetails != nil ? "SET" : "NIL")")
    }

    // MARK: - Certificate Content

    public func loadCertificateContent() async {
        guard let serverId = serverId else { return }

        isLoadingContent = true

        do {
            certificateContent = try await sslService.getSSLCertificateContent(domain: website.domain, serverId: serverId)
        } catch {
            self.error = "Failed to load certificate content: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoadingContent = false
    }

    // MARK: - DNS Challenge Records

    public func loadDNSRecords() async {
        guard let serverId = serverId else { return }

        isLoadingDNSRecords = true

        do {
            dnsRecords = try await sslService.getDNSChallengeRecords(domain: website.domain, serverId: serverId)
        } catch {
            self.error = "Failed to load DNS records: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoadingDNSRecords = false
    }

    // MARK: - Let's Encrypt

    public func issueLetsEncryptCertificate() async {
        guard let serverId = serverId else { return }

        isIssuingCertificate = true
        error = nil

        do {
            try await sslService.issueNewLetsEncryptCert(
                domain: website.domain,
                email: letsEncryptEmail,
                challengeType: selectedChallengeType.rawValue,
                serverId: serverId
            )

            showLetsEncryptSheet = false
            toastManager.showSuccess("Let's Encrypt certificate issued successfully")

            // Reload certificate details
            await load()
        } catch {
            self.error = "Failed to issue certificate: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isIssuingCertificate = false
    }

    // MARK: - Custom Certificate

    public func uploadCustomCertificate() async {
        guard let serverId = serverId else { return }

        let upload = CustomCertificateUpload(
            certificate: customCertificate,
            privateKey: customPrivateKey,
            chainBundle: customChain.isEmpty ? nil : customChain
        )

        // Validate
        let errors = upload.validate()
        guard errors.isEmpty else {
            error = errors.joined(separator: "\n")
            toastManager.showError(error!)
            return
        }

        isUploadingCertificate = true

        do {
            try await sslService.uploadCustomCertificate(
                domain: website.domain,
                cert: customCertificate,
                key: customPrivateKey,
                chain: customChain.isEmpty ? nil : customChain,
                serverId: serverId
            )

            showCustomCertSheet = false
            toastManager.showSuccess("Custom certificate uploaded successfully")

            // Clear fields
            customCertificate = ""
            customPrivateKey = ""
            customChain = ""

            // Reload certificate details
            await load()
        } catch {
            self.error = "Failed to upload certificate: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isUploadingCertificate = false
    }

    // MARK: - Force SSL

    public func toggleForceSSL() async {
        guard let serverId = serverId else { return }

        isEnablingForceSSL = true

        do {
            if !isForceSSLEnabled {
                try await sslService.enableForceSSL(domain: website.domain, serverId: serverId)
                isForceSSLEnabled = true
                toastManager.showSuccess("Force HTTPS enabled — all HTTP traffic will redirect to HTTPS")
            } else {
                try await sslService.disableForceSSL(domain: website.domain, serverId: serverId)
                isForceSSLEnabled = false
                toastManager.showSuccess("Force HTTPS disabled")
            }
        } catch {
            self.error = "Failed to toggle Force HTTPS: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isEnablingForceSSL = false
    }

    // MARK: - HSTS

    public func configureHSTS() async {
        guard let serverId = serverId else { return }

        isConfiguringHSTS = true

        do {
            try await WebsiteSSLService.shared.configureHSTS(
                domain: website.domain,
                maxAge: hstsConfig.maxAge,
                includeSubdomains: hstsConfig.includeSubDomains,
                serverId: serverId
            )

            showHSTSSheet = false
            toastManager.showSuccess("HSTS configured successfully")
        } catch {
            self.error = "Failed to configure HSTS: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isConfiguringHSTS = false
    }

    // MARK: - Certificate Renewal

    public func renewCertificate() async {
        guard let serverId = serverId else { return }

        isRenewing = true

        do {
            try await sslService.renewSSL(websiteId: website.domain, serverId: serverId)
            toastManager.showSuccess("Certificate renewal started")

            // Reload certificate details
            await load()
        } catch {
            self.error = "Failed to renew certificate: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isRenewing = false
    }

    // MARK: - Helpers

    public func clearError() {
        error = nil
    }

    public var certificateStatus: String {
        guard let cert = certificateDetails else { return "No certificate" }
        return cert.status.rawValue
    }

    public var daysUntilExpiry: Int? {
        certificateDetails?.daysUntilExpiry
    }

    public var isExpiringSoon: Bool {
        certificateDetails?.isExpiringSoon ?? false
    }

    public var isExpired: Bool {
        certificateDetails?.isExpired ?? false
    }
}
