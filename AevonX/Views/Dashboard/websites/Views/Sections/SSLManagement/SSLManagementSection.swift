//
//  SSLManagementSection.swift
//  AevonX
//
//  Enhanced SSL Management section with full certificate control,
//  certificate content viewer, and real certificate data display
//

import SwiftUI
import AevonXCoreBridge

struct SSLManagementSection: View {
    @ObservedObject var viewModel: SSLManagementViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Header
                sectionHeader

                if viewModel.isLoading {
                    loadingView
                } else if let cert = viewModel.certificateDetails {
                    // Certificate Details
                    certificateStatusCard(cert)
                    certificateDetailsCard(cert)
                    certificateContentCard
                    certificateActionsCard
                } else {
                    // No SSL
                    noSSLView
                }

                // Force SSL & HSTS — only when certificate exists
                if viewModel.certificateDetails != nil {
                    advancedSecurityCard
                }
            }
            .padding(AXSpacing.xl)
        }
        .sheet(isPresented: $viewModel.showLetsEncryptSheet) {
            LetsEncryptIssueSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showCustomCertSheet) {
            CustomCertificateUploadSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showHSTSSheet) {
            HSTSConfigurationSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SSL/TLS Management")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Text("Manage SSL certificates and security settings")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.load() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.md) {
                ProgressView().scaleEffect(1.2)
                Text("Loading certificate details...")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.xxl)
            Spacer()
        }
    }

    // MARK: - No SSL View

    private var noSSLView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "lock.slash")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axWarning)

            VStack(spacing: AXSpacing.xs) {
                Text("No SSL Certificate")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)

                Text("Secure your website with an SSL certificate")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            }

            HStack(spacing: AXSpacing.md) {
                Button("Issue Let's Encrypt Certificate") {
                    viewModel.showLetsEncryptSheet = true
                }
                .buttonStyle(AXPrimaryButtonStyle())

                Button("Upload Custom Certificate") {
                    viewModel.showCustomCertSheet = true
                }
                .buttonStyle(AXSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.xxl)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
    }

    // MARK: - Certificate Status Card (Enhanced with brand + expiry badge)

    private func certificateStatusCard(_ cert: SSLCertificateDetails) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: cert.status.icon)
                    .font(AXTypography.largeTitle)
                    .foregroundColor(cert.status.color)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AXSpacing.sm) {
                        Text(cert.status.rawValue)
                            .font(AXTypography.title2)
                            .foregroundColor(.axTextPrimary)

                        // Brand badge
                        Text(cert.brand)
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(cert.isLetsEncrypt ? Color.axSuccess : Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                    }

                    HStack(spacing: AXSpacing.sm) {
                        if cert.isValid {
                            Text("Certificate is active and valid")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        } else if cert.isExpired {
                            Text("Certificate has expired")
                                .font(AXTypography.body)
                                .foregroundColor(.axError)
                        } else if cert.isExpiringSoon {
                            Text("Certificate expires in \(cert.daysUntilExpiry) days")
                                .font(AXTypography.body)
                                .foregroundColor(.axWarning)
                        }

                        Text("·")
                            .foregroundColor(.axTextMuted)

                        // Expiry badge
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(AXTypography.caption)
                            Text("Exp in \(cert.daysUntilExpiry) days")
                                .font(AXTypography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(cert.isExpiringSoon ? .axWarning : cert.isExpired ? .axError : .axTextSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(cert.securityGrade)
                        .font(AXTypography.largeTitle).fontWeight(.bold)
                        .foregroundColor(gradeColor(cert.securityGrade))

                    Text("Security Grade")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
            }

            if cert.isExpiringSoon {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axWarning)
                    Text("Renew your certificate soon to avoid service interruption")
                        .font(AXTypography.body)
                        .foregroundColor(.axWarning)
                }
                .padding(AXSpacing.md)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(cert.status.color, lineWidth: 2)
        )
    }

    // MARK: - Certificate Details Card

    private func certificateDetailsCard(_ cert: SSLCertificateDetails) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Certificate Details")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            VStack(spacing: AXSpacing.sm) {
                DetailRow(label: "Issuer", value: cert.issuer, icon: "building.2")
                DetailRow(label: "Brand", value: cert.brand, icon: "tag")
                DetailRow(label: "Subject", value: cert.subject, icon: "person.text.rectangle")
                DetailRow(label: "Valid From", value: formattedDate(cert.validFrom), icon: "calendar")
                DetailRow(label: "Valid Until", value: formattedDate(cert.validUntil), icon: "calendar.badge.clock")
                DetailRow(label: "Serial Number", value: cert.serialNumber, icon: "number")
                DetailRow(label: "Key Size", value: "\(cert.keySize) bits", icon: "key")
                DetailRow(label: "Signature", value: cert.signatureAlgorithm, icon: "checkmark.seal")
                DetailRow(label: "Type", value: cert.certificateType.rawValue, icon: cert.certificateType.icon)

                if !cert.sanDomains.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.axTextTertiary)
                                .frame(width: 20)
                            Text("Covered Domains")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                        ForEach(Array(Set(cert.sanDomains)).sorted(), id: \.self) { domain in
                            Text(domain)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .padding(.leading, 24)
                        }
                    }
                }

                if !cert.protocols.isEmpty {
                    DetailRow(
                        label: "TLS Protocols",
                        value: cert.protocols.joined(separator: ", "),
                        icon: "shield.checkered"
                    )
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    // MARK: - Certificate Content Card (PEM Viewer)

    private var certificateContentCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text("Certificate Content")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                if viewModel.certificateContent == nil && !viewModel.isLoadingContent {
                    Button(action: {
                        Task { await viewModel.loadCertificateContent() }
                    }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "eye")
                            Text("View Content")
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if viewModel.isLoadingContent {
                HStack {
                    Spacer()
                    ProgressView("Loading certificate content...")
                        .font(AXTypography.caption)
                    Spacer()
                }
                .padding(AXSpacing.md)
            } else if let content = viewModel.certificateContent {
                // Certificate PEM
                PEMContentBlock(
                    title: "Certificate (PEM)",
                    content: content.certificate,
                    icon: "doc.text"
                )

                // Private Key PEM
                PEMContentBlock(
                    title: "Private Key (PEM)",
                    content: content.privateKey,
                    icon: "key",
                    isSensitive: true
                )
            } else {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.axTextTertiary)
                    Text("Click \"View Content\" to load the certificate and private key PEM data")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                .padding(AXSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    // MARK: - Certificate Actions Card

    private var certificateActionsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Certificate Actions")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            VStack(spacing: AXSpacing.sm) {
                SSLActionButton(
                    title: "Renew Certificate",
                    subtitle: "Renew the current SSL certificate",
                    icon: "arrow.triangle.2.circlepath",
                    color: .axAccentBlue,
                    isLoading: viewModel.isRenewing
                ) {
                    Task { await viewModel.renewCertificate() }
                }

                SSLActionButton(
                    title: "Issue New Let's Encrypt Certificate",
                    subtitle: "Replace with a new Let's Encrypt certificate",
                    icon: "lock.shield.fill",
                    color: .axSuccess,
                    isLoading: false
                ) {
                    viewModel.showLetsEncryptSheet = true
                }

                SSLActionButton(
                    title: "Upload Custom Certificate",
                    subtitle: "Replace with your own SSL certificate",
                    icon: "arrow.up.doc.fill",
                    color: .axAccentBlue,
                    isLoading: false
                ) {
                    viewModel.showCustomCertSheet = true
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    // MARK: - Advanced Security Card

    private var advancedSecurityCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Advanced Security")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            VStack(spacing: AXSpacing.sm) {
                // Force HTTPS Toggle
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "lock.fill")
                        .font(AXTypography.title)
                        .foregroundColor(viewModel.isForceSSLEnabled ? .axSuccess : .axTextSecondary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Force HTTPS")
                            .font(AXTypography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)

                        Text(viewModel.isForceSSLEnabled ? "All HTTP traffic is redirected to HTTPS" : "Redirect all HTTP traffic to HTTPS")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }

                    Spacer()

                    if viewModel.isEnablingForceSSL {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { viewModel.isForceSSLEnabled },
                            set: { _ in
                                Task { await viewModel.toggleForceSSL() }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                        .frame(width: 40)
                    }
                }
                .padding(AXSpacing.md)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)

                SSLActionButton(
                    title: "Configure HSTS",
                    subtitle: "HTTP Strict Transport Security settings",
                    icon: "shield.lefthalf.filled",
                    color: .axAccentBlue,
                    isLoading: false
                ) {
                    viewModel.showHSTSSheet = true
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return .axSuccess
        case "B": return .axWarning
        default: return .axError
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - PEM Content Block

struct PEMContentBlock: View {
    let title: String
    let content: String
    let icon: String
    var isSensitive: Bool = false

    @State private var isRevealed: Bool = false
    @State private var copied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.axTextTertiary)
                    .font(AXTypography.body)

                Text(title)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                Spacer()

                HStack(spacing: AXSpacing.sm) {
                    if isSensitive {
                        Button(action: { isRevealed.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: isRevealed ? "eye.slash" : "eye")
                                Text(isRevealed ? "Hide" : "Show")
                            }
                            .font(AXTypography.footnote)
                            .foregroundColor(.axAccentBlue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(content, forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy")
                        }
                        .font(AXTypography.footnote)
                        .foregroundColor(copied ? .axSuccess : .axTextTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if !isSensitive || isRevealed {
                ScrollView {
                    Text(content)
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            } else {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.axTextMuted)
                    Text("Content hidden — click \"Show\" to reveal")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .padding(AXSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.axTextTertiary)
                .frame(width: 20)

            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - SSL Action Button

struct SSLActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(AXTypography.title)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AXTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)

                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.axTextTertiary)
                }
            }
            .padding(AXSpacing.md)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}
