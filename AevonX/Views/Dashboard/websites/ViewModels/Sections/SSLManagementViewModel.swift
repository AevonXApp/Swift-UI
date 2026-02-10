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

    private let website: WebsiteInfo
    private let serverId: String?
    private let coreService = CoreWebsiteService.shared
    private let toastManager = GlobalToastManager.shared

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

        guard website.sslEnabled else {
            certificateDetails = nil
            return
        }

        isLoading = true
        error = nil

        do {
            certificateDetails = try await coreService.getSSLCertificateDetails(domain: website.domain, serverId: serverId)
        } catch {
            self.error = "Failed to load SSL details: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoading = false
    }

    // MARK: - Let's Encrypt

    public func issueLetsEncryptCertificate() async {
        guard let serverId = serverId else { return }

        guard !letsEncryptEmail.isEmpty else {
            error = "Please enter an email address"
            toastManager.showError("Email address is required")
            return
        }

        isIssuingCertificate = true

        do {
            try await coreService.issueNewLetsEncryptCert(
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
            try await coreService.uploadCustomCertificate(
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
                try await coreService.enableForceSSL(domain: website.domain, serverId: serverId)
                isForceSSLEnabled = true
                toastManager.showSuccess("Force SSL enabled")
            } else {
                // Would need a disable method
                toastManager.showInfo("Force SSL disable not yet implemented")
            }
        } catch {
            self.error = "Failed to toggle Force SSL: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isEnablingForceSSL = false
    }

    // MARK: - HSTS

    public func configureHSTS() async {
        guard let serverId = serverId else { return }

        isConfiguringHSTS = true

        do {
            try await coreService.configureHSTS(
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
            try await coreService.renewSSL(websiteId: website.domain, serverId: serverId)
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
