//
//  CerberusDomainsView.swift
//  AevonX
//
//  Domain management for AXCerberus WAF.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusDomainsView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var showAddSheet = false
    @State private var newDomain = ""
    @State private var selectedDomain: WAFDomainInfo?

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                heroHeader
                if viewModel.domainOperationInProgress && viewModel.domains.isEmpty {
                    loadingSkeleton
                } else {
                    webServerSection
                    statsRow
                    domainListSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .task { await viewModel.loadDomains() }
        .sheet(isPresented: $showAddSheet) { addDomainSheet }
        .sheet(item: $selectedDomain) { domain in
            CerberusDomainDetailView(viewModel: viewModel, domain: domain)
        }
    }
}

// MARK: - Hero Header

private extension CerberusDomainsView {

    var heroHeader: some View {
        HStack(alignment: .top, spacing: AXSpacing.lg) {
            heroTitleGroup
            Spacer()
            heroActions
        }
    }

    var heroTitleGroup: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "globe.badge.chevron.backward")
                    .font(AXTypography.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.axAccentBlue, .axAccentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(L10n.Cerberus.Domains.title)
                    .font(AXTypography.headline)
                    .foregroundStyle(Color.axTextPrimary)
            }
            Text(L10n.Cerberus.Domains.subtitle)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var heroActions: some View {
        HStack(spacing: AXSpacing.sm) {
            syncButton
            addDomainButton
        }
    }

    var syncButton: some View {
        Button {
            Task { await viewModel.syncDomains() }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(AXTypography.caption)
                Text(L10n.Cerberus.Domains.sync)
                    .font(AXTypography.subheadline)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.1))
            .foregroundStyle(Color.axAccentBlue)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .strokeBorder(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.domainOperationInProgress)
    }

    var addDomainButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(AXTypography.caption)
                Text(L10n.Cerberus.Domains.addDomain)
                    .font(AXTypography.subheadline)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentGreen.opacity(0.1))
            .foregroundStyle(Color.axAccentGreen)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .strokeBorder(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Web Server Card

private extension CerberusDomainsView {

    var webServerSection: some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.lg) {
                webServerIconBox
                webServerInfo
                Spacer()
                webServerStatus
            }
            .padding(AXSpacing.lg)
        }
    }

    var webServerIconBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [.axAccentBlue.opacity(0.15), .axAccentPurple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            Image(systemName: "server.rack")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axAccentBlue)
        }
    }

    var webServerInfo: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            if let ws = viewModel.webServerInfo {
                Text(ws.type.isEmpty ? L10n.Cerberus.Domains.noWebServer : ws.type.capitalized)
                    .font(AXTypography.subheadline)
                    .foregroundStyle(Color.axTextPrimary)
                if ws.port > 0 {
                    HStack(spacing: AXSpacing.xs) {
                        Text(L10n.Field.port)
                            .font(AXTypography.caption)
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

    var webServerStatus: some View {
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

// MARK: - Stats Row

private extension CerberusDomainsView {

    var statsRow: some View {
        HStack(spacing: AXSpacing.md) {
            statCard(
                label: L10n.Cerberus.Domains.totalDomains,
                value: "\(viewModel.domains.count)",
                icon: "globe",
                color: .axAccentBlue
            )
            statCard(
                label: L10n.Cerberus.Domains.protected,
                value: "\(protectedCount)",
                icon: "checkmark.shield.fill",
                color: .axAccentGreen
            )
            statCard(
                label: L10n.Cerberus.Domains.unprotected,
                value: "\(unprotectedCount)",
                icon: "shield.slash",
                color: unprotectedCount > 0 ? .axWarning : .axTextMuted
            )
        }
    }

    var protectedCount: Int {
        viewModel.domains.filter(\.enabled).count
    }

    var unprotectedCount: Int {
        viewModel.domains.filter { !$0.enabled }.count
    }

    func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        AXGlassCard {
            VStack(spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: icon)
                        .font(AXTypography.caption)
                        .foregroundStyle(color)
                    Spacer()
                    Text(value)
                        .font(AXTypography.title2)
                        .foregroundStyle(color)
                }
                HStack {
                    Text(label)
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextTertiary)
                    Spacer()
                }
            }
            .padding(AXSpacing.md)
        }
    }
}

// MARK: - Domain List

private extension CerberusDomainsView {

    var domainListSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            domainListHeader
            if viewModel.domains.isEmpty {
                emptyState
            } else {
                domainList
            }
        }
    }

    var domainListHeader: some View {
        HStack {
            Text(L10n.Cerberus.Domains.configuredDomains)
                .font(AXTypography.subheadline)
                .foregroundStyle(Color.axTextSecondary)
            Spacer()
            if !viewModel.domains.isEmpty {
                AXBadge(
                    text: "\(viewModel.domains.count) domain\(viewModel.domains.count == 1 ? "" : "s")",
                    color: .axAccentBlue,
                    style: .soft
                )
            }
        }
    }

    var domainList: some View {
        VStack(spacing: AXSpacing.sm) {
            ForEach(viewModel.domains) { domain in
                domainRow(domain)
            }
        }
    }

    var emptyState: some View {
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

// MARK: - Domain Row

private extension CerberusDomainsView {

    func domainRow(_ domain: WAFDomainInfo) -> some View {
        Button {
            selectedDomain = domain
        } label: {
            AXCard {
                HStack(spacing: AXSpacing.md) {
                    domainShieldIcon(domain.enabled)
                    domainInfo(domain)
                    Spacer()
                    domainToggle(domain)
                    domainDeleteButton(domain)
                }
                .padding(AXSpacing.lg)
            }
        }
        .buttonStyle(.plain)
    }

    func domainShieldIcon(_ enabled: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(enabled ? Color.axAccentGreen.opacity(0.1) : Color.axTextMuted.opacity(0.08))
                .frame(width: 36, height: 36)
            Image(systemName: enabled ? "checkmark.shield.fill" : "shield.slash")
                .font(AXTypography.subheadline)
                .foregroundStyle(enabled ? Color.axAccentGreen : Color.axTextMuted)
        }
    }

    func domainInfo(_ domain: WAFDomainInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(domain.domain)
                .font(AXTypography.monoMd)
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
    }

    func domainToggle(_ domain: WAFDomainInfo) -> some View {
        Toggle("", isOn: Binding(
            get: { domain.enabled },
            set: { val in Task { await viewModel.toggleDomain(domain.domain, enabled: val) } }
        ))
        .toggleStyle(.switch)
        .labelsHidden()
        .disabled(viewModel.domainOperationInProgress)
    }

    func domainDeleteButton(_ domain: WAFDomainInfo) -> some View {
        Button {
            Task { await viewModel.removeDomain(domain.domain) }
        } label: {
            Image(systemName: "trash")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axError)
                .frame(width: 30, height: 30)
                .background(Color.axError.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .strokeBorder(Color.axError.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.domainOperationInProgress)
    }
}

// MARK: - Add Domain Sheet

private extension CerberusDomainsView {

    var addDomainSheet: some View {
        VStack(spacing: 0) {
            // Hero
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.axAccentGreen.opacity(0.2), Color.axAccentGreen.opacity(0.04)],
                                center: .center, startRadius: 0, endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
                        .frame(width: 52, height: 52)
                    Image(systemName: "globe.badge.chevron.backward")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.axAccentGreen)
                }
                Text(L10n.Cerberus.Domains.addDomainTitle)
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(L10n.Cerberus.Domains.addDomainDesc)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            .padding(.top, AXSpacing.xxl)
            .padding(.bottom, AXSpacing.lg)

            // Input
            VStack(spacing: AXSpacing.lg) {
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
            .padding(.horizontal, AXSpacing.xxl)

            Spacer()

            // Actions
            HStack(spacing: AXSpacing.md) {
                Button {
                    showAddSheet = false
                    newDomain = ""
                } label: {
                    Text(L10n.Button.cancel)
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.axTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).strokeBorder(Color.axBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                AXPrimaryButton(
                    title: L10n.Cerberus.Domains.addDomain,
                    icon: "plus.circle.fill",
                    action: {
                        let d = newDomain.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !d.isEmpty else { return }
                        Task {
                            await viewModel.addDomain(d)
                            showAddSheet = false
                            newDomain = ""
                        }
                    },
                    isDisabled: newDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    accentColor: .axAccentGreen
                )
            }
            .padding(AXSpacing.xxl)
        }
        .frame(width: 440, height: 400)
        .background(Color.axBackground)
    }
}

// MARK: - Loading Skeleton

private extension CerberusDomainsView {

    var loadingSkeleton: some View {
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
                ForEach(0..<3, id: \.self) { _ in
                    skeletonStatCard
                }
            }
            ForEach(0..<3, id: \.self) { _ in
                skeletonDomainRow
            }
        }
    }

    var skeletonStatCard: some View {
        AXGlassCard {
            VStack(spacing: AXSpacing.sm) {
                AXSkeletonBlock(lines: 1, height: 24)
                AXSkeletonBlock(lines: 1, height: 12)
            }
            .padding(AXSpacing.md)
        }
    }

    var skeletonDomainRow: some View {
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
