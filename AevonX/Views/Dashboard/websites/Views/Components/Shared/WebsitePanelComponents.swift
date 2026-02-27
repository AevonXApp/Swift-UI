//
//  WebsitePanelComponents.swift
//  AevonX
//
//  Reusable UI components extracted from ModernWebsitePanel
//  for use across all website management sections
//

import SwiftUI
import AevonXCore

// MARK: - Metric Card

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let trend: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.axAccentBlue)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.axTextPrimary)
        }
    }
}

// MARK: - Config Card

struct ConfigCard<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let content: () -> Content

    init(icon: String, title: String, description: String, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.description = description
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axAccentBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)
                }
            }

            content()
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

// MARK: - Info Grid

struct InfoGrid: View {
    let website: WebsiteInfo

    var body: some View {
        VStack(spacing: AXSpacing.xs) {
            InfoRow(label: "Document Root", value: website.documentRoot ?? "N/A")
            InfoRow(label: "Runtime", value: website.runtime.rawValue)
            if let phpVersion = website.phpVersion {
                InfoRow(label: "PHP Version", value: phpVersion)
            }
            if let port = website.port {
                InfoRow(label: "Port", value: "\(port)")
            }
            InfoRow(label: "Disk Usage", value: website.formattedDiskUsage)
            InfoRow(label: "Bandwidth", value: website.formattedBandwidth)
            if let created = website.createdAt {
                InfoRow(label: "Created", value: created.formatted())
            }
            if let deployed = website.lastDeployed {
                InfoRow(label: "Last Deployed", value: deployed.formatted())
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

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextPrimary)
        }
        .padding(.vertical, 4)
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
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                    Text(ssl.provider.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                    Text(ssl.status.rawValue.capitalized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ssl.status == .active ? .axSuccess : .axWarning)
                }
            }

            if ssl.isExpiringSoon, let days = ssl.daysUntilExpiry {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axWarning)
                    Text("Certificate expires in \(days) days")
                        .font(.system(size: 12))
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
                .font(.system(size: 16))
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text(issue.description)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)

                if let recommendation = issue.recommendation {
                    Text(recommendation)
                        .font(.system(size: 11))
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
                .font(.system(size: 11))
                .foregroundColor(.axAccentBlue)

            Text(alias)
                .font(.system(size: 13, design: .monospaced))
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

    var body: some View {
        HStack {
            Image(systemName: "wifi")
                .font(.system(size: 12))
                .foregroundColor(.axAccentBlue)

            Text(connection.ip)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.axTextPrimary)

            Spacer()

            Text("\(connection.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.axAccentBlue)
                .cornerRadius(6)
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

// MARK: - Empty State Views

struct EmptyStateMessage: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.axTextTertiary)

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.sm)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.axTextTertiary.opacity(0.5))

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text(message)
                    .font(.system(size: 12))
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

// MARK: - Premium Sidebar Button

struct PremiumSidebarButton: View {
    let item: ModernSidebarItem
    var runtime: RuntimeType = .php
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : Color.axBackground.opacity(isHovered ? 0.5 : 0))
                        .frame(width: 32, height: 32)

                    Image(systemName: item.icon(for: runtime))
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                }

                // Title
                Text(item.displayName(for: runtime))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()

                // Selection Indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axAccentBlue)
                        .frame(width: 3, height: 16)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.05) : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Sidebar Category Header

struct SidebarCategoryHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.axTextMuted)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.axTextMuted)
                .tracking(0.8)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.top, AXSpacing.lg)
        .padding(.bottom, AXSpacing.xxs)
    }
}
