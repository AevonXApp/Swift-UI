//
//  PHPVersionsSection.swift
//  AevonX
//
//  Installed & available PHP versions management.
//

import SwiftUI
import AevonXCoreBridge

struct PHPVersionsSection: View {
    let serverId: String
    let installedVersions: [BridgeAppVersion]
    let availableVersions: [BridgeAppVersion]
    var onRefresh: () async -> Void

    @State private var installingVersion: String?
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Installed Versions", icon: "checkmark.circle.fill")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    ForEach(installedVersions, id: \.version) { v in
                        versionCard(v, installed: true)
                    }
                }

                AXSectionTitle(title: "Available Versions", icon: "shippingbox.fill")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    ForEach(availableVersions.filter { av in !installedVersions.contains(where: { $0.version == av.version }) }, id: \.version) { v in
                        versionCard(v, installed: false)
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }

    private func versionCard(_ v: BridgeAppVersion, installed: Bool) -> some View {
        let cleanVersion = cleanVersionString(v.version)
        let isThisInstalling = installingVersion == cleanVersion
        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text("PHP \(cleanVersion)")
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
            if installed {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 10)).foregroundColor(.axSuccess)
                    Text("Installed").font(.system(size: 11)).foregroundColor(.axSuccess)
                }
            } else if isThisInstalling {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Installing...").font(.system(size: 11, weight: .semibold)).foregroundColor(.orange)
                }
            } else {
                Button {
                    Task { await installVersion(cleanVersion) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill").font(.system(size: 10))
                        Text("Install").font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(phpPurple)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(installingVersion != nil)
                .opacity(installingVersion != nil ? 0.5 : 1)
            }
        }
        .padding(AXSpacing.lg)
        .background(isThisInstalling ? phpPurple.opacity(0.08) : Color.axSurface.opacity(0.6))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(isThisInstalling ? phpPurple.opacity(0.4) : Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    private func cleanVersionString(_ raw: String) -> String {
        var s = raw
        for marker in ["===ACTIVE===", "===ACTIVE_MINOR===", "===INSTALLED===", "===MODULES===", "===ZEND==="] {
            s = s.replacingOccurrences(of: marker, with: "")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func installVersion(_ version: String) async {
        installingVersion = version
        toast.showSuccess("Installing PHP \(version)... This may take a few minutes.")
        let json = await bridge.installVersion(serverID: serverId, appID: "php-fpm", version: version)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("PHP \(version) installed successfully")
            await onRefresh()
        } else {
            toast.showError("Failed to install PHP \(version)")
        }
        installingVersion = nil
    }

    private func channelColor(_ ch: String) -> Color {
        switch ch.lowercased() {
        case "latest": return .purple
        case "stable": return .axSuccess
        case "security": return .orange
        case "eol": return .axError
        default: return .axTextMuted
        }
    }
}
