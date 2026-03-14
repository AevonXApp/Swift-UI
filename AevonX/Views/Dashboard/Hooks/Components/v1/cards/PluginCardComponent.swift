//
//  PluginCardComponent.swift
//  AevonX
//
//  Renders a plugin-defined card with title, description, icon, and action/info content.
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

// MARK: - Plugin Card Component

public struct PluginCardComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var hasLoaded = false

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    if let desc = plugin.description {
                        Text(desc)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            if let output = vm.resultOutput, !output.isEmpty {
                parsedContent(output)
            } else if vm.isLoading && !hasLoaded {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                        .scaleEffect(0.6)
                    Text("Loading…")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }

            if let error = vm.errorMessage {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axError)
                        .lineLimit(2)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .task {
            if !hasLoaded, let command = plugin.command {
                await vm.execute(
                    command: command,
                    pluginId: plugin.id,
                    serverId: serverId,
                    context: context
                )
                hasLoaded = true
            }
        }
    }

    // MARK: - Parsed Content

    @ViewBuilder
    private func parsedContent(_ output: String) -> some View {
        if let data = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let configInfo = json["config_info"] as? [String: Any] {
                configInfoView(configInfo)
            } else {
                keyValueView(json)
            }
        } else {
            Text(output.prefix(200))
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .lineLimit(4)
        }
    }

    private func configInfoView(_ info: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            if let version = info["version"] as? String {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text("v\(version)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                }
            }

            if let copyright = info["copyright"] as? String {
                Text(copyright.replacingOccurrences(of: "{YEAR}", with: "\(Calendar.current.component(.year, from: Date()))"))
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            let linkKeys: [(key: String, label: String, icon: String)] = [
                ("docs_url", "Documentation", "book.fill"),
                ("github_url", "Source Code", "chevron.left.forwardslash.chevron.right"),
                ("feedback_url", "Report Issue", "exclamationmark.bubble.fill"),
                ("discord_url", "Community", "bubble.left.and.bubble.right.fill"),
                ("website_url", "Website", "globe"),
            ]

            let availableLinks = linkKeys.filter { info[$0.key] as? String != nil }
            if !availableLinks.isEmpty {
                Divider().opacity(0.3)
                ForEach(availableLinks, id: \.key) { link in
                    if let url = info[link.key] as? String, let linkURL = URL(string: url) {
                        Link(destination: linkURL) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: link.icon)
                                    .font(.system(size: 11))
                                    .foregroundColor(.axAccentBlue)
                                    .frame(width: 16)
                                Text(link.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.axAccentBlue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private func keyValueView(_ json: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let sortedKeys = json.keys.sorted().prefix(6)
            ForEach(Array(sortedKeys), id: \.self) { key in
                HStack {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextMuted)
                    Spacer()
                    let val = json[key]
                    Text(stringValue(val))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axBackground.opacity(0.5))
        )
    }

    private func stringValue(_ val: Any?) -> String {
        guard let val = val else { return "—" }
        if val is NSNull { return "—" }
        if let dict = val as? [String: Any] { return "{\(dict.count) items}" }
        if let arr = val as? [Any] { return "[\(arr.count) items]" }
        let str = "\(val)"
        return str.count > 40 ? String(str.prefix(37)) + "…" : str
    }

    private var accentColor: Color {
        switch plugin.style ?? .secondary {
        case .primary:   return .axAccentBlue
        case .danger:    return .axError
        case .warning:   return .axWarning
        case .success:   return .axSuccess
        case .secondary, .ghost: return .axAccentBlue
        }
    }
}
