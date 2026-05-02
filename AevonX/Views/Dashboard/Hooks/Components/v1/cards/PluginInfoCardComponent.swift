//
//  PluginInfoCardComponent.swift
//  AevonX
//
//  Declarative info_card renderer. Displays a titled card of
//  {icon, label, value} rows. Values can be static (from plugin JSON) or
//  dynamic (resolved from a data_source via dot-path keys).
//

import SwiftUI
import AevonXCoreBridge

public struct PluginInfoCardComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var resolved: [String: String] = [:]
    @State private var hasLoaded = false

    public var body: some View {
        AXGlassCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                header
                if plugin.items?.isEmpty == false || plugin.dataSource != nil {
                    Divider().background(Color.axDivider)
                }
                content
            }
            .padding(AXSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: plugin.id) {
            // Re-fetch whenever the plugin identity changes so cards that
            // carry over into a new tab/sidebar entry don't leak stale
            // `resolved` values from the previous plugin's data_source.
            resolved = [:]
            hasLoaded = true
            await loadIfNeeded()
        }
    }
}

// MARK: - Header

private extension PluginInfoCardComponent {

    var header: some View {
        HStack(spacing: AXSpacing.sm) {
            if let icon = plugin.icon {
                Image(systemName: icon)
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentBlue)
            }
            Text(plugin.titleOverride ?? plugin.label ?? plugin.name)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            if plugin.dataSource != nil {
                Button { Task { await loadIfNeeded(force: true) } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
                .help("Refresh")
            }
        }
    }
}

// MARK: - Content

private extension PluginInfoCardComponent {

    @ViewBuilder
    var content: some View {
        if vm.isLoading && resolved.isEmpty {
            HStack(spacing: AXSpacing.xs) {
                ProgressView().controlSize(.small)
                Text("Loading…")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
        } else if let items = plugin.items, !items.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(items) { item in
                    infoRow(item)
                }
            }
        } else if let err = vm.errorMessage {
            Text(err)
                .font(AXTypography.caption)
                .foregroundColor(.axError)
        } else {
            Text(plugin.description ?? "No items")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
    }

    func infoRow(_ item: HookInfoItem) -> some View {
        HStack(alignment: .center, spacing: AXSpacing.sm) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(resolveColor(item.color))
                    .frame(width: 18)
            }
            if let label = item.label {
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            Spacer()
            valueView(for: item)
        }
    }

    @ViewBuilder
    func valueView(for item: HookInfoItem) -> some View {
        let text = resolvedValue(for: item)
        let color = resolveColor(item.color, fallback: .axTextPrimary)

        switch item.type {
        case .badge:
            Text(text.uppercased())
                .font(AXTypography.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, AXSpacing.xxxs)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
        case .status:
            HStack(spacing: AXSpacing.xxs) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(text)
                    .font(AXTypography.caption)
                    .foregroundColor(color)
            }
        case .boolean:
            let truthy = ["true", "yes", "1", "active", "ok"].contains(text.lowercased())
            Image(systemName: truthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(truthy ? .axAccentGreen : .axTextMuted)
                .font(.system(size: 14))
        default:
            Text(text)
                .font(item.mono == true ? AXTypography.monoSm : AXTypography.body)
                .foregroundColor(color)
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }

    func resolvedValue(for item: HookInfoItem) -> String {
        if let key = item.key, let dyn = resolved[key], !dyn.isEmpty {
            return dyn
        }
        return item.value ?? "—"
    }

    // MARK: - Data loading

    func loadIfNeeded(force: Bool = false) async {
        guard let ds = plugin.dataSource else { return }
        // Build a synthetic command from the data_source so we can reuse
        // the existing dispatcher's validation + SSH plumbing. No rows path —
        // the whole JSON is the payload we'll flatten into a key map.
        let command = HookPluginCommand(
            type: ds.type ?? .coreCmd,
            action: ds.action,
            payload: ds.payload
        )
        await vm.execute(
            command: command,
            pluginId: plugin.id,
            serverId: serverId,
            context: context,
            namespace: plugin.namespace
        )
        if let output = vm.resultOutput,
           let data = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) {
            resolved = Self.flatten(json: json)
        }
    }

    /// Flattens a nested JSON tree into a dot-path → string map so items
    /// can reference values via simple keys ("tpm.device", "kek.mode").
    static func flatten(json: Any, prefix: String = "") -> [String: String] {
        var out: [String: String] = [:]
        if let dict = json as? [String: Any] {
            for (k, v) in dict {
                let path = prefix.isEmpty ? k : "\(prefix).\(k)"
                if v is [String: Any] || v is [Any] {
                    out.merge(flatten(json: v, prefix: path)) { a, _ in a }
                } else {
                    out[path] = stringify(v)
                }
            }
        } else if let array = json as? [Any] {
            for (i, v) in array.enumerated() {
                let path = "\(prefix)[\(i)]"
                out.merge(flatten(json: v, prefix: path)) { a, _ in a }
            }
        } else {
            out[prefix] = stringify(json)
        }
        return out
    }

    static func stringify(_ v: Any) -> String {
        if let b = v as? Bool { return b ? "true" : "false" }
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        if v is NSNull { return "" }
        return "\(v)"
    }

    // MARK: - Color resolution

    func resolveColor(_ token: String?, fallback: Color = .axTextPrimary) -> Color {
        switch token {
        case "accent_blue", "accentBlue", "blue":       return .axAccentBlue
        case "accent_green", "accentGreen", "green":    return .axAccentGreen
        case "accent_purple", "accentPurple", "purple": return .axAccentPurple
        case "warning", "orange":                       return .axWarning
        case "error", "red":                            return .axError
        case "text_muted", "textMuted", "muted":        return .axTextMuted
        case "text_secondary", "textSecondary":         return .axTextSecondary
        case "text_primary", "textPrimary":             return .axTextPrimary
        case "cyan":                                    return .cyan
        case "teal":                                    return .teal
        case "indigo":                                  return .indigo
        case "pink":                                    return .pink
        case "yellow":                                  return .yellow
        // ── Vault / treasury palette ──────────────────────────────────────
        // Warm amber→gold→rose gradient with ivory neutral. Lets a plugin
        // present a distinct identity (AXVault first) using semantic
        // names rather than raw hex — and distinguish itself from the
        // app's blue/green/purple core palette.
        case "amber":                                   return Color(red: 245/255, green: 158/255, blue:  11/255)
        case "gold":                                    return Color(red: 234/255, green: 179/255, blue:   8/255)
        case "rose":                                    return Color(red: 225/255, green:  29/255, blue:  72/255)
        case "ivory":                                   return Color(red: 244/255, green: 233/255, blue: 216/255)
        case "copper":                                  return Color(red: 184/255, green:  83/255, blue:  13/255)
        case "bronze":                                  return Color(red: 146/255, green:  64/255, blue:  14/255)
        case nil, "":                                   return fallback
        default:                                        return fallback
        }
    }
}
