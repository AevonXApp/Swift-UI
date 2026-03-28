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

    private let log = CoreLogger.shared
    private let module = "SSL"

    // MARK: - Computed Properties

    /// The website domain for display
    public var domain: String { website.domain }

    /// The web server engine for this website ("nginx" or "apache")
    private var engine: String { website.webServerEngine ?? "nginx" }

    /// Resolved config path for this website
    private var resolvedConfigPath: String {
        if let p = website.configPath, !p.isEmpty { return p }
        let sa = serverPaths.nginxSitesAvailable
        if sa.contains("/conf.d") || sa.contains("/vhost") || sa.contains("/www/server") {
            return "\(sa)/\(website.domain).conf"
        }
        return "\(sa)/\(website.domain)"
    }

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

        guard !isLoading else { return }

        isLoading = true
        error = nil

        log.debug("[\(website.domain)] Loading SSL details...", module: module)

        // Detect server paths
        await detectPathsIfNeeded()
        let configPath = resolvedConfigPath
        log.debug("[\(website.domain)] Config path: \(configPath)", module: module)

        // Detect Force SSL state — search ALL nginx configs for this domain's redirect
        let forceCmd = bridge.checkForceSSLDomainCmd(domain: website.domain)
        let forceResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: forceCmd)
        isForceSSLEnabled = (Int(forceResult.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0
        log.debug("[\(website.domain)] Force SSL: \(isForceSSLEnabled)", module: module)

        // Fetch LIVE certificate from port 443 via openssl s_client
        let cmd = bridge.sslStatusCmd(domain: website.domain)
        log.debug("[\(website.domain)] SSL probe command: \(cmd.prefix(120))...", module: module)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        log.debug("[\(website.domain)] SSL probe raw output (\(result.count) chars): \(result.prefix(300))", module: module)

        let parsedJSON = bridge.parseSSLStatus(domain: website.domain, output: result)
        log.debug("[\(website.domain)] Parsed SSL JSON: \(parsedJSON.prefix(500))", module: module)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let certData = resp["data"] as? [String: Any] {

            // Check if the cert is a mismatch (served by another domain's catch-all)
            let isMismatch = certData["mismatch"] as? Bool ?? false
            if isMismatch {
                log.debug("[\(website.domain)] Certificate MISMATCH — cert belongs to different domain", module: module)
                certificateDetails = nil
                isLoading = false
                return
            }

            // Parse date strings from Go (e.g. "Mar 10 12:00:00 2026 GMT")
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMM  d HH:mm:ss yyyy z"
            let altFormatter = DateFormatter()
            altFormatter.locale = Locale(identifier: "en_US_POSIX")
            altFormatter.dateFormat = "MMM d HH:mm:ss yyyy z"

            let validFromStr = certData["valid_from"] as? String ?? ""
            let validToStr = certData["valid_to"] as? String ?? ""
            let subjectStr = certData["subject"] as? String ?? ""

            let validFrom = dateFormatter.date(from: validFromStr) ?? altFormatter.date(from: validFromStr) ?? Date()
            let validUntil = dateFormatter.date(from: validToStr) ?? altFormatter.date(from: validToStr) ?? Date()

            log.debug("[\(website.domain)] Cert dates: from=\(validFromStr) to=\(validToStr)", module: module)

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

            // Parse actual SAN domains from certificate (deduplicated)
            let sansStr = certData["sans"] as? String ?? ""
            let domains: [String] = {
                if sansStr.isEmpty { return [website.domain] }
                let parsed = sansStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                return Array(Set(parsed)).sorted()
            }()

            // Parse key size and signature algorithm
            let keySize = Int(certData["key_size"] as? String ?? "") ?? 2048
            let signatureAlg = certData["signature_alg"] as? String ?? "SHA256withRSA"
            let serialNumber = certData["serial_number"] as? String ?? ""

            log.debug("[\(website.domain)] Cert: issuer=\(issuerStr) brand=\(brand) keySize=\(keySize) sig=\(signatureAlg) days=\(daysUntilExpiry) sans=\(sansStr)", module: module)

            let details = SSLCertificateDetails(
                issuer: issuerStr,
                subject: subjectStr,
                validFrom: validFrom,
                validUntil: validUntil,
                serialNumber: serialNumber,
                signatureAlgorithm: signatureAlg,
                keySize: keySize,
                brand: brand,
                status: status,
                domains: domains,
                daysUntilExpiry: daysUntilExpiry,
                isExpiringSoon: isExpiringSoon,
                isExpired: isExpired
            )
            certificateDetails = details
        } else {
            log.debug("[\(website.domain)] No certificate found on port 443", module: module)
            certificateDetails = nil
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

        let certCmd = bridge.readCertificateCmd(domain: website.domain)
        let keyCmd = bridge.readPrivateKeyCmd(domain: website.domain)
        log.debug("[\(website.domain)] Reading cert PEM: \(certCmd.prefix(100))...", module: module)

        let certResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: certCmd)
        let keyResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: keyCmd)

        log.debug("[\(website.domain)] Cert PEM: \(certResult.count) chars, Key PEM: \(keyResult.count) chars", module: module)

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

        log.debug("[\(website.domain)] Issuing Let's Encrypt cert (engine=\(engine))...", module: module)

        var lastOutput = ""
        let cmds = bridge.issueSSLCmd(engine: engine, domain: website.domain)
        for (i, cmd) in cmds.enumerated() {
            log.debug("[\(website.domain)] LE cmd[\(i)]: \(cmd.prefix(120))...", module: module)
            lastOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            log.debug("[\(website.domain)] LE result[\(i)]: \(lastOutput.prefix(300))", module: module)
        }

        showLetsEncryptSheet = false

        // Check for certbot success/failure markers
        if lastOutput.contains("AEVON_SSL_FAILED") || lastOutput.contains("Certificate not yet due for renewal") || (lastOutput.contains("error") && lastOutput.contains("certbot")) {
            error = "SSL issuance failed"
            log.debug("[\(website.domain)] LE issuance FAILED: \(lastOutput.suffix(200))", module: module)
            toastManager.showError("SSL certificate issuance failed — check server logs")
        } else {
            log.debug("[\(website.domain)] LE issuance SUCCESS", module: module)
            toastManager.showSuccess("Let's Encrypt certificate issued successfully")
        }

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

        // Validate PEM format
        let errors = upload.validate()
        guard errors.isEmpty else {
            error = errors.joined(separator: "\n")
            toastManager.showError(error!)
            return
        }

        isUploadingCertificate = true
        error = nil

        // Capture old cert fingerprint before upload for comparison
        let oldSerial = certificateDetails?.serialNumber ?? ""
        let oldIssuer = certificateDetails?.issuer ?? ""

        // Step 0: Discover the ACTUAL nginx config file with SSL directives for this domain.
        // The guessed path (sites-available/domain) is often HTTP-only; certbot may have placed
        // SSL in a different file (e.g. sites-enabled symlink, -le-ssl.conf, conf.d/).
        var configPath = resolvedConfigPath
        let discoverCmd = bridge.findSSLConfigCmd(domain: website.domain)
        let discoveredPath = await SSHBridge.shared.executeAsync(serverID: serverId, command: discoverCmd).trimmingCharacters(in: .whitespacesAndNewlines)
        if !discoveredPath.isEmpty {
            log.debug("[\(website.domain)] SSL config discovered: \(discoveredPath)", module: module)
            configPath = discoveredPath
        } else {
            log.debug("[\(website.domain)] No existing SSL config found, using default: \(configPath)", module: module)
        }

        log.debug("[\(website.domain)] Uploading custom cert (engine=\(engine), configPath=\(configPath))", module: module)
        log.debug("[\(website.domain)] Cert: \(customCertificate.count) chars, Key: \(customPrivateKey.count) chars, Chain: \(customChain.count) chars", module: module)
        log.debug("[\(website.domain)] Old cert on port 443: serial=\(oldSerial) issuer=\(oldIssuer)", module: module)

        let cmds = bridge.uploadCustomCertCmds(
            engine: engine,
            domain: website.domain,
            cert: customCertificate,
            key: customPrivateKey,
            chain: customChain.isEmpty ? nil : customChain,
            configPath: configPath,
            docRoot: website.documentRoot ?? ""
        )

        log.debug("[\(website.domain)] Upload commands: \(cmds.count) steps", module: module)

        var lastOutput = ""
        var anyFailed = false
        for (i, cmd) in cmds.enumerated() {
            let cmdPreview = cmd.count > 200 ? "\(cmd.prefix(100))...[truncated \(cmd.count) chars]" : cmd
            log.debug("[\(website.domain)] Upload step[\(i)]: \(cmdPreview)", module: module)

            lastOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            log.debug("[\(website.domain)] Upload result[\(i)]: \(lastOutput.prefix(500))", module: module)

            if lastOutput.contains("AEVON_CERT_FAILED") {
                anyFailed = true
                log.debug("[\(website.domain)] Upload step[\(i)] FAILED", module: module)
                break
            }
        }

        if anyFailed {
            error = "Certificate upload failed — nginx config test failed"
            log.debug("[\(website.domain)] Upload FAILED. Last output: \(lastOutput)", module: module)
            toastManager.showError("Certificate installation failed — check logs")
        } else {
            log.debug("[\(website.domain)] Upload commands completed. Verifying cert on port 443...", module: module)

            // Fingerprint verification: compare uploaded file vs what port 443 serves
            let verifyCmd = bridge.verifyCertActiveCmd(domain: website.domain)
            let verifyOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: verifyCmd)
            log.debug("[\(website.domain)] Cert verification: \(verifyOutput.prefix(500))", module: module)
            if verifyOutput.contains("AEVON_CERT_MISMATCH") {
                log.debug("[\(website.domain)] WARNING: File fingerprint != live fingerprint. Nginx may not be using the new cert.", module: module)
            } else if verifyOutput.contains("AEVON_CERT_VERIFIED") {
                log.debug("[\(website.domain)] Cert fingerprint VERIFIED — port 443 is serving the uploaded cert", module: module)
            }

            // Reload to verify the new cert is actually being served
            await load()

            if let newCert = certificateDetails {
                let newSerial = newCert.serialNumber
                let newIssuer = newCert.issuer

                if newSerial == oldSerial && newIssuer == oldIssuer && !oldSerial.isEmpty {
                    log.debug("[\(website.domain)] WARNING: Cert on port 443 UNCHANGED after upload! serial=\(newSerial) issuer=\(newIssuer) — you may have uploaded the same certificate", module: module)
                    toastManager.showError("Certificate unchanged — you may have uploaded the same cert that was already active")
                } else {
                    log.debug("[\(website.domain)] Custom cert VERIFIED on port 443: issuer=\(newIssuer) serial=\(newSerial) expiry=\(newCert.daysUntilExpiry) days (was: issuer=\(oldIssuer) serial=\(oldSerial))", module: module)
                    toastManager.showSuccess("Custom certificate installed successfully")
                }

                showCustomCertSheet = false
                customCertificate = ""
                customPrivateKey = ""
                customChain = ""
            } else {
                error = "Certificate files written but nginx may not be serving them — check config"
                log.debug("[\(website.domain)] Custom cert NOT detected on port 443 after upload", module: module)
                toastManager.showError("Certificate files saved but not yet active — check logs")
            }
        }

        // Reset cert content cache so it reloads from new path
        certificateContent = nil

        isUploadingCertificate = false
    }

    // MARK: - Force SSL

    public func toggleForceSSL() async {
        guard let serverId = serverId else { return }

        isEnablingForceSSL = true

        let configPath = resolvedConfigPath
        let docRoot = website.documentRoot ?? ""
        if !isForceSSLEnabled {
            let cmd = bridge.enableForceSSLCmd(engine: engine, configPath: configPath, docRoot: docRoot)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId))
            isForceSSLEnabled = true
            toastManager.showSuccess("Force HTTPS enabled — all HTTP traffic will redirect to HTTPS")
        } else {
            let cmd = bridge.disableForceSSLCmd(engine: engine, configPath: configPath, docRoot: docRoot)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId))
            isForceSSLEnabled = false
            toastManager.showSuccess("Force HTTPS disabled")
        }

        isEnablingForceSSL = false
    }

    // MARK: - HSTS

    public func configureHSTS() async {
        guard let serverId = serverId else { return }

        isConfiguringHSTS = true

        let configPath = resolvedConfigPath
        let cmd = bridge.configureHSTSCmd(
            engine: engine,
            configPath: configPath,
            maxAge: hstsConfig.maxAge,
            includeSubdomains: hstsConfig.includeSubDomains
        )
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId))

        showHSTSSheet = false
        toastManager.showSuccess("HSTS configured successfully")

        isConfiguringHSTS = false
    }

    // MARK: - Certificate Renewal

    public func renewCertificate() async {
        guard let serverId = serverId else { return }

        isRenewing = true

        log.debug("[\(website.domain)] Renewing cert (engine=\(engine))...", module: module)
        let cmd = bridge.renewSSLCmd(engine: engine, domain: website.domain)
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        log.debug("[\(website.domain)] Renew result: \(output.prefix(300))", module: module)

        // Check renewal result
        if output.contains("AEVON_SSL_FAILED") || output.contains("Cert not yet due for renewal") {
            toastManager.showError("Certificate renewal failed — cert may not be due yet")
        } else if output.contains("AEVON_SSL_SUCCESS") || output.contains("Congratulations") || output.contains("new certificate") {
            toastManager.showSuccess("Certificate renewed successfully")
        } else {
            toastManager.showSuccess("Certificate renewal completed")
        }

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
        log.debug("[\(website.domain)] Detected paths: type=\(serverPaths.serverType) sitesAvailable=\(serverPaths.nginxSitesAvailable)", module: module)
    }
}
