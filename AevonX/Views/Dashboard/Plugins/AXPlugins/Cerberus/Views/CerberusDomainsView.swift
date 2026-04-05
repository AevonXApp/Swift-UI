//
//  CerberusDomainsView.swift
//  AevonX
//
//  Domain management for AXCerberus WAF.
//  Domain detail is shown inline (full page), not in a sheet.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusDomainsView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var showAddForm = false
    @State private var newDomain = ""
    @State private var selectedDomain: WAFDomainInfo?
    @State private var domainToDelete: String?
    @State private var hoveredDomain: String?

    var body: some View {
        if let domain = selectedDomain {
            CerberusDomainDetailView(viewModel: viewModel, domain: domain) {
                withAnimation(.easeInOut(duration: 0.25)) { selectedDomain = nil }
            }
        } else {
            domainListPage
        }
    }

    private var domainListPage: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xxl) {
                heroHeader
                if viewModel.domainOperationInProgress && viewModel.domains.isEmpty {
                    DomainLoadingSkeleton()
                } else {
                    webServerBanner
                    if showAddForm { inlineAddDomainForm }
                    globalStatsStrip
                    domainListSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .task { await viewModel.loadDomains() }
        .confirmationDialog(
            L10n.Cerberus.Dialog.deleteDomain,
            isPresented: Binding(get: { domainToDelete != nil }, set: { if !$0 { domainToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.Cerberus.Dialog.delete, role: .destructive) {
                if let domain = domainToDelete {
                    Task { await viewModel.removeDomain(domain) }
                }
            }
        }
    }
}

// MARK: - Hero Header

private extension CerberusDomainsView {

    var heroHeader: some View {
        HStack(alignment: .center, spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.axAccentBlue.opacity(0.2), .axAccentBlue.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.axAccentBlue.opacity(0.4), .axAccentBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "globe.badge.chevron.backward")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.axAccentBlue, .axAccentBlue.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Cerberus.Domains.title)
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
                Text(L10n.Cerberus.Domains.subtitle)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            Spacer()
            heroActionButtons
        }
    }

    var heroActionButtons: some View {
        HStack(spacing: AXSpacing.sm) {
            Button {
                Task { await viewModel.syncDomains() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .medium))
                    Text(L10n.Cerberus.Domains.sync)
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.axAccentBlue)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .strokeBorder(Color.axAccentBlue.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.domainOperationInProgress)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAddForm.toggle() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: showAddForm ? "xmark" : "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.Cerberus.Domains.addDomain)
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    LinearGradient(
                        colors: [.axAccentGreen, .axAccentGreen.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Web Server Banner

private extension CerberusDomainsView {

    var webServerBanner: some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [.axAccentBlue.opacity(0.15), .axAccentBlue.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "server.rack")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.axAccentBlue)
                }
                webServerInfoText
                Spacer()
                webServerStatusBadge
            }
            .padding(AXSpacing.lg)
        }
    }

    var webServerInfoText: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            if let ws = viewModel.webServerInfo {
                Text(ws.type.isEmpty ? L10n.Cerberus.Domains.noWebServer : ws.type.capitalized)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextPrimary)
                if ws.port > 0 {
                    HStack(spacing: AXSpacing.xs) {
                        Text(L10n.Field.port)
                            .font(AXTypography.caption2)
                            .foregroundStyle(Color.axTextTertiary)
                        Text("\(ws.port)")
                            .font(AXTypography.monoSm)
                            .foregroundStyle(Color.axAccentBlue)
                    }
                }
            } else {
                Text(L10n.Cerberus.Domains.detectingServer)
                    .font(AXTypography.subheadline)
                    .foregroundStyle(Color.axTextMuted)
            }
        }
    }

    var webServerStatusBadge: some View {
        Group {
            if let ws = viewModel.webServerInfo {
                AXStatusBadge(
                    status: ws.isActive ? .online : .offline,
                    showLabel: true,
                    size: 8,
                    enablePulseAnimation: ws.isActive
                )
            }
        }
    }
}

// MARK: - Inline Add Domain Form

private extension CerberusDomainsView {

    var inlineAddDomainForm: some View {
        AXCard(accentColor: .axAccentGreen) {
            VStack(spacing: AXSpacing.md) {
                addFormHeader
                addFormInput
                addFormHint
                addFormActions
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    var addFormHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "globe.badge.chevron.backward")
                .font(AXTypography.subheadline)
                .foregroundStyle(Color.axAccentGreen)
            Text(L10n.Cerberus.Domains.addDomainTitle)
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
        }
    }

    var addFormInput: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Cerberus.Domains.domainName)
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextSecondary)
            AXTextField(
                placeholder: L10n.Cerberus.Domains.domainPlaceholder,
                text: $newDomain,
                icon: "globe",
                accentColor: .axAccentGreen
            )
        }
    }

    var addFormHint: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.axAccentGreen.opacity(0.6))
            Text(L10n.Cerberus.Domains.domainHint)
                .font(AXTypography.caption2)
                .foregroundStyle(Color.axTextMuted)
        }
        .padding(AXSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axAccentGreen.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
    }

    var addFormActions: some View {
        let trimmed = newDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(spacing: AXSpacing.sm) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showAddForm = false
                    newDomain = ""
                }
            } label: {
                Text(L10n.Button.cancel)
                    .font(AXTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).strokeBorder(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                guard !trimmed.isEmpty else { return }
                Task {
                    await viewModel.addDomain(trimmed)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAddForm = false
                        newDomain = ""
                    }
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10))
                    Text(L10n.Cerberus.Domains.addDomain)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(trimmed.isEmpty ? Color.axTextMuted : .white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.xs)
                .background(trimmed.isEmpty ? Color.axSurface : Color.axAccentGreen)
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            }
            .buttonStyle(.plain)
            .disabled(trimmed.isEmpty)
            Spacer()
        }
    }
}

// MARK: - Global Stats Strip

private extension CerberusDomainsView {

    var globalStatsStrip: some View {
        HStack(spacing: AXSpacing.md) {
            DomainMiniStat(
                icon: "globe",
                value: "\(viewModel.domains.count)",
                label: L10n.Cerberus.Domains.totalDomains,
                color: .axAccentBlue
            )
            DomainMiniStat(
                icon: "checkmark.shield.fill",
                value: "\(viewModel.domains.filter(\.enabled).count)",
                label: L10n.Cerberus.Domains.protected,
                color: .axAccentGreen
            )
            DomainMiniStat(
                icon: "shield.slash",
                value: "\(viewModel.domains.filter { !$0.enabled }.count)",
                label: L10n.Cerberus.Domains.unprotected,
                color: viewModel.domains.contains(where: { !$0.enabled }) ? .axWarning : .axTextMuted
            )
            DomainMiniStat(
                icon: "chart.bar.fill",
                value: DomainFormatHelper.formatNumber(totalRequests),
                label: L10n.Cerberus.Domains.requests,
                color: .axAccentBlue
            )
        }
    }

    var totalRequests: Int {
        viewModel.domainStats.values.reduce(0) { $0 + $1.totalRequests }
    }
}

// MARK: - Domain List

private extension CerberusDomainsView {

    var domainListSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            domainListHeader
            if viewModel.domains.isEmpty {
                domainEmptyState
            } else {
                domainGrid
            }
        }
    }

    var domainListHeader: some View {
        HStack {
            Text(L10n.Cerberus.Domains.configuredDomains)
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.axTextSecondary)
            Spacer()
            if !viewModel.domains.isEmpty {
                AXBadge(
                    text: L10n.Cerberus.Badge.domains(viewModel.domains.count),
                    color: .axAccentBlue,
                    style: .soft
                )
            }
        }
    }

    var domainGrid: some View {
        VStack(spacing: AXSpacing.md) {
            ForEach(viewModel.domains) { domain in
                DomainCard(
                    domain: domain,
                    stats: viewModel.domainStats[domain.domain],
                    isHovered: hoveredDomain == domain.domain,
                    operationInProgress: viewModel.domainOperationInProgress,
                    onSelect: {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedDomain = domain }
                    },
                    onToggle: { val in
                        Task { await viewModel.toggleDomain(domain.domain, enabled: val) }
                    },
                    onDelete: { domainToDelete = domain.domain },
                    onHover: { hoveredDomain = $0 ? domain.domain : nil }
                )
            }
        }
    }

    var domainEmptyState: some View {
        AXGlassCard {
            AXEmptyState(
                icon: "globe",
                title: L10n.Cerberus.Domains.noDomains,
                description: L10n.Cerberus.Domains.noDomainsDesc,
                actionLabel: L10n.Cerberus.Domains.syncDomains,
                action: { Task { await viewModel.syncDomains() } },
                accentColor: .axAccentBlue
            )
            .padding(AXSpacing.xxl)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Mini Stat Card

private struct DomainMiniStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: AXSpacing.sm) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(color)
            }
            HStack {
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundStyle(Color.axTextTertiary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.04), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .strokeBorder(color.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Domain Card

private struct DomainCard: View {
    let domain: WAFDomainInfo
    let stats: DomainStats?
    let isHovered: Bool
    let operationInProgress: Bool
    let onSelect: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    private var total: Int { stats?.totalRequests ?? 0 }
    private var blocked: Int { stats?.blockedRequests ?? 0 }
    private var blockRate: Double { total > 0 ? Double(blocked) / Double(total) * 100 : 0 }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Gradient left accent bar
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: domain.enabled
                                ? [.axAccentGreen, .axAccentBlue]
                                : [.axTextMuted.opacity(0.4), .axTextMuted.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .padding(.vertical, AXSpacing.sm)

                VStack(spacing: 0) {
                    cardHeader
                    cardDivider
                    cardStats
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        domain.enabled ? Color.axAccentGreen.opacity(0.02) : Color.clear,
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .strokeBorder(
                                isHovered ? Color.axAccentBlue.opacity(0.35) : Color.axBorder.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.lg))
            .shadow(
                color: isHovered ? Color.axAccentBlue.opacity(0.12) : Color.black.opacity(0.04),
                radius: isHovered ? 12 : 4,
                y: isHovered ? 4 : 2
            )
        }
        .buttonStyle(.plain)
        .onHover { onHover($0) }
        .animation(.easeOut(duration: 0.2), value: isHovered)
    }

    private var cardHeader: some View {
        HStack(spacing: AXSpacing.md) {
            shieldIcon
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(domain.domain)
                    .font(AXTypography.monoMd)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextPrimary)
                HStack(spacing: AXSpacing.xs) {
                    Text(domain.webServer.isEmpty ? L10n.Cerberus.Domains.unknownServer : domain.webServer)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextTertiary)
                    if domain.enabled {
                        AXBadge(text: L10n.Status.active, color: .axAccentGreen, style: .soft)
                    }
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { domain.enabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .disabled(operationInProgress)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.axError)
                    .frame(width: 28, height: 28)
                    .background(Color.axError.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(operationInProgress)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        domain.enabled ? Color.axAccentGreen.opacity(0.3) : Color.axTextMuted.opacity(0.15),
                        domain.enabled ? Color.axAccentBlue.opacity(0.2) : Color.axTextMuted.opacity(0.05),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private var cardStats: some View {
        HStack(spacing: 0) {
            statCell(
                icon: "chart.bar.fill",
                value: DomainFormatHelper.formatNumber(total),
                label: L10n.Cerberus.Domains.requests,
                color: .axAccentBlue
            )
            statDivider
            statCell(
                icon: "hand.raised.fill",
                value: DomainFormatHelper.formatNumber(blocked),
                label: L10n.Cerberus.Domains.blocked,
                color: .axError
            )
            statDivider
            statCell(
                icon: "shield.lefthalf.filled",
                value: String(format: "%.1f%%", blockRate),
                label: L10n.Cerberus.Domains.blockRate,
                color: blockRate > 10 ? .axWarning : .axAccentGreen
            )
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.axTextMuted.opacity(0.5))
                .padding(.trailing, AXSpacing.lg)
        }
        .padding(.vertical, AXSpacing.md)
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.08))
                    .frame(width: 24, height: 24)
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AXTypography.monoSm)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.axTextTertiary)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.axBorder.opacity(0.3))
            .frame(width: 1, height: 28)
    }

    private var shieldIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: domain.enabled
                            ? [Color.axAccentGreen.opacity(0.15), Color.axAccentGreen.opacity(0.05)]
                            : [Color.axTextMuted.opacity(0.1), Color.axTextMuted.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)
            Image(systemName: domain.enabled ? "checkmark.shield.fill" : "shield.slash")
                .font(.system(size: 16))
                .foregroundStyle(domain.enabled ? Color.axAccentGreen : Color.axTextMuted)
        }
    }
}

// MARK: - Loading Skeleton

private struct DomainLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            AXGlassCard {
                HStack(spacing: AXSpacing.lg) {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axSurface)
                        .frame(width: 44, height: 44)
                        .shimmer()
                    AXSkeletonBlock(lines: 2, height: 14)
                    Spacer()
                }
                .padding(AXSpacing.lg)
            }
            HStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    AXGlassCard {
                        VStack(spacing: AXSpacing.sm) {
                            AXSkeletonBlock(lines: 1, height: 24)
                            AXSkeletonBlock(lines: 1, height: 12)
                        }
                        .padding(AXSpacing.md)
                    }
                }
            }
            ForEach(0..<3, id: \.self) { _ in
                AXCard {
                    HStack(spacing: AXSpacing.md) {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axSurface)
                            .frame(width: 36, height: 36)
                            .shimmer()
                        AXSkeletonBlock(lines: 2, height: 14)
                        Spacer()
                    }
                    .padding(AXSpacing.lg)
                }
            }
        }
    }
}

// MARK: - Format Helper

enum DomainFormatHelper {
    static func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }
}
