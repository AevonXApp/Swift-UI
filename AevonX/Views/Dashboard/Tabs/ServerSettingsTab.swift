//
//  ServerSettingsTab.swift
//  AevonX
//
//  Legendary server settings & administration — 100% real SSH data
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

struct ServerSettingsTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    @StateObject private var vm: ServerSettingsViewModel

    init(server: Server, serverId: String, connectionViewModel: ServerConnectionViewModel) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        _vm = StateObject(wrappedValue: ServerSettingsViewModel(serverId: serverId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                // Hero Card
                heroCard
                // Quick Actions
                quickActionsBar
                // Two-column layout
                HStack(alignment: .top, spacing: AXSpacing.lg) {
                    // Left column
                    VStack(spacing: AXSpacing.lg) {
                        serverInfoCard
                        networkCard
                        diskStorageCard
                    }
                    .frame(maxWidth: .infinity)
                    // Right column
                    VStack(spacing: AXSpacing.lg) {
                        connectionCard
                        sshSecurityCard
                        systemCard
                    }
                    .frame(maxWidth: .infinity)
                }
                // Full width sections
                passwordManagementCard
                userManagementCard
                servicesCard
                dangerZoneCard
            }
            .padding(AXSpacing.xl)
        }
        .task { await vm.loadAll() }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.xl) {
                // Server icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [.axAccentBlue, .axAccentGreen.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                        .shadow(color: .axAccentBlue.opacity(0.3), radius: 12, y: 4)
                    Image(systemName: "server.rack")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text(server.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(vm.osInfo.isEmpty ? server.host : vm.osInfo)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                    HStack(spacing: AXSpacing.md) {
                        statusBadge(connectionViewModel.isConnected ? "Connected" : "Offline",
                                    color: connectionViewModel.isConnected ? .axSuccess : .axError)
                        if !vm.serverUptime.isEmpty {
                            statusBadge(vm.serverUptime, color: .axAccentBlue, icon: "clock")
                        }
                        if !vm.architecture.isEmpty {
                            statusBadge(vm.architecture, color: .axTextMuted, icon: "cpu")
                        }
                    }
                }

                Spacer()

                // IP Badge
                if !vm.publicIP.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Public IP")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.axTextTertiary)
                            .textCase(.uppercase)
                        Text(vm.publicIP)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 4)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsBar: some View {
        HStack(spacing: AXSpacing.md) {
            quickActionButton(icon: "arrow.clockwise", title: "Refresh", color: .axAccentBlue) {
                await vm.loadAll()
            }
            quickActionButton(icon: "arrow.triangle.2.circlepath", title: "Restart SSH", color: .axWarning) {
                let _ = try? await SSHBridge.shared.execute("sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh", serverId: serverId)
            }
            quickActionButton(icon: "arrow.down.circle", title: "Check Updates", color: .axAccentGreen) {
                await vm.checkUpdates()
            }
            if vm.updatesAvailable > 0 {
                quickActionButton(icon: "arrow.up.circle.fill", title: "Upgrade (\(vm.updatesAvailable))", color: .axError) {
                    await vm.upgradeSystem()
                }
            }
            Spacer()
        }
    }

    // MARK: - Server Information Card

    private var serverInfoCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "server.rack", title: "Server Info", subtitle: "System details", gradient: [.axAccentBlue, Color(red: 0.2, green: 0.5, blue: 1.0)])
                Divider().background(Color.axBorder)

                if vm.isLoadingInfo {
                    SettingsLoadingPlaceholder(text: "Loading server info...")
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        editableHostnameRow
                        SettingsInfoRow(icon: "desktopcomputer", title: "OS", value: vm.osInfo)
                        SettingsInfoRow(icon: "cpu", title: "Kernel", value: vm.kernelVersion)
                        SettingsInfoRow(icon: "memorychip", title: "Architecture", value: vm.architecture)
                        SettingsInfoRow(icon: "bolt.fill", title: "CPU", value: vm.cpuModel)
                        SettingsInfoRow(icon: "memorychip.fill", title: "Total RAM", value: vm.totalRAM)
                        SettingsInfoRow(icon: "clock", title: "Uptime", value: vm.serverUptime)
                        editableTimezoneRow
                    }
                    if let msg = vm.hostnameMsg { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }
                }
            }
        }
    }

    // MARK: - Network Card

    private var networkCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "network", title: "Network", subtitle: "IP & DNS configuration", gradient: [.axAccentGreen, Color(red: 0.1, green: 0.7, blue: 0.5)])
                Divider().background(Color.axBorder)

                if vm.isLoadingInfo {
                    SettingsLoadingPlaceholder(text: "Loading network...")
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        SettingsInfoRow(icon: "globe", title: "Public IP", value: vm.publicIP, valueColor: .axAccentBlue)
                        SettingsInfoRow(icon: "network", title: "Private IP", value: vm.privateIP)
                        SettingsInfoRow(icon: "arrow.triangle.branch", title: "Gateway", value: vm.defaultGateway)
                        SettingsInfoRow(icon: "magnifyingglass", title: "DNS Servers", value: vm.dnsServers)
                    }
                }
            }
        }
    }

    // MARK: - Disk Storage Card

    private var diskStorageCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "internaldrive", title: "Disk & Storage", subtitle: "Partition usage", gradient: [.purple, .purple.opacity(0.6)])
                Divider().background(Color.axBorder)

                if vm.isLoadingDisk {
                    SettingsLoadingPlaceholder(text: "Loading disk info...")
                } else if vm.diskPartitions.isEmpty {
                    Text("No partitions found").font(AXTypography.caption).foregroundColor(.axTextTertiary)
                } else {
                    ForEach(Array(vm.diskPartitions.enumerated()), id: \.offset) { _, part in
                        VStack(spacing: 4) {
                            HStack {
                                Text(part.mount)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                                Text("\(part.used) / \(part.size)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextSecondary)
                                Text("\(part.percent)%")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(part.percent >= 90 ? .axError : part.percent >= 70 ? .axWarning : .axSuccess)
                            }
                            DiskUsageBar(percent: part.percent)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Connection Card

    private var connectionCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "link", title: "Connection", subtitle: "SSH connection details", gradient: [.axAccentGreen, .teal])
                Divider().background(Color.axBorder)
                VStack(spacing: AXSpacing.sm) {
                    SettingsInfoRow(icon: "globe", title: "Host", value: server.host)
                    SettingsInfoRow(icon: "number", title: "Port", value: "\(server.port)")
                    SettingsInfoRow(icon: "person.fill", title: "Username", value: server.username)
                    SettingsInfoRow(icon: "circle.fill", title: "Status",
                                   value: connectionViewModel.isConnected ? "Connected" : "Disconnected",
                                   valueColor: connectionViewModel.isConnected ? .axSuccess : .axError)
                }
            }
        }
    }

    // MARK: - SSH Security Card

    private var sshSecurityCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "lock.shield.fill", title: "SSH Security", subtitle: "sshd_config management", gradient: [Color(red: 0.9, green: 0.3, blue: 0.3), .axError.opacity(0.7)])
                Divider().background(Color.axBorder)

                if vm.isLoadingSSH {
                    SettingsLoadingPlaceholder(text: "Loading SSH config...")
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        SettingsInfoRow(icon: "number", title: "SSH Port", value: vm.sshPort)
                        SettingsToggleRow(icon: "person.crop.circle.badge.exclamationmark", title: "Permit Root Login", isOn: $vm.permitRootLogin, tint: .axError)
                        SettingsToggleRow(icon: "key.horizontal", title: "Password Auth", isOn: $vm.passwordAuthEnabled, tint: .axWarning)
                        SettingsInfoRow(icon: "person.2.badge.key", title: "Max Auth Tries", value: vm.maxAuthTries)
                        SettingsInfoRow(icon: "key.fill", title: "Authorized Keys", value: "\(vm.authorizedKeysCount)")

                        if let msg = vm.sshMsg { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }

                        Button(action: { Task { await vm.saveSSHConfig() } }) {
                            HStack(spacing: AXSpacing.xs) {
                                if vm.isSavingSSH { ProgressView().scaleEffect(0.6) }
                                else { Image(systemName: "checkmark.shield.fill").font(.system(size: 12)) }
                                Text("Save & Reload SSH").font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(LinearGradient(colors: [.axAccentBlue, .axAccentBlue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle()).disabled(vm.isSavingSSH)
                    }
                }
            }
        }
    }

    // MARK: - System Card

    private var systemCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "gearshape.2.fill", title: "System", subtitle: "Swap & updates", gradient: [.axWarning, .orange.opacity(0.7)])
                Divider().background(Color.axBorder)
                VStack(spacing: AXSpacing.sm) {
                    // Swap
                    HStack {
                        Image(systemName: "memorychip").font(.system(size: 13)).foregroundColor(.axTextMuted).frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Swap Memory").font(AXTypography.body).foregroundColor(.axTextPrimary)
                            if vm.swapEnabled {
                                Text("\(vm.swapUsed) / \(vm.swapTotal)").font(.system(size: 11)).foregroundColor(.axTextTertiary)
                            }
                        }
                        Spacer()
                        statusBadge(vm.swapEnabled ? "Active" : "Disabled", color: vm.swapEnabled ? .axSuccess : .axTextMuted)
                    }

                    // Updates
                    HStack {
                        Image(systemName: "arrow.down.circle").font(.system(size: 13)).foregroundColor(.axTextMuted).frame(width: 22)
                        Text("System Updates").font(AXTypography.body).foregroundColor(.axTextPrimary)
                        Spacer()
                        if vm.isCheckingUpdates {
                            ProgressView().scaleEffect(0.6)
                        } else if vm.updatesAvailable > 0 {
                            statusBadge("\(vm.updatesAvailable) available", color: .axWarning, icon: "exclamationmark.circle")
                        } else {
                            statusBadge("Up to date", color: .axSuccess, icon: "checkmark.circle")
                        }
                    }
                    if let msg = vm.updateMessage { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }
                }
            }
        }
    }

    // MARK: - Password Management

    private var passwordManagementCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                SettingsGradientHeader(icon: "lock.rotation", title: "Password Management", subtitle: "Change system & database passwords", gradient: [.axWarning, .orange])
                Divider().background(Color.axBorder)

                SettingsPasswordRow(title: "Root Password", subtitle: "Linux root user", icon: "person.badge.key",
                    newPwd: $vm.rootNewPwd, confirmPwd: $vm.rootConfirmPwd,
                    isChanging: vm.isChangingRoot, message: vm.rootMsg, action: vm.changeRootPassword)

                Divider().background(Color.axBorder.opacity(0.4))

                SettingsPasswordRow(title: "MySQL Root", subtitle: "MySQL database root user", icon: "cylinder.split.1x2",
                    newPwd: $vm.mysqlNewPwd, confirmPwd: $vm.mysqlConfirmPwd,
                    isChanging: vm.isChangingMySQL, message: vm.mysqlMsg, action: vm.changeMySQLPassword)

                Divider().background(Color.axBorder.opacity(0.4))

                SettingsPasswordRow(title: "PostgreSQL", subtitle: "PostgreSQL postgres user", icon: "cylinder",
                    newPwd: $vm.pgNewPwd, confirmPwd: $vm.pgConfirmPwd,
                    isChanging: vm.isChangingPG, message: vm.pgMsg, action: vm.changePGPassword)
            }
        }
    }

    // MARK: - User Management

    private var userManagementCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "person.2.fill", title: "User Management", subtitle: "System users & access", gradient: [.cyan, .axAccentBlue])
                Divider().background(Color.axBorder)

                if vm.isLoadingUsers {
                    SettingsLoadingPlaceholder(text: "Loading users...")
                } else {
                    // User list
                    ForEach(Array(vm.systemUsers.enumerated()), id: \.offset) { _, user in
                        HStack(spacing: AXSpacing.sm) {
                            ZStack {
                                Circle().fill(user.name == "root" ? Color.axError.opacity(0.15) : Color.axAccentBlue.opacity(0.15))
                                    .frame(width: 30, height: 30)
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(user.name == "root" ? .axError : .axAccentBlue)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: AXSpacing.xs) {
                                    Text(user.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                                    Text("UID:\(user.uid)").font(.system(size: 10)).foregroundColor(.axTextTertiary)
                                }
                                Text(user.shell).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextTertiary)
                            }
                            Spacer()
                            if user.name != "root" {
                                Button(action: { Task { await vm.deleteUser(user.name) } }) {
                                    Image(systemName: "trash").font(.system(size: 11)).foregroundColor(.axError.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Divider().background(Color.axBorder.opacity(0.4))

                    // Add user
                    HStack(spacing: AXSpacing.sm) {
                        TextField("Username", text: $vm.newUsername)
                            .font(.system(size: 12)).textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, AXSpacing.sm).padding(.vertical, 5)
                            .background(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                        SecureField("Password", text: $vm.newUserPassword)
                            .font(.system(size: 12)).textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, AXSpacing.sm).padding(.vertical, 5)
                            .background(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                        Button(action: { Task { await vm.addUser() } }) {
                            HStack(spacing: 3) {
                                if vm.isAddingUser { ProgressView().scaleEffect(0.5) }
                                else { Image(systemName: "plus").font(.system(size: 10, weight: .bold)) }
                                Text("Add").font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white).padding(.horizontal, AXSpacing.md).padding(.vertical, 5)
                            .background(Color.axAccentBlue).cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle()).disabled(vm.isAddingUser || vm.newUsername.isEmpty)
                    }
                    if let msg = vm.userMsg { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }
                }
            }
        }
    }


    // MARK: - Services

    private var servicesCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "square.stack.3d.up.fill", title: "Services", subtitle: "systemd service control", gradient: [.teal, .mint])
                Divider().background(Color.axBorder)

                if vm.isLoadingServices {
                    SettingsLoadingPlaceholder(text: "Loading services...")
                } else {
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: AXSpacing.sm) {
                        ForEach(Array(vm.runningServices.enumerated()), id: \.offset) { _, svc in
                            HStack(spacing: AXSpacing.xs) {
                                Circle()
                                    .fill(svc.isActive ? Color.axSuccess : Color.axError)
                                    .frame(width: 7, height: 7)
                                Text(svc.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { Task { await vm.restartService(svc.name) } }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 9))
                                        .foregroundColor(.axAccentBlue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Button(action: { Task { await vm.toggleService(svc.name, start: !svc.isActive) } }) {
                                    Image(systemName: svc.isActive ? "stop.fill" : "play.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(svc.isActive ? .axError : .axSuccess)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
                            .background(Color.axBackgroundTertiary.opacity(0.5))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Danger Zone

    @State private var showRemoveAlert = false

    private var dangerZoneCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "exclamationmark.triangle.fill", title: "Danger Zone", subtitle: "Destructive actions", gradient: [.axError, .red.opacity(0.7)])
                Divider().background(Color.axError.opacity(0.3))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remove Server").font(AXTypography.body).foregroundColor(.axTextPrimary)
                        Text("Permanently remove from your fleet").font(.system(size: 11)).foregroundColor(.axTextTertiary)
                    }
                    Spacer()
                    Button(action: { showRemoveAlert = true }) {
                        Text("Remove")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axError)
                            .padding(.horizontal, AXSpacing.md).padding(.vertical, 6)
                            .background(Color.axError.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axError.opacity(0.3), lineWidth: 1))
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axError.opacity(0.2), lineWidth: 1))
        .alert("Remove Server?", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {}
        } message: {
            Text("Remove \"\(server.name)\"? This cannot be undone.")
        }
    }

    // MARK: - Editable Rows

    private var editableHostnameRow: some View {
        HStack {
            Image(systemName: "desktopcomputer").font(.system(size: 13)).foregroundColor(.axTextMuted).frame(width: 22)
            Text("Hostname").font(AXTypography.body).foregroundColor(.axTextPrimary)
            Spacer()
            if vm.isEditingHostname {
                HStack(spacing: 4) {
                    TextField("hostname", text: $vm.newHostname)
                        .font(.system(size: 12, design: .monospaced))
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.axBackgroundTertiary).cornerRadius(4).frame(width: 150)
                    Button(action: { Task { await vm.changeHostname() } }) {
                        Image(systemName: vm.isChangingHostname ? "hourglass" : "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.axSuccess)
                    }.buttonStyle(PlainButtonStyle())
                    Button(action: { vm.isEditingHostname = false; vm.newHostname = vm.hostname }) {
                        Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.axTextMuted)
                    }.buttonStyle(PlainButtonStyle())
                }
            } else {
                HStack(spacing: 4) {
                    Text(vm.hostname).font(.system(size: 13, design: .monospaced)).foregroundColor(.axTextSecondary)
                    Button(action: { vm.isEditingHostname = true }) {
                        Image(systemName: "pencil").font(.system(size: 9)).foregroundColor(.axAccentBlue)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var editableTimezoneRow: some View {
        HStack {
            Image(systemName: "globe.americas").font(.system(size: 13)).foregroundColor(.axTextMuted).frame(width: 22)
            Text("Timezone").font(AXTypography.body).foregroundColor(.axTextPrimary)
            Spacer()
            if vm.isEditingTimezone {
                HStack(spacing: 4) {
                    Picker("", selection: $vm.selectedTimezone) {
                        ForEach(vm.commonTimezones, id: \.self) { Text($0).tag($0) }
                    }.frame(width: 160)
                    Button(action: { Task { await vm.changeTimezone() } }) {
                        Image(systemName: vm.isChangingTimezone ? "hourglass" : "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.axSuccess)
                    }.buttonStyle(PlainButtonStyle())
                    Button(action: { vm.isEditingTimezone = false; vm.selectedTimezone = vm.currentTimezone }) {
                        Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.axTextMuted)
                    }.buttonStyle(PlainButtonStyle())
                }
            } else {
                HStack(spacing: 4) {
                    Text(vm.currentTimezone).font(.system(size: 13, design: .monospaced)).foregroundColor(.axTextSecondary)
                    Button(action: { vm.isEditingTimezone = true }) {
                        Image(systemName: "pencil").font(.system(size: 9)).foregroundColor(.axAccentBlue)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Helpers

    private func statusBadge(_ text: String, color: Color, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 9))
            } else {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            Text(text).font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button(action: { Task { await action() } }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.md).padding(.vertical, 8)
            .background(color.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.2), lineWidth: 1))
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SettingRow (kept for backward compat)

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        SettingsInfoRow(icon: icon, title: title, value: value)
    }
}

#Preview {
    ServerSettingsTab(
        server: Server.placeholder(name: "Preview"),
        serverId: "test",
        connectionViewModel: ServerConnectionViewModel(server: Server.placeholder(name: "Preview"), serverId: "test")
    )
    .background(Color.axBackground)
}
