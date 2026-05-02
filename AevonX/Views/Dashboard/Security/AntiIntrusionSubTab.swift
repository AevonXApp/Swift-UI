//
//  AntiIntrusionSubTab.swift
//  AevonX
//
//  Intrusion detection overview — real data from server
//

import SwiftUI
import AevonXCoreBridge

// MARK: - View

struct AntiIntrusionSubTab: View {
    let serverId: String

    @State private var isLoading = true
    @State private var fail2banActive = false
    @State private var jailList: [String] = []
    @State private var jailDetails: [(jail: String, currentlyBanned: Int, totalBanned: Int, bannedIPs: [String])] = []
    @State private var isInstalling = false
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                headerCard

                if isLoading {
                    loadingView
                } else if !fail2banActive {
                    notActiveView
                } else {
                    statsRow
                    jailsCard
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadData() }
    }

    // MARK: - Load Data

    private func loadData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        // Check fail2ban overall status (from Core)
        let installed = await securityManager.fail2banStatus(serverId: serverId)
        await MainActor.run { fail2banActive = installed }

        guard fail2banActive else { return }

        // Get jail list (from Core)
        let jails = await securityManager.fail2banJailList(serverId: serverId)
        await MainActor.run { jailList = jails }

        // Get details for each jail
        var details: [(jail: String, currentlyBanned: Int, totalBanned: Int, bannedIPs: [String])] = []
        for jail in jailList {
            let status = await securityManager.fail2banJailStatus(jail: jail, serverId: serverId)
            guard status != "not-found" else { continue }

            var current = 0
            var total = 0
            var ips: [String] = []

            for line in status.components(separatedBy: "\n") {
                let l = line.trimmingCharacters(in: .whitespaces)
                if l.contains("Currently banned") {
                    current = Int(l.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
                }
                if l.contains("Total banned") {
                    total = Int(l.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
                }
                if l.contains("Banned IP list") {
                    let ipParts = l.components(separatedBy: ":")
                    if ipParts.count >= 2 {
                        ips = ipParts.dropFirst().joined(separator: ":")
                            .trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: " ")
                            .filter { !$0.isEmpty }
                    }
                }
            }
            details.append((jail: jail, currentlyBanned: current, totalBanned: total, bannedIPs: ips))
        }
        await MainActor.run {
            jailDetails = details
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        AXCard {
            HStack {
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(fail2banActive ? Color.axError.opacity(0.15) : Color.axTextMuted.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 18))
                            .foregroundColor(fail2banActive ? .axError : .axTextMuted)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text(L10n.Security.intrusionDetectionPrevention)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("fail2ban jail monitoring and banned IP management")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                AXRefreshButton(isLoading: isLoading) {
                    await loadData()
                }
            }
        }
    }

    private var loadingView: some View {
        AXLoadingState(message: "Loading intrusion detection status…")
    }

    private var notActiveView: some View {
        AXCard {
            VStack(spacing: AXSpacing.lg) {
                Image(systemName: "shield.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.axWarning)
                Text("fail2ban is not installed")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Security.installFail2banToEnableIntrusionDetectionAndAutomaticIpBanning)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextMuted)
                    .multilineTextAlignment(.center)

                Button(action: {
                    Task {
                        isInstalling = true
                        let _ = await securityManager.installFail2ban(serverId: serverId)
                        isInstalling = false
                        await loadData()
                    }
                }) {
                    HStack(spacing: AXSpacing.sm) {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                        }
                        Text(isInstalling ? "Installing…" : "Install fail2ban")
                            .font(AXTypography.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xxl)
                    .padding(.vertical, AXSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(isInstalling ? Color.axTextMuted : Color.axAccentBlue)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isInstalling)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xl)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: AXSpacing.lg) {
            let totalCurrent = jailDetails.reduce(0) { $0 + $1.currentlyBanned }
            let totalAllTime = jailDetails.reduce(0) { $0 + $1.totalBanned }
            let totalIPs = jailDetails.reduce(0) { $0 + $1.bannedIPs.count }

            AXStatCard(icon: "shield.fill", label: "Active Jails", value: "\(jailList.count)", color: .axAccentBlue)
            AXStatCard(icon: "hand.raised.fill", label: "Currently Banned", value: "\(totalCurrent)", color: .axError)
            AXStatCard(icon: "chart.line.uptrend.xyaxis", label: "Total Banned", value: "\(totalAllTime)", color: .axWarning)
            AXStatCard(icon: "network.badge.shield.half.filled", label: "Unique IPs", value: "\(totalIPs)", color: .axAccentGreen)
        }
    }

    // MARK: - Jails

    private func filteredIPs(_ ips: [String]) -> [String] {
        if searchText.isEmpty { return ips }
        return ips.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var jailsCard: some View {
        VStack(spacing: AXSpacing.xl) {
            // Search bar
            AXSearchBar(text: $searchText, placeholder: "Search banned IPs…")

            ForEach(jailDetails, id: \.jail) { detail in
                let filtered = filteredIPs(detail.bannedIPs)

                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        // Jail header
                        HStack {
                            AXSectionTitle(title: "Jail: \(detail.jail)", icon: "lock.shield.fill")

                            Spacer()

                            HStack(spacing: AXSpacing.lg) {
                                HStack(spacing: AXSpacing.xs) {
                                    Text(L10n.Security.currently)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                    Text("\(detail.currentlyBanned)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.axError)
                                }
                                HStack(spacing: AXSpacing.xs) {
                                    Text(L10n.Security.total)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                    Text("\(detail.totalBanned)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.axWarning)
                                }
                            }
                        }
                        .padding(AXSpacing.lg)

                        Divider().background(Color.axBorder)

                        if detail.bannedIPs.isEmpty {
                            AXPlaceholder(
                                icon: "checkmark.circle.fill",
                                title: "No IPs currently banned in this jail",
                                iconColor: .axSuccess,
                                iconSize: 20
                            )
                        } else if filtered.isEmpty {
                            AXPlaceholder(
                                icon: "magnifyingglass",
                                title: "No IPs match \"\(searchText)\""
                            )
                        } else {
                            // Status bar
                            if !searchText.isEmpty {
                                HStack {
                                    Text("Showing \(filtered.count) of \(detail.bannedIPs.count)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.axTextMuted)
                                    Spacer()
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.xs)
                                .background(Color.axBackgroundTertiary.opacity(0.3))
                            }

                            // Table header
                            HStack(spacing: 0) {
                                Text(L10n.Security.ipAddress).frame(maxWidth: .infinity, alignment: .leading)
                                Text(L10n.Security.action).frame(width: 120, alignment: .center)
                            }
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axBackgroundTertiary.opacity(0.5))

                            ForEach(Array(filtered.enumerated()), id: \.element) { index, ip in
                                HStack(spacing: 0) {
                                    HStack(spacing: AXSpacing.sm) {
                                        Circle()
                                            .fill(Color.axError)
                                            .frame(width: 6, height: 6)
                                        Text(ip)
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(.axError)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Button(action: {
                                        Task {
                                            let _ = await securityManager.fail2banUnban(ip: ip, jail: detail.jail, serverId: serverId)
                                            await loadData()
                                        }
                                    }) {
                                        HStack(spacing: AXSpacing.xxs) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 10))
                                            Text(L10n.Button.remove)
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .foregroundColor(.axError)
                                        .padding(.horizontal, AXSpacing.sm)
                                        .padding(.vertical, AXSpacing.xxxs)
                                        .background(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                                .fill(Color.axError.opacity(0.08))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                                        .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 120, alignment: .center)
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
}
