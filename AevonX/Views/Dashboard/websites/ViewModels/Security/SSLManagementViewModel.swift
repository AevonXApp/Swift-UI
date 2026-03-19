//
//  SSLManagementViewModel.swift
//  AevonX
//
//  ViewModel for SSL Management section — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

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
    private let bridge = WebsitesBridge.shared
    private let toastManager = GlobalToastManager.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

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

        // Detect Force SSL state via config check
        await detectPathsIfNeeded()
        let configPath = "\(serverPaths.nginxSitesAvailable)/\(website.domain)"
        let forceResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "grep -c 'return 301 https' \(configPath) 2>/dev/null")
        isForceSSLEnabled = (Int(forceResult.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0

        // Fetch certificate details
        let cmd = bridge.sslStatusCmd(domain: website.domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseSSLStatus(domain: website.domain, output: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let certData = resp["data"] as? [String: Any] {
            
            // Parse date strings from Go (e.g. "Mar 10 12:00:00 2026 GMT")
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMM  d HH:mm:ss yyyy z"
            let altFormatter = DateFormatter()
            altFormatter.locale = Locale(identifier: "en_US_POSIX")
            altFormatter.dateFormat = "MMM d HH:mm:ss yyyy z"
            
            let validFromStr = certData["valid_from"] as? String ?? ""
            let validToStr = certData["valid_to"] as? String ?? ""
            
            let validFrom = dateFormatter.date(from: validFromStr) ?? altFormatter.date(from: validFromStr) ?? Date()
            let validUntil = dateFormatter.date(from: validToStr) ?? altFormatter.date(from: validToStr) ?? Date()
            
            // Compute expiry info
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
            let isExpired = validUntil < Date()
            let isExpiringSoon = daysUntilExpiry <= 30 && !isExpired
            
            // Compute status
            let status: SSLCertificateStatus
            if isExpired {
                status = .expired
            } else if isExpiringSoon {
                status = .expiringSoon
            } else {
                status = .valid
            }
            
            // Parse brand from issuer (e.g. "C = US, O = Let's Encrypt, CN = E7")
            let issuerStr = certData["issuer"] as? String ?? "Unknown"
            let brand = parseBrandFromIssuer(issuerStr)
            
            let details = SSLCertificateDetails(
                issuer: issuerStr,
                validFrom: validFrom,
                validUntil: validUntil,
                brand: brand,
                status: status,
                domains: [website.domain],
                daysUntilExpiry: daysUntilExpiry,
                isExpiringSoon: isExpiringSoon,
                isExpired: isExpired
            )
            certificateDetails = details
        }

        isLoading = false
    }
    
    // MARK: - Brand Parsing
    
    /// Parse certificate brand/authority from issuer string.
    private func parseBrandFromIssuer(_ issuer: String) -> String {
        // Try O= first (e.g. "C = US, O = Let's Encrypt, CN = E7")
        if let oRange = issuer.range(of: "O = ") ?? issuer.range(of: "O=") {
            let afterO = issuer[oRange.upperBound...]
            let brand = afterO.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? String(afterO)
            return brand.trimmingCharacters(in: .whitespaces)
        }
        // Fallback: try CN=
        if let cnRange = issuer.range(of: "CN = ") ?? issuer.range(of: "CN=") {
            let afterCN = issuer[cnRange.upperBound...]
            let brand = afterCN.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? String(afterCN)
            return brand.trimmingCharacters(in: .whitespaces)
        }
        return "Unknown"
    }

    // MARK: - Certificate Content

    public func loadCertificateContent() async {
        guard let serverId = serverId else { return }

        isLoadingContent = true

        let certPath = "/etc/letsencrypt/live/\(website.domain)/fullchain.pem"
        let keyPath = "/etc/letsencrypt/live/\(website.domain)/privkey.pem"
        let certResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo cat \(certPath) 2>/dev/null")
        let keyResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo cat \(keyPath) 2>/dev/null")
        certificateContent = SSLCertificateContent(
            certificate: certResult,
            privateKey: keyResult,
            chain: nil
        )

        isLoadingContent = false
    }

    // MARK: - DNS Challenge Records

    public func loadDNSRecords() async {
        guard let serverId = serverId else { return }

        isLoadingDNSRecords = true

        let cmd = bridge.dnsLookupCmd(domain: website.domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseDNSRecords(domain: website.domain, output: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let records = resp["data"] as? [[String: String]] {
            dnsRecords = records.compactMap { dict in
                guard let type = dict["type"], let name = dict["name"], let value = dict["value"] else { return nil }
                return SSLDNSRecord(type: type, name: name, value: value)
            }
        }

        isLoadingDNSRecords = false
    }

    // MARK: - Let's Encrypt

    public func issueLetsEncryptCertificate() async {
        guard let serverId = serverId else { return }

        isIssuingCertificate = true
        error = nil

        let cmds = bridge.issueSSLCmd(domain: website.domain)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }

        showLetsEncryptSheet = false
        toastManager.showSuccess("Let's Encrypt certificate issued successfully")

        await load()

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

        let cmds = bridge.uploadCustomCertCmds(
            domain: website.domain,
            cert: customCertificate,
            key: customPrivateKey,
            chain: customChain.isEmpty ? nil : customChain
        )
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

        showCustomCertSheet = false
        toastManager.showSuccess("Custom certificate uploaded successfully")

        customCertificate = ""
        customPrivateKey = ""
        customChain = ""

        await load()

        isUploadingCertificate = false
    }

    // MARK: - Force SSL

    public func toggleForceSSL() async {
        guard let serverId = serverId else { return }

        isEnablingForceSSL = true

        if !isForceSSLEnabled {
            let cmd = bridge.enableForceSSLCmd(domain: website.domain)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            isForceSSLEnabled = true
            toastManager.showSuccess("Force HTTPS enabled — all HTTP traffic will redirect to HTTPS")
        } else {
            let cmd = bridge.disableForceSSLCmd(domain: website.domain)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            isForceSSLEnabled = false
            toastManager.showSuccess("Force HTTPS disabled")
        }

        isEnablingForceSSL = false
    }

    // MARK: - HSTS

    public func configureHSTS() async {
        guard let serverId = serverId else { return }

        isConfiguringHSTS = true

        let cmd = bridge.configureHSTSCmd(
            domain: website.domain,
            maxAge: hstsConfig.maxAge,
            includeSubdomains: hstsConfig.includeSubDomains
        )
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())

        showHSTSSheet = false
        toastManager.showSuccess("HSTS configured successfully")

        isConfiguringHSTS = false
    }

    // MARK: - Certificate Renewal

    public func renewCertificate() async {
        guard let serverId = serverId else { return }

        isRenewing = true

        let cmd = bridge.renewSSLCmd(domain: website.domain)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        toastManager.showSuccess("Certificate renewal started")

        await load()

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

    private func detectPathsIfNeeded() async {
        guard !pathsDetected, let serverId = serverId else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }
}
