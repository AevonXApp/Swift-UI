//
//  WebsitePanelComponents.swift
//  AevonX
//
//  Reusable UI components extracted from ModernWebsitePanel
//  for use across all website management sections
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Info Grid

struct InfoGrid: View {
    let website: WebsiteInfo

    var body: some View {
        VStack(spacing: AXSpacing.xs) {
            AXInfoRow(label: "Document Root", value: website.documentRoot ?? "N/A")
            AXInfoRow(label: "Runtime", value: website.runtime.rawValue)
            if let phpVersion = website.phpVersion {
                AXInfoRow(label: "PHP Version", value: phpVersion)
            }
            if let port = website.port {
                AXInfoRow(label: "Port", value: "\(port)")
            }
            AXInfoRow(label: "Disk Usage", value: website.formattedDiskUsage)
            AXInfoRow(label: "Bandwidth", value: website.formattedBandwidth)
            if let created = website.createdAt {
                AXInfoRow(label: "Created", value: created.formatted())
            }
            if let deployed = website.lastDeployed {
                AXInfoRow(label: "Last Deployed", value: deployed.formatted())
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - SSL Overview Card

struct SSLOverviewCard: View {
    let ssl: SSLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Provider")
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextSecondary)
                    Text(ssl.provider.rawValue)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextSecondary)
                    Text(ssl.status.rawValue.capitalized)
                        .font(AXTypography.headline)
                        .foregroundColor(ssl.status == .active ? .axSuccess : .axWarning)
                }
            }

            if ssl.isExpiringSoon, let days = ssl.daysUntilExpiry {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axWarning)
                    Text("Certificate expires in \(days) days")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axWarning)
                }
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Health Issue Row

struct HealthIssueRow: View {
    let issue: WebsiteHealthIssue

    var body: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Image(systemName: severityIcon)
                .font(AXTypography.title3)
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Text(issue.description)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)

                if let recommendation = issue.recommendation {
                    Text(recommendation)
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextTertiary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(AXSpacing.md)
        .background(severityColor.opacity(0.05))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(severityColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var severityIcon: String {
        switch issue.severity {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch issue.severity {
        case .critical: return .axError
        case .warning: return .axWarning
        case .info: return .axAccentBlue
        }
    }
}

// MARK: - Alias Row

struct AliasRow: View {
    let alias: String

    var body: some View {
        HStack {
            Image(systemName: "link")
                .font(AXTypography.footnote)
                .foregroundColor(.axAccentBlue)

            Text(alias)
                .font(AXTypography.monoMd)
                .foregroundColor(.axTextPrimary)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.sm)
    }
}

// MARK: - Connection Row

struct ConnectionRow: View {
    let connection: DetailedConnection
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        HStack {
            Image(systemName: "wifi")
                .font(AXTypography.subheadline)
                .foregroundColor(.axAccentBlue)

            Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses ? PrivacyMask.ip(connection.ip) : connection.ip)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.axTextPrimary)

            Spacer()

            Text("\(connection.count)")
                .font(AXTypography.callout).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.sm)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextTertiary.opacity(0.5))

            VStack(spacing: 4) {
                Text(title)
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)

                Text(message)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AXSpacing.xxl)
        .frame(maxWidth: .infinity)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

