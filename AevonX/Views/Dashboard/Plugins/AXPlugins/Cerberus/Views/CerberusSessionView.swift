//
//  CerberusSessionView.swift
//  AevonX
//
//  Session Tracking tab — shows active sessions, ATO detections, rate limiting.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusSessionView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                if viewModel.sessionLoading && viewModel.sessionStatus == nil {
                    loadingSkeleton
                } else if let status = viewModel.sessionStatus {
                    heroSection(status)
                    statsGrid(status)
                    securityPanel(status)
                } else {
                    emptyState
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadSessionStatus() }
    }
}

// MARK: - Hero Section

private extension CerberusSessionView {

    func heroSection(_ status: WAFSessionStatus) -> some View {
        AXGlassCard(accentColor: .axAccentPurple) {
            HStack(spacing: AXSpacing.lg) {
                heroIcon
                heroTitleBlock(status)
                Spacer()
                refreshButton
            }
        }
    }

    var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.axAccentPurple.opacity(0.3),
                            Color.axAccentBlue.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 28
                    )
                )
                .frame(width: 56, height: 56)
            Image(systemName: "shield.checkered")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.axAccentPurple)
        }
    }

    func heroTitleBlock(_ status: WAFSessionStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            Text("Session Tracking")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axTextPrimary)
            Text(status.enabled
                 ? "Actively monitoring user sessions"
                 : "Session tracking is disabled")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextSecondary)
            heroBadge(enabled: status.enabled)
        }
    }

    func heroBadge(enabled: Bool) -> some View {
        AXBadge(
            text: enabled ? L10n.Status.enabled : L10n.Status.disabled,
            color: enabled ? .axAccentGreen : .axTextMuted,
            style: .soft
        )
    }

    var refreshButton: some View {
        Button {
            Task { await viewModel.loadSessionStatus() }
        } label: {
            refreshButtonLabel
        }
        .buttonStyle(.plain)
        .disabled(viewModel.sessionLoading)
    }

    var refreshButtonLabel: some View {
        HStack(spacing: AXSpacing.xs) {
            if viewModel.sessionLoading {
                ProgressView()
                    .controlSize(.small)
            }
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(Color.axAccentBlue)
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axAccentBlue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
    }
}

// MARK: - Stats Grid

private extension CerberusSessionView {

    func statsGrid(_ status: WAFSessionStatus) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4),
            spacing: AXSpacing.md
        ) {
            statCard(
                label: "Active Sessions",
                value: "\(status.activeSessions ?? 0)",
                icon: "person.crop.circle.fill",
                color: .axAccentBlue
            )
            statCard(
                label: "Total Tracked",
                value: "\(status.totalTracked ?? 0)",
                icon: "person.2.fill",
                color: .axAccentGreen
            )
            statCard(
                label: "ATO Detections",
                value: "\(status.atoDetections ?? 0)",
                icon: "exclamationmark.shield.fill",
                color: .axError
            )
            statCard(
                label: "Rate Limited",
                value: "\(status.rateLimited ?? 0)",
                icon: "speedometer",
                color: .axWarning
            )
        }
    }

    func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.md) {
                statIconBox(icon: icon, color: color)
                statValueBlock(value: value, label: label)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.lg)
        }
    }

    func statIconBox(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(color.opacity(0.12))
                .frame(width: 40, height: 40)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    func statValueBlock(value: String, label: String) -> some View {
        VStack(spacing: AXSpacing.xxs) {
            Text(value)
                .font(AXTypography.title2)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
                .lineLimit(1)
        }
    }
}

// MARK: - Security Panel

private extension CerberusSessionView {

    func securityPanel(_ status: WAFSessionStatus) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                securityPanelHeader
                Divider().background(Color.axDivider)
                securityRow(
                    icon: "key.fill",
                    title: "Session Cookie",
                    detail: "cerberus_sid",
                    color: .axAccentBlue
                )
                securityRow(
                    icon: "gauge.with.needle.fill",
                    title: "Rate Limit",
                    detail: "\(status.rateLimited ?? 0) enforced",
                    color: .axWarning
                )
                securityRow(
                    icon: "person.badge.shield.checkmark.fill",
                    title: "ATO Detection",
                    detail: atoStatusText(status),
                    color: atoStatusColor(status)
                )
            }
            .padding(AXSpacing.lg)
        }
    }

    var securityPanelHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.axAccentPurple)
            Text("Session Security")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
        }
    }

    func securityRow(icon: String, title: String, detail: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            securityRowIcon(icon: icon, color: color)
            securityRowText(title: title, detail: detail)
            Spacer()
        }
    }

    func securityRowIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(color.opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    func securityRowText(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(title)
                .font(AXTypography.subheadline)
                .foregroundStyle(Color.axTextPrimary)
            Text(detail)
                .font(AXTypography.monoXs)
                .foregroundStyle(Color.axTextSecondary)
        }
    }

    func atoStatusText(_ status: WAFSessionStatus) -> String {
        let count = status.atoDetections ?? 0
        if !status.enabled { return L10n.Status.disabled }
        return count > 0 ? "\(count) threat\(count == 1 ? "" : "s") detected" : "No threats"
    }

    func atoStatusColor(_ status: WAFSessionStatus) -> Color {
        let count = status.atoDetections ?? 0
        if !status.enabled { return .axTextMuted }
        return count > 0 ? .axError : .axAccentGreen
    }
}

// MARK: - Empty & Loading States

private extension CerberusSessionView {

    var emptyState: some View {
        AXEmptyState(
            icon: "person.2.slash",
            title: "Session Tracking Disabled",
            description: "Enable session tracking in your WAF configuration to monitor user sessions, detect account takeover attempts, and enforce per-session rate limits.",
            accentColor: .axAccentPurple
        )
    }

    var loadingSkeleton: some View {
        VStack(spacing: AXSpacing.lg) {
            skeletonHero
            skeletonGrid
            skeletonPanel
        }
    }

    var skeletonHero: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
            .fill(Color.axSurface)
            .frame(height: 88)
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xl))
    }

    var skeletonGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4),
            spacing: AXSpacing.md
        ) {
            ForEach(0..<4, id: \.self) { _ in
                skeletonStatCard
            }
        }
    }

    var skeletonStatCard: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(Color.axSurface)
            .frame(height: 120)
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    var skeletonPanel: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(Color.axSurface)
            .frame(height: 160)
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
    }

    var shimmerOverlay: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.axSurfaceHover.opacity(0.4),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
