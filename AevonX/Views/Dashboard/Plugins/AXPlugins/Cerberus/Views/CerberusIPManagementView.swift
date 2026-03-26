//
//  CerberusIPManagementView.swift
//  AevonX
//
//  IP Guard tab — blocklist, allowlist, GeoIP country blocking.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusIPManagementView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var newBlockIP = ""
    @State private var newAllowIP = ""
    @State private var newBlockCountry = ""
    @State private var searchQuery = ""
    @State private var showAddBlockSheet = false
    @State private var showAddAllowSheet = false
    @State private var showAddCountrySheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                if viewModel.isLoading && viewModel.blockedIPs.isEmpty && viewModel.allowedIPs.isEmpty {
                    ipSkeletonContent
                } else {
                    ipHeroSection
                    searchBar
                    HStack(alignment: .top, spacing: AXSpacing.lg) {
                        blocklistSection
                        allowlistSection
                    }
                    geoIPSection
                }
            }
            .padding(AXSpacing.xl)
        }
        .task {
            async let ips: () = viewModel.loadIPLists()
            async let geo: () = viewModel.loadGeoIP()
            _ = await (ips, geo)
        }
        .sheet(isPresented: $showAddBlockSheet) { addIPSheet(isBlock: true) }
        .sheet(isPresented: $showAddAllowSheet) { addIPSheet(isBlock: false) }
        .sheet(isPresented: $showAddCountrySheet) { addCountrySheet }
    }
}

// MARK: - Skeleton

private extension CerberusIPManagementView {

    var ipSkeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            AXCard { AXSkeletonBlock(lines: 2) }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                AXCard { AXSkeletonBlock(lines: 5) }
                AXCard { AXSkeletonBlock(lines: 5) }
            }
        }
    }
}

// MARK: - Hero Section

private extension CerberusIPManagementView {

    var ipHeroSection: some View {
        AXGlassCard(accentColor: .axAccentPurple) {
            HStack(spacing: AXSpacing.xxl) {
                ipHeroIcon
                ipHeroTitle
                Spacer()
                ipHeroStats
            }
        }
    }

    var ipHeroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentPurple.opacity(0.2), Color.axAccentPurple.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 26
                    )
                )
                .frame(width: 48, height: 48)
            Circle()
                .stroke(Color.axAccentPurple.opacity(0.25), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: "network.badge.shield.half.filled")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axAccentPurple)
        }
    }

    var ipHeroTitle: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text("IP Guard")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text("Manage blocklists, allowlists, and geo-restrictions")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var ipHeroStats: some View {
        HStack(spacing: AXSpacing.xxl) {
            heroStat(icon: "hand.raised.fill", value: "\(viewModel.blockedIPs.count)", label: "Blocked", color: .axError)
            Divider().frame(height: 36)
            heroStat(icon: "checkmark.shield.fill", value: "\(viewModel.allowedIPs.count)", label: "Allowed", color: .axAccentGreen)
            Divider().frame(height: 36)
            heroStat(icon: "globe.badge.chevron.backward", value: "\(viewModel.blockedCountries.count)", label: "Countries", color: .axAccentPurple)
            Divider().frame(height: 36)
            heroStat(icon: "shield.checkered", value: "\(totalRules)", label: "Total Rules", color: .axAccentBlue)
        }
    }

    func heroStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(AXTypography.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }
}

// MARK: - Search

private extension CerberusIPManagementView {

    var searchBar: some View {
        AXTextField(placeholder: "Search IPs...", text: $searchQuery, icon: "magnifyingglass")
    }
}

// MARK: - Blocklist

private extension CerberusIPManagementView {

    var blocklistSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                blocklistHeader
                if filteredBlockedIPs.isEmpty {
                    ipEmptyState(text: "No blocked IPs", icon: "hand.raised.slash")
                } else {
                    blocklistContent
                }
            }
        }
    }

    var blocklistHeader: some View {
        HStack {
            Image(systemName: "hand.raised.fill").foregroundStyle(Color.axError)
            Text("Blocked IPs").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(filteredBlockedIPs.count)", color: .axError, style: .soft)
            addBtn(color: .axError) { showAddBlockSheet = true }
        }
    }

    var blocklistContent: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(filteredBlockedIPs, id: \.self) { ip in
                ipRow(ip: ip, isBlock: true)
            }
        }
    }
}

// MARK: - Allowlist

private extension CerberusIPManagementView {

    var allowlistSection: some View {
        AXCard(accentColor: .axAccentGreen) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                allowlistHeader
                if filteredAllowedIPs.isEmpty {
                    ipEmptyState(text: "No allowed IPs", icon: "checkmark.shield")
                } else {
                    allowlistContent
                }
            }
        }
    }

    var allowlistHeader: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(Color.axAccentGreen)
            Text("Allowed IPs").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(filteredAllowedIPs.count)", color: .axAccentGreen, style: .soft)
            addBtn(color: .axAccentGreen) { showAddAllowSheet = true }
        }
    }

    var allowlistContent: some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(filteredAllowedIPs, id: \.self) { ip in
                ipRow(ip: ip, isBlock: false)
            }
        }
    }
}

// MARK: - IP Row

private extension CerberusIPManagementView {

    func ipRow(ip: String, isBlock: Bool) -> some View {
        let accent: Color = isBlock ? .axError : .axAccentGreen
        return HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(accent.opacity(0.4))
                .frame(width: 6, height: 6)
            Text(ip)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            Button {
                Task {
                    if isBlock { await viewModel.unblockIP(ip) }
                    else { await viewModel.removeAllowedIP(ip) }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.axTextTertiary)
                    .frame(width: 24, height: 24)
                    .background(Color.axError.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.ipOperationInProgress)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.5)))
    }

    func addBtn(color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    func ipEmptyState(text: String, icon: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(AXTypography.title3)
                    .foregroundStyle(Color.axTextMuted)
                Text(text)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
            .padding(.vertical, AXSpacing.xl)
            Spacer()
        }
    }
}

// MARK: - GeoIP Section

private extension CerberusIPManagementView {

    var geoIPSection: some View {
        AXCard(accentColor: .axAccentPurple) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                geoIPHeader
                Text("Block all traffic from specific countries via MaxMind GeoLite2.")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                if viewModel.blockedCountries.isEmpty {
                    ipEmptyState(text: "No countries blocked", icon: "globe")
                } else {
                    countryGrid
                }
            }
        }
    }

    var geoIPHeader: some View {
        HStack {
            Image(systemName: "globe.badge.chevron.backward").foregroundStyle(Color.axAccentPurple)
            Text("Country Blocking (GeoIP)").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(viewModel.blockedCountries.count)", color: .axAccentPurple, style: .soft)
            addBtn(color: .axAccentPurple) { showAddCountrySheet = true }
        }
    }

    var countryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AXSpacing.xs) {
            ForEach(viewModel.blockedCountries, id: \.self) { code in
                countryChip(code)
            }
        }
    }

    func countryChip(_ code: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Text(flagEmoji(for: code))
            Text(code)
                .font(AXTypography.monoSm)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            Button {
                Task { await viewModel.unblockCountry(code) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.geoIPOperationInProgress)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentPurple.opacity(0.06)))
    }
}

// MARK: - Add IP Sheet

private extension CerberusIPManagementView {

    func addIPSheet(isBlock: Bool) -> some View {
        let accent: Color = isBlock ? .axError : .axAccentGreen
        let iconName = isBlock ? "hand.raised.fill" : "checkmark.shield.fill"
        return VStack(spacing: 0) {
            // Hero header
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accent.opacity(0.2), accent.opacity(0.04)],
                                center: .center, startRadius: 0, endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                        .frame(width: 52, height: 52)
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accent)
                }
                Text(isBlock ? "Block IP Address" : "Allow IP Address")
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text(isBlock ? "Add an IP or CIDR range to the blocklist" : "Whitelist a trusted IP or CIDR range")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            .padding(.top, AXSpacing.xxl)
            .padding(.bottom, AXSpacing.lg)

            // Input section
            VStack(spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("IP Address / CIDR")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextSecondary)
                    AXTextField(
                        placeholder: "e.g. 203.0.113.42 or 10.0.0.0/24",
                        text: isBlock ? $newBlockIP : $newAllowIP,
                        icon: "network",
                        accentColor: accent,
                        validation: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    )
                }

                // Hint
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(accent.opacity(0.6))
                    Text("Supports IPv4, IPv6 and CIDR notation")
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accent.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .padding(.horizontal, AXSpacing.xxl)

            Spacer()

            // Actions
            HStack(spacing: AXSpacing.md) {
                Button {
                    if isBlock { showAddBlockSheet = false } else { showAddAllowSheet = false }
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
                    title: isBlock ? "Block IP" : "Allow IP",
                    icon: iconName,
                    action: {
                        Task {
                            if isBlock {
                                await viewModel.blockIP(newBlockIP); newBlockIP = ""; showAddBlockSheet = false
                            } else {
                                await viewModel.allowIP(newAllowIP); newAllowIP = ""; showAddAllowSheet = false
                            }
                        }
                    },
                    isLoading: viewModel.ipOperationInProgress,
                    isDisabled: (isBlock ? newBlockIP : newAllowIP).trimmingCharacters(in: .whitespaces).isEmpty,
                    style: isBlock ? .destructive : .primary,
                    accentColor: accent
                )
            }
            .padding(AXSpacing.xxl)
        }
        .frame(width: 440, height: 380)
        .background(Color.axBackground)
    }
}

// MARK: - Add Country Sheet

private extension CerberusIPManagementView {

    var addCountrySheet: some View {
        VStack(spacing: 0) {
            // Hero header
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.axAccentPurple.opacity(0.2), Color.axAccentPurple.opacity(0.04)],
                                center: .center, startRadius: 0, endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(Color.axAccentPurple.opacity(0.2), lineWidth: 1)
                        .frame(width: 52, height: 52)
                    Image(systemName: "globe.badge.chevron.backward")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.axAccentPurple)
                }
                Text("Block Country")
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                Text("Block all traffic from a specific country via GeoIP")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            .padding(.top, AXSpacing.xxl)
            .padding(.bottom, AXSpacing.lg)

            // Input
            VStack(spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Country Code")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.axTextSecondary)
                    AXTextField(
                        placeholder: "e.g. CN, RU, KP",
                        text: $newBlockCountry,
                        icon: "globe",
                        accentColor: .axAccentPurple,
                        validation: { $0.trimmingCharacters(in: .whitespaces).count == 2 }
                    )
                }

                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.axAccentPurple.opacity(0.6))
                    Text("ISO 3166-1 alpha-2 code (2 letters)")
                        .font(AXTypography.caption2)
                        .foregroundStyle(Color.axTextMuted)
                }
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axAccentPurple.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            }
            .padding(.horizontal, AXSpacing.xxl)

            Spacer()

            // Actions
            HStack(spacing: AXSpacing.md) {
                Button {
                    showAddCountrySheet = false
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
                    title: "Block Country",
                    icon: "globe.badge.chevron.backward",
                    action: {
                        Task {
                            let code = newBlockCountry.trimmingCharacters(in: .whitespaces).uppercased()
                            await viewModel.blockCountry(code); newBlockCountry = ""; showAddCountrySheet = false
                        }
                    },
                    isLoading: viewModel.geoIPOperationInProgress,
                    isDisabled: newBlockCountry.trimmingCharacters(in: .whitespaces).count != 2,
                    style: .destructive,
                    accentColor: .axAccentPurple
                )
            }
            .padding(AXSpacing.xxl)
        }
        .frame(width: 440, height: 380)
        .background(Color.axBackground)
    }
}

// MARK: - Helpers

private extension CerberusIPManagementView {

    var totalRules: Int {
        viewModel.blockedIPs.count + viewModel.blockedCountries.count
    }

    var filteredBlockedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.blockedIPs }
        return viewModel.blockedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    var filteredAllowedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.allowedIPs }
        return viewModel.allowedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { flag.append(String(s)) }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}
