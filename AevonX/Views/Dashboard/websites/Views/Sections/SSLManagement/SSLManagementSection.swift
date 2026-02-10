//
//  SSLManagementSection.swift
//  AevonX
//
//  Enhanced SSL Management section with full certificate control
//

import SwiftUI
import AevonXCore

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
                    certificateActionsCard
                } else {
                    // No SSL
                    noSSLView
                }

                // Force SSL & HSTS
                advancedSecurityCard
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
                .font(.system(size: 60))
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

    // MARK: - Certificate Status Card

    private func certificateStatusCard(_ cert: SSLCertificateDetails) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: cert.status.icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color(cert.status.color))

                VStack(alignment: .leading, spacing: 4) {
                    Text(cert.status.rawValue)
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)

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
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(cert.securityGrade)
                        .font(.system(size: 32, weight: .bold))
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
                .stroke(Color(cert.status.color), lineWidth: 2)
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
                        ForEach(cert.sanDomains, id: \.self) { domain in
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
                SSLActionButton(
                    title: "Force HTTPS",
                    subtitle: viewModel.isForceSSLEnabled ? "All traffic redirected to HTTPS" : "Redirect HTTP to HTTPS",
                    icon: "lock.fill",
                    color: viewModel.isForceSSLEnabled ? .axSuccess : .axTextSecondary,
                    isLoading: viewModel.isEnablingForceSSL
                ) {
                    Task { await viewModel.toggleForceSSL() }
                }

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
                    .font(.system(size: 24))
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
