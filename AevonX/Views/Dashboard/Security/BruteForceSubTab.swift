//
//  BruteForceSubTab.swift
//  AevonX
//
//  Brute force protection (fail2ban) — real data
//  Phase 2: Search, filter, sort, whitelist, improved UX
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
    @State private var maxRetries = 5
    @State private var banDuration = 600
    @State private var isInstalling = false

    // Phase 2: Search, filter, sort
    @State private var banSearchText = ""
    @State private var banSortAscending = true
    @State private var showUnbanAllConfirm = false
    @State private var newBanIP = ""
    @State private var isAddingBan = false
    @State private var ipToUnban: String? = nil

    // Phase 2: Whitelist
    @State private var whitelistIPs: [String] = []
    @State private var newWhitelistIP = ""
    @State private var isAddingWhitelist = false
    @State private var ipToRemoveFromWhitelist: String? = nil

    private let securityManager = SecurityManager.shared

    // Filtered + sorted banned IPs
    private var displayedBannedIPs: [String] {
        var ips = bannedIPs
        if !banSearchText.isEmpty {
            ips = ips.filter { $0.localizedCaseInsensitiveContains(banSearchText) }
        }
        ips.sort { ip1, ip2 in
            banSortAscending ? ip1 < ip2 : ip1 > ip2
        }
        return ips
    }

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
                    whitelistCard
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadData() }
        .alert("Unban IP", isPresented: Binding(
            get: { ipToUnban != nil },
            set: { if !$0 { ipToUnban = nil } }
        )) {
            Button("Cancel", role: .cancel) { ipToUnban = nil }
            Button("Unban", role: .destructive) {
                if let ip = ipToUnban {
                    Task {
                        let _ = await securityManager.fail2banUnban(ip: ip, jail: "sshd", serverId: serverId)
                        await loadData()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to unban \(ipToUnban ?? "")? This IP will be able to attempt logins again.")
        }
        .alert("Unban All IPs", isPresented: $showUnbanAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Unban All", role: .destructive) {
                Task {
                    let _ = await securityManager.fail2banUnbanAll(jail: "sshd", serverId: serverId)
                    await loadData()
                }
            }
        } message: {
            Text("Are you sure you want to unban all \(bannedIPs.count) IP(s)? All blocked addresses will be able to attempt logins again.")
        }
        .alert("Remove from Whitelist", isPresented: Binding(
            get: { ipToRemoveFromWhitelist != nil },
            set: { if !$0 { ipToRemoveFromWhitelist = nil } }
        )) {
            Button("Cancel", role: .cancel) { ipToRemoveFromWhitelist = nil }
            Button("Remove", role: .destructive) {
                if let ip = ipToRemoveFromWhitelist {
                    Task {
                        let _ = await securityManager.fail2banRemoveFromWhitelist(ip: ip, serverId: serverId)
                        await loadData()
                    }
                }
            }
        } message: {
            Text("Remove \(ipToRemoveFromWhitelist ?? "") from the whitelist? This IP may get banned in the future.")
        }
    }

    // MARK: - Load Data

    private func loadData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        // Check fail2ban status (from Core)
        let installed = await securityManager.fail2banStatus(serverId: serverId)
        await MainActor.run { isInstalled = installed }

        guard isInstalled else { return }

        // Get SSHD jail status (from Core)
        let status = await securityManager.fail2banJailStatus(jail: "sshd", serverId: serverId)
        await MainActor.run { parseJailStatus(status) }

        // Load whitelist (from Core)
        let wl = await securityManager.fail2banWhitelist(serverId: serverId)
        await MainActor.run { whitelistIPs = wl }
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
        AXLoadingState(message: "Loading fail2ban status…")
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

    // MARK: - Configuration

    private var configurationCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                AXSectionTitle(title: "Configuration", icon: "slider.horizontal.3")

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
                                let _ = await securityManager.fail2banSetMaxRetry(count: maxRetries, serverId: serverId)
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
                                let _ = await securityManager.fail2banSetBanTime(seconds: banDuration, serverId: serverId)
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
                AXSectionTitle(title: "Statistics", icon: "chart.bar.fill", iconColor: .axAccentPurple)

                Divider().background(Color.axBorder)

                VStack(spacing: AXSpacing.lg) {
                    statRow(label: "Currently Banned", value: "\(currentlyBanned)", color: .axError)
                    statRow(label: "Total Banned", value: "\(totalBanned)", color: .axWarning)
                    statRow(label: "Active Jail", value: "sshd", color: .axAccentGreen)
                    statRow(label: "Whitelisted", value: "\(whitelistIPs.count)", color: .axAccentBlue)
                }

                Divider().background(Color.axBorder)

                AXRefreshButton(isLoading: isLoading) {
                    await loadData()
                }
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

    // MARK: - Banned IPs (Phase 2: search + filter + sort + improved unban)

    private var bannedIPsCard: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                // Header with search and actions
                VStack(spacing: AXSpacing.sm) {
                        HStack {
                            AXSectionTitle(title: "Banned IPs", icon: "xmark.shield.fill", iconColor: .axError)

                            AXBadge(text: "\(bannedIPs.count) banned", color: bannedIPs.isEmpty ? .axSuccess : .axError, style: .filled)

                        // Sort toggle
                        Button(action: { banSortAscending.toggle() }) {
                            Image(systemName: banSortAscending ? "arrow.up" : "arrow.down")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.axTextMuted)
                                .padding(AXSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .fill(Color.axSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                                .stroke(Color.axBorder, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(banSortAscending ? "Sort Z→A" : "Sort A→Z")

                        // Unban All button
                        if !bannedIPs.isEmpty {
                            Button(action: { showUnbanAllConfirm = true }) {
                                HStack(spacing: AXSpacing.xxs) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 10))
                                    Text("Unban All")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.axError)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxs)
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
                        }
                    }

                    // Search bar
                    if !bannedIPs.isEmpty || !banSearchText.isEmpty {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextMuted)
                            TextField("Search by IP address…", text: $banSearchText)
                                .font(AXTypography.body)
                                .textFieldStyle(.plain)

                            if !banSearchText.isEmpty {
                                Button(action: { banSearchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.axTextMuted)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(Color.axBackgroundTertiary.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(AXSpacing.lg)

                Divider().background(Color.axBorder)

                // Ban IP row
                HStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "nosign")
                            .font(.system(size: 12))
                            .foregroundColor(.axError)
                        TextField("Enter IP to ban (e.g. 192.168.1.100)", text: $newBanIP)
                            .font(.system(size: 12, design: .monospaced))
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axBackgroundTertiary.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                            )
                    )

                    Button(action: {
                        guard !newBanIP.isEmpty else { return }
                        Task {
                            isAddingBan = true
                            let _ = await securityManager.fail2banBanIP(ip: newBanIP, jail: "sshd", serverId: serverId)
                            await MainActor.run { newBanIP = "" }
                            isAddingBan = false
                            await loadData()
                        }
                    }) {
                        HStack(spacing: AXSpacing.xxs) {
                            if isAddingBan {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            Text("Ban")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(newBanIP.isEmpty ? Color.axTextMuted : Color.axError)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(newBanIP.isEmpty || isAddingBan)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)

                Divider().background(Color.axBorder)

                if bannedIPs.isEmpty {
                    AXPlaceholder(
                        icon: "checkmark.shield.fill",
                        title: "No IPs currently banned",
                        iconColor: .axSuccess
                    )
                } else if displayedBannedIPs.isEmpty {
                    AXPlaceholder(
                        icon: "magnifyingglass",
                        title: "No IPs match \"\(banSearchText)\""
                    )
                } else {
                    // Table header
                    HStack(spacing: 0) {
                        Text("IP Address").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Action").frame(width: 120, alignment: .center)
                    }
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axBackgroundTertiary.opacity(0.5))

                    Divider().background(Color.axBorder)

                    ForEach(Array(displayedBannedIPs.enumerated()), id: \.element) { index, ip in
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

                            Button(action: { ipToUnban = ip }) {
                                HStack(spacing: AXSpacing.xxs) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                    Text("Remove")
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

    // MARK: - Whitelist Management (Phase 2)

    private var whitelistCard: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                    AXSectionTitle(title: "Whitelisted IPs", icon: "checkmark.shield.fill", iconColor: .axAccentGreen) {
                        AXBadge(text: "Never banned", color: .axTextMuted, style: .soft)
                    }
                .padding(AXSpacing.lg)

                Divider().background(Color.axBorder)

                // Add IP row
                HStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.axAccentGreen)
                        TextField("Enter IP address (e.g. 192.168.1.100)", text: $newWhitelistIP)
                            .font(.system(size: 12, design: .monospaced))
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(Color.axBackgroundTertiary.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                            )
                    )

                    Button(action: {
                        guard !newWhitelistIP.isEmpty else { return }
                        Task {
                            isAddingWhitelist = true
                            let _ = await securityManager.fail2banAddToWhitelist(ip: newWhitelistIP, serverId: serverId)
                            await MainActor.run { newWhitelistIP = "" }
                            isAddingWhitelist = false
                            await loadData()
                        }
                    }) {
                        HStack(spacing: AXSpacing.xxs) {
                            if isAddingWhitelist {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            Text("Add")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(newWhitelistIP.isEmpty ? Color.axTextMuted : Color.axAccentGreen)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(newWhitelistIP.isEmpty || isAddingWhitelist)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)

                Divider().background(Color.axBorder)

                if whitelistIPs.isEmpty {
                    AXPlaceholder(
                        icon: "shield.slash",
                        title: "No whitelisted IPs",
                        subtitle: "Add IPs that should never be banned"
                    )
                } else {
                    ForEach(Array(whitelistIPs.enumerated()), id: \.element) { index, ip in
                        HStack(spacing: 0) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axAccentGreen)
                                Text(ip)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: { ipToRemoveFromWhitelist = ip }) {
                                HStack(spacing: AXSpacing.xxs) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                    Text("Remove")
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
