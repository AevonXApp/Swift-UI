//
//  PHPComposerSection.swift
//  AevonX
//
//  Dependency audit & security scan.
//

import SwiftUI
import AevonXCoreBridge

struct PHPComposerSection: View {
    let serverId: String
    @State private var isLoading = true
    @State private var isInstalled = false
    @State private var version = ""
    @State private var isInstalling = false
    @State private var isAuditing = false
    @State private var auditResult = ""
    @State private var globalPackages: [[String: String]] = []

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Composer Manager", icon: "shippingbox.circle.fill")

                if isLoading {
                    VStack(spacing: AXSpacing.md) {
                        AXSkeletonStatCard()
                        ForEach(0..<3, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                } else {
                    HStack(spacing: AXSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(isInstalled ? phpPurple.opacity(0.15) : Color.axSurface)
                                .frame(width: 50, height: 50)
                            Image(systemName: isInstalled ? "shippingbox.circle.fill" : "shippingbox.circle")
                                .font(.system(size: 22))
                                .foregroundColor(isInstalled ? phpPurple : .axTextMuted)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(isInstalled ? "Composer v\(version)" : "Composer Not Installed")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.axTextPrimary)
                            Text(isInstalled ? "Dependency management for PHP" : "Click Install to set up Composer automatically")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.4))
                    .cornerRadius(AXCornerRadius.lg)

                    if isInstalled {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            AXSectionTitle(title: "Security Audit", icon: "shield.lefthalf.filled")
                            Text(L10n.Apps.runComposerAuditToCheckForKnownVulnerabilitiesInYourDependencies)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)

                            Button {
                                Task { await runAudit() }
                            } label: {
                                HStack {
                                    if isAuditing { ProgressView().scaleEffect(0.65).frame(width: 14, height: 14) }
                                    else { Image(systemName: "shield.lefthalf.filled") }
                                    Text(L10n.Apps.runSecurityAudit)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(AXSpacing.md)
                                .background(phpPurple)
                                .foregroundColor(.white)
                                .cornerRadius(AXCornerRadius.lg)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isAuditing)

                            if !auditResult.isEmpty {
                                Text(auditResult)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextSecondary)
                                    .padding(AXSpacing.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.axSurface.opacity(0.4))
                                    .cornerRadius(AXCornerRadius.md)
                            }
                        }
                        .padding(AXSpacing.lg)
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.lg)

                        if !globalPackages.isEmpty {
                            VStack(alignment: .leading, spacing: AXSpacing.md) {
                                AXSectionTitle(title: "Global Packages", icon: "shippingbox.fill")
                                ForEach(globalPackages.indices, id: \.self) { i in
                                    let pkg = globalPackages[i]
                                    HStack {
                                        Text(pkg["name"] ?? "").font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextPrimary)
                                        Spacer()
                                        Text(pkg["version"] ?? "").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(AXSpacing.lg)
                            .background(Color.axSurface.opacity(0.3))
                            .cornerRadius(AXCornerRadius.lg)
                        }
                    } else {
                        Button {
                            Task { await installComposer() }
                        } label: {
                            HStack {
                                if isInstalling { ProgressView().scaleEffect(0.65).frame(width: 14, height: 14) }
                                else { Image(systemName: "arrow.down.circle.fill") }
                                Text(L10n.Apps.installComposer).font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AXSpacing.lg)
                            .background(phpPurple)
                            .foregroundColor(.white)
                            .cornerRadius(AXCornerRadius.lg)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isInstalling)
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadComposerInfo() }
    }

    private func loadComposerInfo() async {
        isLoading = true
        let json = await bridge.getComposerInfo(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {
            isInstalled = info["installed"] as? Bool ?? false
            version = info["version"] as? String ?? ""
        }
        isLoading = false
    }

    private func installComposer() async {
        isInstalling = true
        let json = await bridge.installComposer(serverID: serverId, appID: "php-fpm")
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("Composer installed successfully")
            await loadComposerInfo()
        } else {
            toast.showError("Failed to install Composer")
        }
        isInstalling = false
    }

    private func runAudit() async {
        isAuditing = true
        let json = await bridge.composerAudit(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            if let result = (resp["data"] as? [String: Any])?["output"] as? String {
                auditResult = result
            } else {
                auditResult = "No vulnerabilities found ✅"
            }
            toast.showSuccess("Security audit completed")
        } else {
            toast.showError("Audit failed")
        }
        isAuditing = false
    }
}
