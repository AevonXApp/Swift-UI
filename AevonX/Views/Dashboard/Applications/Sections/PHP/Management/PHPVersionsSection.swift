//
//  PHPVersionsSection.swift
//  AevonX
//
//  Installed & available PHP versions — install goes through Quick Install
//  (nohup + polling + real progress). Uninstall & set-default are direct SSH.
//

import SwiftUI
import AevonXCoreBridge

struct PHPVersionsSection: View {
    let serverId: String
    let installedVersions: [BridgeAppVersion]
    let availableVersions: [BridgeAppVersion]
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    var onRefresh: () async -> Void

    @State private var actionInProgress: String?
    @State private var confirmUninstall: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Installed
                AXSectionTitle(title: "Installed Versions", icon: "checkmark.circle.fill")
                if installedVersions.isEmpty {
                    emptyState("No PHP versions installed", icon: "folder")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        ForEach(installedVersions, id: \.version) { v in
                            installedCard(v)
                        }
                    }
                }

                // Available
                AXSectionTitle(title: "Available Versions", icon: "shippingbox.fill")
                let filteredAvailable = availableVersions.filter { av in
                    !installedVersions.contains(where: { $0.version == av.version })
                }
                if filteredAvailable.isEmpty {
                    emptyState("All available versions are installed", icon: "checkmark.seal")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        ForEach(filteredAvailable, id: \.version) { v in
                            availableCard(v)
                        }
                    }
                }

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .overlay {
            if let version = confirmUninstall {
                AXConfirmationDialog(
                    title: "Uninstall PHP \(version)?",
                    message: "This will remove PHP \(version)-fpm, CLI, and all associated modules.",
                    icon: "trash",
                    iconColor: .axError,
                    actionTitle: "Uninstall",
                    actionColor: .axError,
                    note: "This action cannot be undone.",
                    onConfirm: {
                        confirmUninstall = nil
                        Task { await uninstallVersion(version) }
                    },
                    onCancel: { confirmUninstall = nil }
                )
            }
        }
    }

    // MARK: - Installed Version Card

    private func installedCard(_ v: BridgeAppVersion) -> some View {
        let cleanVer = cleanVersionString(v.version)
        let isActive = v.channel?.lowercased() == "active"
        let isActioning = actionInProgress == cleanVer

        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text("PHP \(cleanVer)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                if isActive {
                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.axSuccess)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.axSuccess.opacity(0.12))
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 10)).foregroundColor(.axSuccess)
                Text("Installed").font(.system(size: 11)).foregroundColor(.axSuccess)
            }

            Divider().opacity(0.2)

            HStack(spacing: AXSpacing.sm) {
                if !isActive {
                    Button {
                        Task { await setDefault(cleanVer) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").font(.system(size: 9))
                            Text("Set Default").font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(phpPurple)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isActioning || actionInProgress != nil)
                }

                Spacer()

                if !isActive {
                    if isActioning {
                        ProgressView().controlSize(.small)
                    } else {
                        Button {
                            confirmUninstall = cleanVer
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash").font(.system(size: 9))
                                Text("Uninstall").font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.axError)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(actionInProgress != nil)
                    }
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(isActive ? phpPurple.opacity(0.06) : Color.axSurface.opacity(0.6))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(isActive ? phpPurple.opacity(0.3) : Color.axBorder.opacity(0.2), lineWidth: 1))
        .opacity(actionInProgress != nil && !isActioning ? 0.5 : 1)
    }

    // MARK: - Available Version Card

    private func availableCard(_ v: BridgeAppVersion) -> some View {
        let cleanVer = cleanVersionString(v.version)
        let isQIInstalling = connectionViewModel.quickInstallVM?.isInstalling == true

        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text("PHP \(cleanVer)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text(v.channel ?? "")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(channelColor(v.channel ?? ""))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(channelColor(v.channel ?? "").opacity(0.12))
                    .cornerRadius(4)
            }

            Button {
                installViaQuickInstall(version: cleanVer)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill").font(.system(size: 10))
                    Text("Install").font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(phpPurple)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isQIInstalling)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.6))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Install via Quick Install

    private func installViaQuickInstall(version: String) {
        print("[PHP-INSTALL] 🔵 installViaQuickInstall called for version: \(version)")

        // Get or create QuickInstallViewModel
        let qi: QuickInstallViewModel
        if let existing = connectionViewModel.quickInstallVM {
            print("[PHP-INSTALL] ♻️ Reusing existing QuickInstallViewModel (isInstalling: \(existing.isInstalling))")
            qi = existing
        } else {
            print("[PHP-INSTALL] 🆕 Creating new QuickInstallViewModel (serverProfile: \(connectionViewModel.serverProfile?.distro.rawValue ?? "nil"))")
            qi = QuickInstallViewModel(serverId: serverId, profile: connectionViewModel.serverProfile)
            connectionViewModel.quickInstallVM = qi
        }

        // Log catalog info
        print("[PHP-INSTALL] 📦 QI catalog has \(qi.bridgePackages.count) packages")
        for pkg in qi.bridgePackages {
            print("[PHP-INSTALL]   - \(pkg.id): \(pkg.name) (\(pkg.versions.count) versions)")
        }

        // Find PHP package in QI catalog
        guard let phpPkg = qi.bridgePackages.first(where: { $0.id == "php" }) else {
            print("[PHP-INSTALL] ❌ PHP package NOT FOUND in QI catalog!")
            toast.showError("PHP package not found in Quick Install catalog")
            return
        }

        print("[PHP-INSTALL] ✅ Found PHP package: \(phpPkg.name), versions: \(phpPkg.versions.map { "\($0.id)(\($0.label))" }.joined(separator: ", "))")

        // Find matching version
        let matchedVersion = phpPkg.versions.first(where: {
            $0.id.contains(version) || $0.label.contains(version)
        })
        let versionId = matchedVersion?.id ?? version
        print("[PHP-INSTALL] 🎯 Version match: requested=\(version), matched=\(matchedVersion?.id ?? "NONE"), using versionId=\(versionId)")

        // Set selection
        let selection = BridgeQISelection(
            package_id: "php",
            package_name: "PHP",
            version_id: versionId,
            version_label: version
        )
        qi.selections = [selection]
        print("[PHP-INSTALL] 📋 Selection set: package=\(selection.package_id), version=\(selection.version_id), label=\(selection.version_label)")

        qi.isVisible = true
        qi.isMinimized = false

        Task {
            print("[PHP-INSTALL] 🚀 Calling qi.beginInstallation()...")
            await qi.beginInstallation()
            print("[PHP-INSTALL] ✅ beginInstallation() returned — isComplete: \(qi.isComplete), isFailed: \(qi.isFailed)")
            await onRefresh()
            print("[PHP-INSTALL] 🔄 Versions refreshed after install")
        }
    }

    // MARK: - Direct SSH Actions (fast, no need for nohup)

    private func uninstallVersion(_ version: String) async {
        actionInProgress = version
        toast.showSuccess("Uninstalling PHP \(version)...")
        let json = await bridge.uninstallVersion(serverID: serverId, appID: "php-fpm", version: version)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("PHP \(version) uninstalled")
            await onRefresh()
        } else {
            toast.showError("Failed to uninstall PHP \(version)")
        }
        actionInProgress = nil
    }

    private func setDefault(_ version: String) async {
        actionInProgress = version
        toast.showSuccess("Setting PHP \(version) as default...")
        let json = await bridge.switchVersion(serverID: serverId, appID: "php-fpm", version: version)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("PHP \(version) is now the default")
            await onRefresh()
        } else {
            toast.showError("Failed to set PHP \(version) as default")
        }
        actionInProgress = nil
    }

    // MARK: - Helpers

    private func cleanVersionString(_ raw: String) -> String {
        var s = raw
        for marker in ["===ACTIVE===", "===ACTIVE_MINOR===", "===INSTALLED===", "===MODULES===", "===ZEND==="] {
            s = s.replacingOccurrences(of: marker, with: "")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func channelColor(_ ch: String) -> Color {
        switch ch.lowercased() {
        case "latest": return .purple
        case "stable": return .axSuccess
        case "security": return .orange
        case "eol": return .axError
        case "available": return .blue
        default: return .axTextMuted
        }
    }

    private func emptyState(_ text: String, icon: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.axTextMuted)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.xl)
            Spacer()
        }
    }
}
