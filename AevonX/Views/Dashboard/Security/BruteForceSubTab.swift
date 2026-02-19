//
//  BruteForceSubTab.swift
//  AevonX
//
//  Brute force protection (fail2ban) — real data
//

import SwiftUI
import AevonXCore

// MARK: - View

struct BruteForceSubTab: View {
    let serverId: String

    @State private var isInstalled = false
    @State private var isLoading = true
    @State private var jailInfo = ""
    @State private var bannedIPs: [String] = []
    @State private var currentlyBanned = 0
    @State private var totalBanned = 0
    @State private var whitelistIP = ""
    @State private var maxRetries = 5
    @State private var banDuration = 600
    @State private var isInstalling = false

    private let sshService = SSHService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                headerCard

                if isLoading {
                    loadingView
                } else if !isInstalled {
                    notInstalledView
                } else {
                    HStack(alignment: .top, spacing: AXSpacing.xl) {
                        configurationCard
                            .frame(maxWidth: .infinity)
                        statsCard
                            .frame(width: 280)
                    }

                    bannedIPsCard
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

        // Check fail2ban status
        if let result = try? await sshService.execute(
            CommandTemplate.security(.fail2banStatus).build(), serverId: serverId
        ) {
            await MainActor.run {
                isInstalled = !result.stdout.contains("not-installed")
            }
        }

        guard isInstalled else { return }

        // Get SSHD jail status
        if let result = try? await sshService.execute(
            CommandTemplate.security(.fail2banJailStatus(jail: "sshd")).build(), serverId: serverId
        ) {
            await MainActor.run {
                parseJailStatus(result.stdout)
            }
        }
    }

    private func parseJailStatus(_ raw: String) {
        guard raw != "not-found" else { return }
        jailInfo = raw

        // Parse currently banned count
        if let line = raw.components(separatedBy: "\n").first(where: { $0.contains("Currently banned") }) {
            let parts = line.components(separatedBy: ":")
            if let last = parts.last {
                currentlyBanned = Int(last.trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }

        // Parse total banned count
        if let line = raw.components(separatedBy: "\n").first(where: { $0.contains("Total banned") }) {
            let parts = line.components(separatedBy: ":")
            if let last = parts.last {
                totalBanned = Int(last.trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }

        // Parse banned IP list
        if let line = raw.components(separatedBy: "\n").first(where: { $0.contains("Banned IP list") }) {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let ipStr = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                bannedIPs = ipStr.components(separatedBy: " ").filter { !$0.isEmpty }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        AXCard {
            HStack {
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isInstalled ? .axWarning : .axTextMuted)

                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text("Brute Force Protection")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("fail2ban — Automatically blocks IPs after repeated failed login attempts")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                if !isLoading {
                    HStack(spacing: AXSpacing.sm) {
                        Circle()
                            .fill(isInstalled ? Color.axSuccess : Color.axError)
                            .frame(width: 7, height: 7)
                        Text(isInstalled ? "Active" : "Not Installed")
                            .font(AXTypography.caption)
                            .foregroundColor(isInstalled ? .axSuccess : .axError)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(isInstalled ? Color.axSuccess.opacity(0.08) : Color.axError.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(isInstalled ? Color.axSuccess.opacity(0.2) : Color.axError.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
            Text("Loading fail2ban status…")
                .font(AXTypography.body)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }

    private var notInstalledView: some View {
        AXCard {
            VStack(spacing: AXSpacing.lg) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 40))
                    .foregroundColor(.axWarning)

                Text("fail2ban is not installed")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)

                Text("Install fail2ban on your server to enable brute force protection.")
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

    // MARK: - Configuration

    private var configurationCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .foregroundColor(.axAccentBlue)
                    Text("Configuration")
                        .font(AXTypography.title3)
                        .foregroundColor(.axTextPrimary)
                }

                Divider().background(Color.axBorder)

                // Max retries
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Max Failed Attempts")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)

                    HStack(spacing: AXSpacing.md) {
                        Stepper("\(maxRetries)", value: $maxRetries, in: 1...50)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 120)

                        Button(action: {
                            Task {
                                let cmd = CommandTemplate.security(.fail2banSetMaxRetry(count: maxRetries))
                                _ = try? await sshService.execute(cmd.build(), serverId: serverId)
                            }
                        }) {
                            Text("Apply")
                                .font(AXTypography.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .fill(Color.axAccentBlue)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("attempts before ban")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }

                // Ban duration
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Ban Duration")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)

                    HStack(spacing: AXSpacing.md) {
                        Picker("", selection: $banDuration) {
                            Text("5 min").tag(300)
                            Text("10 min").tag(600)
                            Text("30 min").tag(1800)
                            Text("1 hour").tag(3600)
                            Text("24 hours").tag(86400)
                            Text("Permanent").tag(-1)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)

                        Button(action: {
                            Task {
                                let cmd = CommandTemplate.security(.fail2banSetBanTime(seconds: banDuration))
                                _ = try? await sshService.execute(cmd.build(), serverId: serverId)
                            }
                        }) {
                            Text("Apply")
                                .font(AXTypography.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .fill(Color.axAccentBlue)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.axAccentPurple)
                    Text("Statistics")
                        .font(AXTypography.title3)
                        .foregroundColor(.axTextPrimary)
                }

                Divider().background(Color.axBorder)

                VStack(spacing: AXSpacing.lg) {
                    statRow(label: "Currently Banned", value: "\(currentlyBanned)", color: .axError)
                    statRow(label: "Total Banned", value: "\(totalBanned)", color: .axWarning)
                    statRow(label: "Active Jail", value: "sshd", color: .axAccentGreen)
                }

                Divider().background(Color.axBorder)

                Button(action: {
                    Task { await loadData() }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text("Refresh")
                            .font(AXTypography.headline)
                    }
                    .frame(maxWidth: .infinity)
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

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.body)
                .foregroundColor(.axTextMuted)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }

    // MARK: - Banned IPs

    private var bannedIPsCard: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "xmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.axError)
                        Text("Currently Banned IPs")
                            .font(AXTypography.title3)
                            .foregroundColor(.axTextPrimary)
                    }

                    Spacer()

                    Text("\(bannedIPs.count) banned")
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                }
                .padding(AXSpacing.lg)

                Divider().background(Color.axBorder)

                if bannedIPs.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.axSuccess)
                        Text("No IPs currently banned")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.xxxl)
                } else {
                    // Header
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

                    Divider().background(Color.axBorder)

                    ForEach(Array(bannedIPs.enumerated()), id: \.element) { index, ip in
                        HStack(spacing: 0) {
                            Text(ip)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.axError)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                                Task {
                                    let cmd = CommandTemplate.security(.fail2banUnban(ip: ip, jail: "sshd"))
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
