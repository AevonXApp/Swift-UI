//
//  CerberusDomainDetailView+Blocking.swift
//  AevonX
//
//  Per-domain IP and country blocking — inline forms, no sheets.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Blocking Tab

extension CerberusDomainDetailView {

    var blockingTab: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                blockedIPsSection
                blockedCountriesSection
            }
            .padding(AXSpacing.xl)
        }
    }
}

// MARK: - Blocked IPs

private struct DomainBlockIPSection: View {
    @ObservedObject var viewModel: CerberusViewModel
    let domainName: String
    @State private var showAddForm = false
    @State private var newIP = ""

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                ipSectionHeader
                if showAddForm { ipAddForm }
                ipListContent
            }
        }
    }

    private var ipSectionHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [Color.axError.opacity(0.12), Color.axError.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.axError)
            }
            Text(L10n.Cerberus.DomainDetail.blockedIPs)
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            AXBadge(
                text: "\(viewModel.selectedDomainBlockedIPs.count)",
                color: .axError,
                style: .soft
            )
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAddForm.toggle() }
            } label: {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: showAddForm ? "xmark" : "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text(showAddForm ? L10n.Button.cancel : L10n.Cerberus.DomainDetail.addIP)
                        .font(AXTypography.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(showAddForm ? Color.axTextMuted : Color.axError)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(showAddForm ? Color.axSurface : Color.axError.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .strokeBorder(showAddForm ? Color.axBorder.opacity(0.5) : Color.axError.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var ipAddForm: some View {
        HStack(spacing: AXSpacing.sm) {
            AXTextField(
                placeholder: L10n.Cerberus.DomainDetail.ipPlaceholder,
                text: $newIP,
                icon: "network",
                accentColor: .axError
            )
            Button {
                let ip = newIP.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !ip.isEmpty else { return }
                Task {
                    await viewModel.domainBlockIP(ip, domain: domainName)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        newIP = ""
                        showAddForm = false
                    }
                }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        newIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.axTextMuted
                            : Color.axError
                    )
            }
            .buttonStyle(.plain)
            .disabled(newIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var ipListContent: some View {
        Group {
            if viewModel.selectedDomainBlockedIPs.isEmpty {
                ipEmptyState
            } else {
                ipListRows
            }
        }
    }

    private var ipEmptyState: some View {
        VStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentGreen.opacity(0.08), Color.axAccentGreen.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Circle()
                    .strokeBorder(Color.axAccentGreen.opacity(0.1), lineWidth: 1)
                    .frame(width: 56, height: 56)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.axAccentGreen.opacity(0.4))
            }
            Text(L10n.Cerberus.DomainDetail.noBlockedIPs)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xl)
    }

    private var ipListRows: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach(viewModel.selectedDomainBlockedIPs, id: \.self) { ip in
                HStack(spacing: AXSpacing.sm) {
                    Circle()
                        .fill(Color.axError)
                        .frame(width: 5, height: 5)
                    Text(ip)
                        .font(AXTypography.monoSm)
                        .foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    Button {
                        Task { await viewModel.domainUnblockIP(ip, domain: domainName) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.axError)
                            .frame(width: 24, height: 24)
                            .background(Color.axError.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, AXSpacing.xxxs)
            }
        }
    }
}

// MARK: - Blocked Countries

private struct DomainBlockCountrySection: View {
    @ObservedObject var viewModel: CerberusViewModel
    let domainName: String
    @State private var showAddForm = false
    @State private var newCountry = ""

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                countrySectionHeader
                if showAddForm { countryAddForm }
                countryListContent
            }
        }
    }

    private var countrySectionHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [Color.axWarning.opacity(0.12), Color.axWarning.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: "globe.badge.chevron.backward")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.axWarning)
            }
            Text(L10n.Cerberus.DomainDetail.blockedCountries)
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.axTextPrimary)
            AXBadge(
                text: "\(viewModel.selectedDomainBlockedCountries.count)",
                color: .axWarning,
                style: .soft
            )
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAddForm.toggle() }
            } label: {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: showAddForm ? "xmark" : "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text(showAddForm ? L10n.Button.cancel : L10n.Cerberus.DomainDetail.addCountry)
                        .font(AXTypography.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(showAddForm ? Color.axTextMuted : Color.axWarning)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(showAddForm ? Color.axSurface : Color.axWarning.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .strokeBorder(showAddForm ? Color.axBorder.opacity(0.5) : Color.axWarning.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var countryAddForm: some View {
        HStack(spacing: AXSpacing.sm) {
            AXTextField(
                placeholder: L10n.Cerberus.DomainDetail.countryPlaceholder,
                text: $newCountry,
                icon: "globe",
                accentColor: .axWarning
            )
            Button {
                let code = newCountry.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                guard !code.isEmpty else { return }
                Task {
                    await viewModel.domainBlockCountry(code, domain: domainName)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        newCountry = ""
                        showAddForm = false
                    }
                }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        newCountry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.axTextMuted
                            : Color.axWarning
                    )
            }
            .buttonStyle(.plain)
            .disabled(newCountry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var countryListContent: some View {
        Group {
            if viewModel.selectedDomainBlockedCountries.isEmpty {
                countryEmptyState
            } else {
                countryListRows
            }
        }
    }

    private var countryEmptyState: some View {
        VStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentBlue.opacity(0.08), Color.axAccentPurple.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Circle()
                    .strokeBorder(Color.axAccentBlue.opacity(0.1), lineWidth: 1)
                    .frame(width: 56, height: 56)
                Image(systemName: "globe.americas")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axAccentBlue.opacity(0.4), Color.axAccentPurple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            Text(L10n.Cerberus.DomainDetail.noBlockedCountries)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xl)
    }

    private var countryListRows: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach(viewModel.selectedDomainBlockedCountries, id: \.self) { code in
                HStack(spacing: AXSpacing.sm) {
                    Text(flagEmoji(for: code))
                        .font(.system(size: 14))
                    Text(Locale.current.localizedString(forRegionCode: code) ?? code)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextPrimary)
                    Text(code)
                        .font(AXTypography.monoSm)
                        .foregroundStyle(Color.axTextTertiary)
                    Spacer()
                    Button {
                        Task { await viewModel.domainUnblockCountry(code, domain: domainName) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.axWarning)
                            .frame(width: 24, height: 24)
                            .background(Color.axWarning.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, AXSpacing.xxxs)
            }
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { flag.append(String(s)) }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}

// MARK: - Bridge to main view

extension CerberusDomainDetailView {

    var blockedIPsSection: some View {
        DomainBlockIPSection(viewModel: viewModel, domainName: domain.domain)
    }

    var blockedCountriesSection: some View {
        DomainBlockCountrySection(viewModel: viewModel, domainName: domain.domain)
    }
}
