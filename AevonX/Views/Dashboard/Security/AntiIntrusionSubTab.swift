//
//  AntiIntrusionSubTab.swift
//  AevonX
//
//  Intrusion detection overview — real data from server
//

import SwiftUI
import AevonXCore

// MARK: - View

struct AntiIntrusionSubTab: View {
    let serverId: String

    @State private var isLoading = true
    @State private var fail2banActive = false
    @State private var jailList: [String] = []
    @State private var jailDetails: [(jail: String, currentlyBanned: Int, totalBanned: Int, bannedIPs: [String])] = []
    @State private var isInstalling = false

    private let sshService = SSHService.shared

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

        // Check fail2ban overall status
        if let result = try? await sshService.execute(
            CommandTemplate.security(.fail2banStatus).build(), serverId: serverId
        ) {
            await MainActor.run {
                let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                fail2banActive = !trimmed.contains("not-installed")

                // Parse jail list from status output
                var jails: [String] = []
                for line in trimmed.components(separatedBy: "\n") {
                    if line.contains("Jail list:") {
                        let parts = line.components(separatedBy: ":")
                        if parts.count >= 2 {
                            jails = parts[1]
                                .components(separatedBy: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                        }
                    }
                }
                jailList = jails
            }
        }

        guard fail2banActive else { return }

        // Get details for each jail
        var details: [(jail: String, currentlyBanned: Int, totalBanned: Int, bannedIPs: [String])] = []
        for jail in jailList {
            if let result = try? await sshService.execute(
                CommandTemplate.security(.fail2banJailStatus(jail: jail)).build(), serverId: serverId
            ) {
                let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed != "not-found" else { continue }

                var current = 0
                var total = 0
                var ips: [String] = []

                for line in trimmed.components(separatedBy: "\n") {
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
                        Text("Intrusion Detection & Prevention")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("fail2ban jail monitoring and banned IP management")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                Button(action: {
                    Task { await loadData() }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text("Refresh")
                            .font(AXTypography.headline)
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
            Text("Loading intrusion detection status…")
                .font(AXTypography.body)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
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
                Text("Install fail2ban to enable intrusion detection and automatic IP banning.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextMuted)
                    .multilineTextAlignment(.center)

                Button(action: {
                    Task {
                        isInstalling = true
                        _ = try? await sshService.execute(
                            "sudo apt-get install fail2ban -y", serverId: serverId
                        )
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

            statCard(icon: "shield.fill", label: "Active Jails", value: "\(jailList.count)", color: .axAccentBlue)
            statCard(icon: "hand.raised.fill", label: "Currently Banned", value: "\(totalCurrent)", color: .axError)
            statCard(icon: "chart.line.uptrend.xyaxis", label: "Total Banned", value: "\(totalAllTime)", color: .axWarning)
            statCard(icon: "network.badge.shield.half.filled", label: "Unique IPs", value: "\(totalIPs)", color: .axAccentGreen)
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(color)
                    Text(label)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Jails

    private var jailsCard: some View {
        ForEach(jailDetails, id: \.jail) { detail in
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    // Jail header
                    HStack {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.axAccentBlue)
                            Text("Jail: \(detail.jail)")
                                .font(AXTypography.title3)
                                .foregroundColor(.axTextPrimary)
                        }

                        Spacer()

                        HStack(spacing: AXSpacing.lg) {
                            HStack(spacing: AXSpacing.xs) {
                                Text("Currently:")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                Text("\(detail.currentlyBanned)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.axError)
                            }
                            HStack(spacing: AXSpacing.xs) {
                                Text("Total:")
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
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.axSuccess)
                            Text("No IPs currently banned in this jail")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xl)
                    } else {
                        // IP list
                        HStack(spacing: 0) {
                            Text("IP Address").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Action").frame(width: 100, alignment: .center)
                        }
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axBackgroundTertiary.opacity(0.5))

                        ForEach(Array(detail.bannedIPs.enumerated()), id: \.element) { index, ip in
                            HStack(spacing: 0) {
                                Text(ip)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.axError)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    Task {
                                        let cmd = CommandTemplate.security(.fail2banUnban(ip: ip, jail: detail.jail))
                                        _ = try? await sshService.execute(cmd.build(), serverId: serverId)
                                        await loadData()
                                    }
                                }) {
                                    Text("Unban")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axAccentBlue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .frame(width: 100, alignment: .center)
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
