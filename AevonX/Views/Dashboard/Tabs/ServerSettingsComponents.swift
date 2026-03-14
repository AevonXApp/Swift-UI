//
//  ServerSettingsComponents.swift
//  AevonX
//
//  Reusable components for the legendary server settings tab
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Settings ViewModel

@MainActor
class ServerSettingsViewModel: ObservableObject {
    let serverId: String
    
    // Server Info
    @Published var hostname = ""
    @Published var osInfo = ""
    @Published var kernelVersion = ""
    @Published var architecture = ""
    @Published var serverUptime = ""
    @Published var currentTimezone = ""
    @Published var cpuModel = ""
    @Published var totalRAM = ""
    @Published var publicIP = ""
    @Published var privateIP = ""
    @Published var defaultGateway = ""
    @Published var dnsServers = ""
    @Published var isLoadingInfo = true
    
    // SSH Security
    @Published var permitRootLogin = false
    @Published var passwordAuthEnabled = false
    @Published var sshPort = "22"
    @Published var authorizedKeysCount = 0
    @Published var maxAuthTries = "6"
    @Published var isLoadingSSH = true
    
    // Users
    @Published var systemUsers: [(name: String, uid: String, shell: String, lastLogin: String)] = []
    @Published var isLoadingUsers = true
    
    // Services
    @Published var runningServices: [(name: String, status: String, isActive: Bool)] = []
    @Published var isLoadingServices = true
    
    // Disk
    @Published var diskPartitions: [(mount: String, size: String, used: String, avail: String, percent: Int)] = []
    @Published var isLoadingDisk = true
    
    // Swap
    @Published var swapTotal = ""
    @Published var swapUsed = ""
    @Published var swapEnabled = false
    
    // Updates
    @Published var updatesAvailable = 0
    @Published var isCheckingUpdates = false
    @Published var isUpgrading = false
    @Published var updateMessage: (String, Bool)? = nil
    
    // Password states
    @Published var rootNewPwd = ""
    @Published var rootConfirmPwd = ""
    @Published var isChangingRoot = false
    @Published var rootMsg: (String, Bool)? = nil
    
    @Published var mysqlNewPwd = ""
    @Published var mysqlConfirmPwd = ""
    @Published var isChangingMySQL = false
    @Published var mysqlMsg: (String, Bool)? = nil
    
    @Published var pgNewPwd = ""
    @Published var pgConfirmPwd = ""
    @Published var isChangingPG = false
    @Published var pgMsg: (String, Bool)? = nil
    
    // Hostname/Timezone editing
    @Published var newHostname = ""
    @Published var isEditingHostname = false
    @Published var isChangingHostname = false
    @Published var hostnameMsg: (String, Bool)? = nil
    
    @Published var selectedTimezone = ""
    @Published var isEditingTimezone = false
    @Published var isChangingTimezone = false
    
    // SSH saving
    @Published var isSavingSSH = false
    @Published var sshMsg: (String, Bool)? = nil
    
    // New user
    @Published var newUsername = ""
    @Published var newUserPassword = ""
    @Published var isAddingUser = false
    @Published var userMsg: (String, Bool)? = nil
    
    let commonTimezones = [
        "UTC", "US/Eastern", "US/Central", "US/Mountain", "US/Pacific",
        "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Moscow",
        "Asia/Tokyo", "Asia/Shanghai", "Asia/Kolkata", "Asia/Dubai", "Asia/Riyadh",
        "Australia/Sydney", "Pacific/Auckland", "America/Sao_Paulo", "Africa/Cairo"
    ]
    
    init(serverId: String) {
        self.serverId = serverId
    }
    
    private func ssh(_ cmd: String) async -> String {
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: cmd)
        let result = SSHResult.parse(json)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Load All
    
    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadServerInfo() }
            group.addTask { await self.loadSSHConfig() }
            group.addTask { await self.loadUsers() }

            group.addTask { await self.loadServices() }
            group.addTask { await self.loadDisk() }
        }
    }
    
    func loadServerInfo() async {
        isLoadingInfo = true
        defer { isLoadingInfo = false }
        
        async let h = ssh("hostname")
        async let os = ssh("cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'\"' -f2")
        async let k = ssh("uname -r")
        async let a = ssh("uname -m")
        async let u = ssh("uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}' | sed 's/^.*up //'")
        async let tz = ssh("timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null")
        async let cpu = ssh("grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs")
        async let ram = ssh("free -h | grep Mem | awk '{print $2}'")
        async let pubIP = ssh("curl -s --max-time 3 ifconfig.me 2>/dev/null || echo 'N/A'")
        async let privIP = ssh("hostname -I 2>/dev/null | awk '{print $1}'")
        async let gw = ssh("ip route | grep default | awk '{print $3}' | head -1")
        async let dns = ssh("cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' | head -3 | tr '\\n' ', ' | sed 's/,$//'")
        async let swp = ssh("free -m 2>/dev/null | grep Swap | awk '{print $2\"|\"$3}'")
        
        hostname = await h; newHostname = hostname
        osInfo = await os
        kernelVersion = await k
        architecture = await a
        serverUptime = await u
        currentTimezone = await tz; selectedTimezone = currentTimezone
        cpuModel = await cpu
        totalRAM = await ram
        publicIP = await pubIP
        privateIP = await privIP
        defaultGateway = await gw
        dnsServers = await dns
        
        let swpStr = await swp
        let parts = swpStr.split(separator: "|")
        if parts.count == 2 {
            let totalMB = Int(parts[0]) ?? 0
            let usedMB = Int(parts[1]) ?? 0
            swapEnabled = totalMB > 0
            swapTotal = totalMB >= 1024 ? String(format: "%.1f GB", Double(totalMB) / 1024.0) : "\(totalMB) MB"
            swapUsed = usedMB >= 1024 ? String(format: "%.1f GB", Double(usedMB) / 1024.0) : "\(usedMB) MB"
        }
    }
    
    func loadSSHConfig() async {
        isLoadingSSH = true
        defer { isLoadingSSH = false }
        
        let rootVal = await ssh("grep -i '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}'").lowercased()
        permitRootLogin = (rootVal == "yes" || rootVal == "without-password" || rootVal == "prohibit-password")
        
        let pwdVal = await ssh("grep -i '^PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}'").lowercased()
        passwordAuthEnabled = (pwdVal == "yes")
        
        sshPort = await ssh("grep -i '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo '22'")
        if sshPort.isEmpty { sshPort = "22" }
        
        let keys = await ssh("wc -l < ~/.ssh/authorized_keys 2>/dev/null || echo '0'")
        authorizedKeysCount = Int(keys) ?? 0
        
        maxAuthTries = await ssh("grep -i '^MaxAuthTries' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo '6'")
        if maxAuthTries.isEmpty { maxAuthTries = "6" }
    }
    
    func loadUsers() async {
        isLoadingUsers = true
        defer { isLoadingUsers = false }
        
        let output = await ssh("awk -F: '$3>=1000 || $1==\"root\" {print $1\"|\"$3\"|\"$7}' /etc/passwd 2>/dev/null")
        let lastOutput = await ssh("lastlog 2>/dev/null | tail -n +2")
        
        var lastLogins: [String: String] = [:]
        for line in lastOutput.split(separator: "\n") {
            let parts = line.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                let user = String(parts[0])
                let rest = String(parts[1]).trimmingCharacters(in: .whitespaces)
                lastLogins[user] = rest.hasPrefix("**Never") ? "Never" : String(rest.prefix(30))
            }
        }
        
        systemUsers = output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count == 3 else { return nil }
            let name = String(parts[0])
            guard name != "nobody" && name != "nfsnobody" else { return nil }
            return (name: name, uid: String(parts[1]), shell: String(parts[2]), lastLogin: lastLogins[name] ?? "Unknown")
        }
    }
    

    
    func loadServices() async {
        isLoadingServices = true
        defer { isLoadingServices = false }
        
        let output = await ssh("systemctl list-units --type=service --no-pager --no-legend 2>/dev/null | head -30 | awk '{print $1\"|\"$3\"|\"$4}'")
        runningServices = output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|")
            guard parts.count >= 3 else { return nil }
            let name = String(parts[0]).replacingOccurrences(of: ".service", with: "")
            let active = String(parts[1])
            let sub = String(parts[2])
            return (name: name, status: sub, isActive: active == "active")
        }
    }
    
    func loadDisk() async {
        isLoadingDisk = true
        defer { isLoadingDisk = false }
        
        let output = await ssh("df -h --output=target,size,used,avail,pcent 2>/dev/null | tail -n +2 | grep -vE 'tmpfs|devtmpfs|udev|snap'")
        diskPartitions = output.split(separator: "\n").compactMap { line in
            let cols = String(line).split(separator: " ").map(String.init)
            guard cols.count >= 5 else { return nil }
            let pct = Int(cols[4].replacingOccurrences(of: "%", with: "")) ?? 0
            return (mount: cols[0], size: cols[1], used: cols[2], avail: cols[3], percent: pct)
        }
    }
    
    // MARK: - Actions
    
    func changeHostname() async {
        guard !newHostname.isEmpty, newHostname != hostname else { return }
        isChangingHostname = true; defer { isChangingHostname = false }
        let out = await ssh("sudo hostnamectl set-hostname '\(newHostname)' 2>&1 && echo 'OK' || echo 'FAIL'")
        if out.contains("OK") {
            hostname = newHostname; isEditingHostname = false
            hostnameMsg = ("Hostname changed", true)
        } else { hostnameMsg = ("Failed", false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.hostnameMsg = nil }
    }
    
    func changeTimezone() async {
        guard !selectedTimezone.isEmpty, selectedTimezone != currentTimezone else { return }
        isChangingTimezone = true; defer { isChangingTimezone = false }
        let _ = await ssh("sudo timedatectl set-timezone '\(selectedTimezone)' 2>&1")
        currentTimezone = selectedTimezone; isEditingTimezone = false
    }
    
    func changeRootPassword() async {
        guard validatePwd(rootNewPwd, rootConfirmPwd, setMsg: { self.rootMsg = $0 }) else { return }
        isChangingRoot = true; defer { isChangingRoot = false }
        let esc = rootNewPwd.replacingOccurrences(of: "'", with: "'\\''")
        let out = await ssh("echo 'root:\(esc)' | sudo chpasswd 2>&1 && echo 'OK' || echo 'FAIL'")
        if out.contains("OK") {
            rootMsg = ("Root password changed", true); rootNewPwd = ""; rootConfirmPwd = ""
        } else { rootMsg = ("Failed: \(out)", false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.rootMsg = nil }
    }
    
    func changeMySQLPassword() async {
        guard validatePwd(mysqlNewPwd, mysqlConfirmPwd, setMsg: { self.mysqlMsg = $0 }) else { return }
        isChangingMySQL = true; defer { isChangingMySQL = false }
        let esc = mysqlNewPwd.replacingOccurrences(of: "'", with: "'\\''")
        let out = await ssh("mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY '\(esc)'; FLUSH PRIVILEGES;\" 2>&1 && echo 'OK' || echo 'FAIL'")
        if out.contains("OK") {
            mysqlMsg = ("MySQL password changed", true); mysqlNewPwd = ""; mysqlConfirmPwd = ""
        } else { mysqlMsg = ("Failed: \(out)", false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.mysqlMsg = nil }
    }
    
    func changePGPassword() async {
        guard validatePwd(pgNewPwd, pgConfirmPwd, setMsg: { self.pgMsg = $0 }) else { return }
        isChangingPG = true; defer { isChangingPG = false }
        let esc = pgNewPwd.replacingOccurrences(of: "'", with: "''")
        let out = await ssh("sudo -u postgres psql -c \"ALTER USER postgres PASSWORD '\(esc)';\" 2>&1 && echo 'OK' || echo 'FAIL'")
        if out.contains("OK") {
            pgMsg = ("PostgreSQL password changed", true); pgNewPwd = ""; pgConfirmPwd = ""
        } else { pgMsg = ("Failed: \(out)", false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.pgMsg = nil }
    }
    
    func saveSSHConfig() async {
        isSavingSSH = true; defer { isSavingSSH = false }
        let rootVal = permitRootLogin ? "yes" : "no"
        let pwdVal = passwordAuthEnabled ? "yes" : "no"
        let out = await ssh("""
        sudo sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin \(rootVal)/' /etc/ssh/sshd_config && \
        sudo sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication \(pwdVal)/' /etc/ssh/sshd_config && \
        sudo systemctl reload sshd 2>/dev/null || sudo systemctl reload ssh 2>/dev/null && echo 'OK' || echo 'FAIL'
        """)
        sshMsg = out.contains("OK") ? ("SSH config saved & reloaded", true) : ("Failed to save", false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.sshMsg = nil }
    }
    
    func addUser() async {
        guard !newUsername.isEmpty, !newUserPassword.isEmpty else { return }
        isAddingUser = true; defer { isAddingUser = false }
        let esc = newUserPassword.replacingOccurrences(of: "'", with: "'\\''")
        let out = await ssh("sudo useradd -m -s /bin/bash '\(newUsername)' 2>&1 && echo '\(newUsername):\(esc)' | sudo chpasswd 2>&1 && echo 'OK' || echo 'FAIL'")
        if out.contains("OK") {
            userMsg = ("User '\(newUsername)' created", true); newUsername = ""; newUserPassword = ""
            await loadUsers()
        } else { userMsg = ("Failed: \(out)", false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.userMsg = nil }
    }
    
    func deleteUser(_ name: String) async {
        let _ = await ssh("sudo userdel -r '\(name)' 2>&1")
        await loadUsers()
    }
    

    
    func toggleService(_ name: String, start: Bool) async {
        let action = start ? "start" : "stop"
        let _ = await ssh("sudo systemctl \(action) \(name).service 2>&1")
        await loadServices()
    }
    
    func restartService(_ name: String) async {
        let _ = await ssh("sudo systemctl restart \(name).service 2>&1")
        await loadServices()
    }
    
    func checkUpdates() async {
        isCheckingUpdates = true; defer { isCheckingUpdates = false }
        let out = await ssh("sudo apt update 2>/dev/null | tail -1 || sudo yum check-update 2>/dev/null | tail -1")
        if let match = out.range(of: #"\d+"#, options: .regularExpression) {
            updatesAvailable = Int(out[match]) ?? 0
        }
    }
    
    func upgradeSystem() async {
        isUpgrading = true; defer { isUpgrading = false }
        let out = await ssh("sudo apt upgrade -y 2>&1 | tail -3 || sudo yum upgrade -y 2>&1 | tail -3")
        updateMessage = (out.isEmpty ? "Upgrade complete" : out, true)
        await checkUpdates()
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { self.updateMessage = nil }
    }
    
    private func validatePwd(_ pwd: String, _ confirm: String, setMsg: @escaping ((String, Bool)?) -> Void) -> Bool {
        guard !pwd.isEmpty, pwd == confirm else {
            setMsg(("Passwords do not match", false))
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { setMsg(nil) }
            return false
        }
        guard pwd.count >= 6 else {
            setMsg(("Minimum 6 characters", false))
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { setMsg(nil) }
            return false
        }
        return true
    }
}

// MARK: - Reusable UI Components

struct SettingsGradientHeader: View {
    let icon: String
    let title: String
    let subtitle: String?
    let gradient: [Color]
    
    init(icon: String, title: String, subtitle: String? = nil, gradient: [Color] = [.axAccentBlue, .axAccentBlue.opacity(0.6)]) {
        self.icon = icon; self.title = title; self.subtitle = subtitle; self.gradient = gradient
    }
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                    .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }
            Spacer()
        }
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    init(icon: String, title: String, value: String, valueColor: Color = .axTextSecondary) {
        self.icon = icon; self.title = title; self.value = value; self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
                .frame(width: 22)
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let tint: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.axTextMuted)
                .frame(width: 22)
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: tint))
                .frame(width: 40)
        }
    }
}

struct SettingsInlineMsg: View {
    let text: String
    let isSuccess: Bool
    
    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 12))
            Text(text)
                .font(AXTypography.caption)
                .lineLimit(2)
        }
        .foregroundColor(isSuccess ? .axSuccess : .axError)
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isSuccess ? Color.axSuccess : Color.axError).opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
}

struct SettingsPasswordRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var newPwd: String
    @Binding var confirmPwd: String
    let isChanging: Bool
    let message: (String, Bool)?
    let action: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axWarning)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(AXTypography.subheadline).fontWeight(.medium).foregroundColor(.axTextPrimary)
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.axTextTertiary)
                }
            }
            
            HStack(spacing: AXSpacing.sm) {
                SecureField("New Password", text: $newPwd)
                    .font(.system(size: 13))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, 6)
                    .background(Color.axBackgroundTertiary)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    .cornerRadius(AXCornerRadius.sm)
                
                SecureField("Confirm", text: $confirmPwd)
                    .font(.system(size: 13))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, 6)
                    .background(Color.axBackgroundTertiary)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                    .cornerRadius(AXCornerRadius.sm)
                
                Button(action: { Task { await action() } }) {
                    HStack(spacing: 4) {
                        if isChanging { ProgressView().scaleEffect(0.6) }
                        else { Image(systemName: "lock.rotation").font(.system(size: 11)) }
                        Text("Change").font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, 6)
                    .background(LinearGradient(colors: [.axWarning, .axWarning.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isChanging || newPwd.isEmpty || confirmPwd.isEmpty)
            }
            
            if let msg = message {
                SettingsInlineMsg(text: msg.0, isSuccess: msg.1)
            }
        }
    }
}

struct DiskUsageBar: View {
    let percent: Int
    
    var barColor: Color {
        if percent >= 90 { return .axError }
        if percent >= 70 { return .axWarning }
        return .axAccentGreen
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.axBackgroundTertiary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [barColor, barColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(percent) / 100)
            }
        }
        .frame(height: 6)
    }
}

struct SettingsLoadingPlaceholder: View {
    let text: String
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            ProgressView().scaleEffect(0.7)
            Text(text).font(AXTypography.caption).foregroundColor(.axTextTertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.lg)
    }
}
