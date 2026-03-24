//
//  CerberusIPManagementView.swift
//  AevonX
//
//  IP Guard tab — blocklist/allowlist/GeoIP with summary header.
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
                    ipSummaryHeader
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

    private var ipSkeletonContent: some View {
        VStack(spacing: AXSpacing.md) {
            AXCard { AXSkeletonBlock(lines: 2) }
            HStack(alignment: .top, spacing: AXSpacing.lg) {
                AXCard { AXSkeletonBlock(lines: 5) }
                AXCard { AXSkeletonBlock(lines: 5) }
            }
        }
    }

    // MARK: - Summary Header

    private var ipSummaryHeader: some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.xxxl) {
                ipSummaryStat(icon: "hand.raised.fill", value: "\(viewModel.blockedIPs.count)", label: "Blocked IPs", color: .axError)
                Divider().frame(height: 40)
                ipSummaryStat(icon: "checkmark.shield.fill", value: "\(viewModel.allowedIPs.count)", label: "Allowed IPs", color: .axAccentGreen)
                Divider().frame(height: 40)
                ipSummaryStat(icon: "globe.badge.chevron.backward", value: "\(viewModel.blockedCountries.count)", label: "Blocked Countries", color: .axAccentPurple)
                Divider().frame(height: 40)
                ipSummaryStat(icon: "shield.checkered", value: "\(viewModel.blockedIPs.count + viewModel.blockedCountries.count)", label: "Total Rules", color: .axAccentBlue)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func ipSummaryStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(AXTypography.headline)
                .foregroundStyle(color)
            Text(value)
                .font(AXTypography.title3)
                .foregroundStyle(Color.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        AXTextField(placeholder: "Search IPs...", text: $searchQuery, icon: "magnifyingglass")
    }

    // MARK: - Blocklist

    private var blocklistSection: some View {
        AXCard(accentColor: .axError) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Color.axError)
                    Text("Blocked IPs").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    AXBadge(text: "\(filteredBlockedIPs.count)", color: .axError, style: .soft)
                    Button { showAddBlockSheet = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.axError)
                    }.buttonStyle(.plain)
                }
                if filteredBlockedIPs.isEmpty {
                    ipEmptyState(text: "No blocked IPs")
                } else {
                    ipList(ips: filteredBlockedIPs, isBlock: true)
                }
            }
        }
    }

    // MARK: - Allowlist

    private var allowlistSection: some View {
        AXCard(accentColor: .axAccentGreen) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "checkmark.shield.fill").foregroundStyle(Color.axAccentGreen)
                    Text("Allowed IPs").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
                    Spacer()
                    AXBadge(text: "\(filteredAllowedIPs.count)", color: .axAccentGreen, style: .soft)
                    Button { showAddAllowSheet = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.axAccentGreen)
                    }.buttonStyle(.plain)
                }
                if filteredAllowedIPs.isEmpty {
                    ipEmptyState(text: "No allowed IPs")
                } else {
                    ipList(ips: filteredAllowedIPs, isBlock: false)
                }
            }
        }
    }

    // MARK: - IP List

    private func ipList(ips: [String], isBlock: Bool) -> some View {
        VStack(spacing: AXSpacing.xxs) {
            ForEach(ips, id: \.self) { ip in
                ipRow(ip: ip, isBlock: isBlock)
            }
        }
    }

    private func ipRow(ip: String, isBlock: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(isBlock ? Color.axError.opacity(0.3) : Color.axAccentGreen.opacity(0.3))
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
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.ipOperationInProgress)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axSurfaceHover.opacity(0.5)))
    }

    // MARK: - GeoIP Section

    private var geoIPSection: some View {
        AXCard(accentColor: .axAccentPurple) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                geoIPHeader
                Text("Block all traffic from specific countries via MaxMind GeoLite2.")
                    .font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
                if viewModel.blockedCountries.isEmpty {
                    ipEmptyState(text: "No countries blocked")
                } else {
                    countryGrid
                }
            }
        }
    }

    private var geoIPHeader: some View {
        HStack {
            Image(systemName: "globe.badge.chevron.backward").foregroundStyle(Color.axAccentPurple)
            Text("Country Blocking (GeoIP)").font(AXTypography.headline).foregroundStyle(Color.axTextPrimary)
            Spacer()
            AXBadge(text: "\(viewModel.blockedCountries.count)", color: .axAccentPurple, style: .soft)
            Button { showAddCountrySheet = true } label: {
                Image(systemName: "plus.circle.fill").foregroundStyle(Color.axAccentPurple)
            }.buttonStyle(.plain)
        }
    }

    private var countryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AXSpacing.xs) {
            ForEach(viewModel.blockedCountries, id: \.self) { code in
                countryChip(code)
            }
        }
    }

    private func countryChip(_ code: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Text(flagEmoji(for: code))
            Text(code).font(AXTypography.monoSm).foregroundStyle(Color.axTextPrimary)
            Spacer()
            Button { Task { await viewModel.unblockCountry(code) } } label: {
                Image(systemName: "xmark").font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.geoIPOperationInProgress)
        }
        .padding(.vertical, AXSpacing.xs)
        .padding(.horizontal, AXSpacing.sm)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentPurple.opacity(0.06)))
    }

    // MARK: - Add IP Sheet

    private func addIPSheet(isBlock: Bool) -> some View {
        VStack(spacing: AXSpacing.lg) {
            HStack {
                Text(isBlock ? "Block IP" : "Allow IP").font(AXTypography.title3).foregroundStyle(Color.axTextPrimary)
                Spacer()
                Button {
                    if isBlock { showAddBlockSheet = false } else { showAddAllowSheet = false }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.axTextTertiary)
                }.buttonStyle(.plain)
            }
            AXTextField(
                placeholder: "e.g. 203.0.113.42 or 10.0.0.0/24",
                text: isBlock ? $newBlockIP : $newAllowIP,
                icon: "network",
                accentColor: isBlock ? .axError : .axAccentGreen,
                validation: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            AXPrimaryButton(
                title: isBlock ? "Block" : "Allow",
                icon: isBlock ? "hand.raised.fill" : "checkmark.shield.fill",
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
                accentColor: isBlock ? .axError : .axAccentGreen
            )
            Spacer()
        }
        .padding(AXSpacing.xl).frame(width: 380, height: 240).background(Color.axBackground)
    }

    // MARK: - Add Country Sheet

    private var addCountrySheet: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack {
                Text("Block Country").font(AXTypography.title3).foregroundStyle(Color.axTextPrimary)
                Spacer()
                Button { showAddCountrySheet = false } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.axTextTertiary)
                }.buttonStyle(.plain)
            }
            AXTextField(
                placeholder: "e.g. CN, RU, KP",
                text: $newBlockCountry,
                icon: "globe",
                accentColor: .axAccentPurple,
                validation: { $0.trimmingCharacters(in: .whitespaces).count == 2 }
            )
            Text("Enter an ISO 3166-1 alpha-2 country code (2 letters).")
                .font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
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
            Spacer()
        }
        .padding(AXSpacing.xl).frame(width: 380, height: 260).background(Color.axBackground)
    }

    // MARK: - Helpers

    private var filteredBlockedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.blockedIPs }
        return viewModel.blockedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    private var filteredAllowedIPs: [String] {
        guard !searchQuery.isEmpty else { return viewModel.allowedIPs }
        return viewModel.allowedIPs.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    private func ipEmptyState(text: String) -> some View {
        HStack {
            Spacer()
            Text(text).font(AXTypography.caption).foregroundStyle(Color.axTextMuted).padding(.vertical, AXSpacing.xl)
            Spacer()
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
