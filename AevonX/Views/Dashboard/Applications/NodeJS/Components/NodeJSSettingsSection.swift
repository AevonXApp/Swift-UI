//
//  NodeJSSettingsSection.swift
//  AevonX
//
//  PM2, Node.js, and NPM configuration settings.
//  Premium design with AX design system components.
//

import SwiftUI
import AevonXCore

struct NodeJSSettingsSection: View {
    let serverId: String

    @State private var npmRegistry = ""
    @State private var maxOldSpaceSize = ""
    @State private var pm2MaxRestarts = "10"
    @State private var pm2RestartDelay = "100"
    @State private var pm2LogRotateInstalled = false
    @State private var pm2StartupConfigured = false
    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if isLoading {
                AXLoadingState(message: "Loading settings…")
            } else {
                npmSettingsCard
                nodeAndPM2SettingsCard
                pm2StatusCard
                pm2ActionsCard
            }
        }
        .task { await loadSettings() }
    }

    // MARK: - NPM Settings

    private var npmSettingsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionHeader(title: "NPM Settings", icon: "shippingbox.fill", color: Color(hex: "#CB3837"))

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Registry URL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextMuted)

                    HStack(spacing: AXSpacing.sm) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "link")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                            TextField("https://registry.npmjs.org/", text: $npmRegistry)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )

                        Button {
                            Task { await setRegistry() }
                        } label: {
                            Text("Save")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(AXCornerRadius.sm)
                                .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Node + PM2 Settings (Combined)

    private var nodeAndPM2SettingsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                sectionHeader(title: "Runtime Configuration", icon: "gearshape.2.fill", color: Color(hex: "#339933"))

                // Node.js Memory
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#339933"))
                        Text("Node.js Memory Limit")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.axTextMuted)
                    }

                    HStack(spacing: AXSpacing.sm) {
                        settingsField(text: $maxOldSpaceSize, placeholder: "4096", width: 100)
                        Text("MB")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.axTextMuted)
                        Text("(--max-old-space-size)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextMuted.opacity(0.6))
                    }
                }

                Divider()
                    .overlay(Color.axBorder.opacity(0.3))

                // PM2 Config
                HStack(spacing: AXSpacing.xl) {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.system(size: 11))
                                .foregroundColor(.axAccentBlue)
                            Text("Max Restarts")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.axTextMuted)
                        }
                        settingsField(text: $pm2MaxRestarts, placeholder: "10", width: 80)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                                .foregroundColor(.axWarning)
                            Text("Restart Delay")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.axTextMuted)
                        }
                        HStack(spacing: 4) {
                            settingsField(text: $pm2RestartDelay, placeholder: "100", width: 80)
                            Text("ms")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }
            }
        }
    }

    // MARK: - PM2 Status

    private var pm2StatusCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionHeader(title: "PM2 Status", icon: "checkmark.circle.fill", color: .axSuccess)

                HStack(spacing: AXSpacing.md) {
                    statusBadge(
                        title: "Log Rotation",
                        icon: "doc.text.fill",
                        isActive: pm2LogRotateInstalled,
                        color: .axAccentBlue
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    statusBadge(
                        title: "Startup Script",
                        icon: "power",
                        isActive: pm2StartupConfigured,
                        color: .axSuccess
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusBadge(title: String, icon: String, isActive: Bool, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? color.opacity(0.15) : Color.axBackground)
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? color.opacity(0.3) : Color.axBorder, lineWidth: 1)
                    )

                Image(systemName: isActive ? icon : "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isActive ? color : .axTextMuted)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                Text(isActive ? "Active" : "Not configured")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isActive ? color : .axTextMuted)
            }
        }
    }

    // MARK: - PM2 Actions

    private var pm2ActionsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionHeader(title: "PM2 Actions", icon: "bolt.fill", color: .axWarning)

                HStack(spacing: AXSpacing.sm) {
                    settingsActionButton(title: "PM2 Startup", icon: "power", color: .axSuccess, desc: "Auto-start on boot") {
                        await configureStartup()
                    }
                    settingsActionButton(title: "Install LogRotate", icon: "arrow.clockwise.circle", color: .axAccentBlue, desc: "Manage log files") {
                        await installLogRotate()
                    }
                    settingsActionButton(title: "PM2 Update", icon: "arrow.up.circle", color: .axWarning, desc: "Update to latest") {
                        await updatePM2()
                    }
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            Text(title)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
        }
    }

    private func settingsField(text: Binding<String>, placeholder: String, width: CGFloat) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 7)
            .frame(width: width)
            .background(Color.axBackground)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
    }

    private func settingsActionButton(title: String, icon: String, color: Color, desc: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadSettings() async {
        isLoading = true
        let ssh = SSHService.shared

        let regResult = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; npm config get registry 2>/dev/null",
            serverId: serverId
        )
        npmRegistry = regResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? "https://registry.npmjs.org/"

        let lrResult = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; pm2 list 2>/dev/null | grep -q 'pm2-logrotate' && echo 'yes' || echo 'no'",
            serverId: serverId
        )
        pm2LogRotateInstalled = lrResult?.stdout.contains("yes") ?? false

        let startupResult = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; pm2 startup 2>&1 | grep -q 'already' && echo 'yes' || echo 'no'",
            serverId: serverId
        )
        pm2StartupConfigured = startupResult?.stdout.contains("yes") ?? false

        isLoading = false
    }

    private func setRegistry() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; npm config set registry \"\(npmRegistry)\"",
            serverId: serverId
        )
        GlobalToastManager.shared.showSuccess("NPM registry updated")
    }

    private func configureStartup() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; pm2 startup 2>&1 && pm2 save 2>&1",
            serverId: serverId
        )
        pm2StartupConfigured = true
        GlobalToastManager.shared.showSuccess("PM2 startup configured")
    }

    private func installLogRotate() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; pm2 install pm2-logrotate 2>&1",
            serverId: serverId
        )
        pm2LogRotateInstalled = true
        GlobalToastManager.shared.showSuccess("LogRotate installed")
    }

    private func updatePM2() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute(
            "source ~/.nvm/nvm.sh 2>/dev/null; npm install -g pm2@latest 2>&1",
            serverId: serverId
        )
        GlobalToastManager.shared.showSuccess("PM2 updated to latest")
    }
}
