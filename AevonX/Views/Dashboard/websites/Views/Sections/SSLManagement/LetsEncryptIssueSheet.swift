//
//  LetsEncryptIssueSheet.swift
//  AevonX
//
//  Sheet for issuing Let's Encrypt certificates
//  With DNS records table and verification support
//

import SwiftUI
import AevonXCoreBridge

struct LetsEncryptIssueSheet: View {
    @ObservedObject var viewModel: SSLManagementViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(L10n.Button.cancel) {
                    viewModel.showLetsEncryptSheet = false
                }
                .foregroundColor(.axTextSecondary)

                Spacer()

                Text("Issue Let's Encrypt Certificate")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Color.clear.frame(width: 60)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            Divider()

            // Error banner
            if let error = viewModel.error {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.white)
                        .lineLimit(3)
                    Spacer()
                    Button {
                        viewModel.clearError()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(AXSpacing.md)
                .background(Color.axError)
            }

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Info Box
                    HStack(alignment: .top, spacing: AXSpacing.md) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.axAccentBlue)
                            .font(AXTypography.title)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Let's Encrypt")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)

                            Text("Free SSL certificates that auto-renew every 90 days")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)

                    // Email
                    FormSection(title: "Email Address", subtitle: "Required for certificate notifications") {
                        TextField("your@email.com", text: $viewModel.letsEncryptEmail)
                            .textFieldStyle(AXTextFieldStyle())
                    }

                    // Challenge Type
                    FormSection(title: "Verification Method", subtitle: "How Let's Encrypt will verify your domain") {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(SSLChallengeType.allCases, id: \.rawValue) { challenge in
                                ChallengeTypeRow(
                                    challenge: challenge,
                                    isSelected: viewModel.selectedChallengeType == challenge
                                ) {
                                    viewModel.selectedChallengeType = challenge
                                    // Load DNS records when DNS-01 is selected
                                    if challenge == .dns01 {
                                        Task { await viewModel.loadDNSRecords() }
                                    }
                                }
                            }
                        }
                    }

                    // DNS Records Table (shown when DNS-01 is selected)
                    if viewModel.selectedChallengeType == .dns01 {
                        dnsRecordsSection
                    }

                    // Issue Button
                    Button(action: {
                        Task { await viewModel.issueLetsEncryptCertificate() }
                    }) {
                        HStack {
                            if viewModel.isIssuingCertificate {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Issuing Certificate...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Issue Certificate")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(viewModel.isIssuingCertificate)
                }
                .padding(AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .frame(width: 600)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - DNS Records Section

    private var dnsRecordsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Header
            HStack(alignment: .top, spacing: AXSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.axAccentBlue)
                    .font(AXTypography.title3)

                Text("Please add the following DNS records for verification")
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
            }
            .padding(AXSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.axAccentBlue.opacity(0.08))
            .cornerRadius(AXCornerRadius.md)

            if viewModel.isLoadingDNSRecords {
                HStack {
                    Spacer()
                    ProgressView("Loading DNS records...")
                        .font(AXTypography.caption)
                    Spacer()
                }
                .padding(AXSpacing.lg)
            } else if !viewModel.dnsRecords.isEmpty {
                // DNS Records Table
                VStack(spacing: 0) {
                    // Table Header
                    HStack(spacing: 0) {
                        Text("Domain name")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Record value")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Type")
                            .frame(width: 60, alignment: .leading)
                        Text("Required")
                            .frame(width: 70, alignment: .center)
                    }
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface.opacity(0.5))

                    Divider()

                    // Table Rows
                    ForEach(viewModel.dnsRecords) { record in
                        DNSRecordRow(record: record)
                        Divider().opacity(0.5)
                    }
                }
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            }

            // Verification Tips
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                tipRow(
                    text: "It takes some time to resolve the domain name to take effect. After completing all the resolution operations, please wait 1 minute before clicking the verification button",
                    color: .axWarning
                )

                tipRow(
                    text: "You can manually verify whether the domain name resolution is effective through CMD commands: nslookup -q=txt _acme-challenge.\(viewModel.domain)",
                    color: .axTextSecondary
                )

                tipRow(
                    text: "If using Cloudflare, AWS Route 53, or other DNS providers, the DNS interface can be used to automatically resolve",
                    color: .axTextSecondary
                )
            }
        }
    }

    private func tipRow(text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Text("•")
                .foregroundColor(color)
                .font(AXTypography.caption)
            Text(text)
                .font(AXTypography.caption)
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - DNS Record Row

struct DNSRecordRow: View {
    let record: SSLDNSRecord
    @State private var copied = false

    var body: some View {
        HStack(spacing: 0) {
            // Domain Name
            Text(record.domainName)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Record Value + Copy Button
            HStack(spacing: AXSpacing.xs) {
                Text(record.recordValue)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(record.recordValue, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(AXTypography.footnote)
                        .foregroundColor(copied ? .axSuccess : .axTextTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy value")
            }

            // Type
            Text(record.recordType)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .frame(width: 60, alignment: .leading)

            // Required
            Text(record.isRequired ? "YES" : "NO")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(record.isRequired ? .axSuccess : .axTextMuted)
                .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Challenge Type Row

struct ChallengeTypeRow: View {
    let challenge: SSLChallengeType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: challenge.icon)
                    .font(AXTypography.title2)
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.rawValue)
                        .font(AXTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)

                    Text(challenge.description)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.axAccentBlue)
                }
            }
            .padding(AXSpacing.md)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.axBackground)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
