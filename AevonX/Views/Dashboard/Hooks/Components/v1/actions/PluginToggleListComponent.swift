//
//  PluginToggleListComponent.swift
//  AevonX
//
//  Renders a list of items with on/off toggle switches.
//  Each toggle dispatches a command with the item key + state.
//

import SwiftUI
import AevonXCoreBridge

public struct PluginToggleListComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var items: [ToggleItem] = []
    @State private var isLoaded = false

    struct ToggleItem: Identifiable {
        let id = UUID()
        let key: String
        let label: String
        let description: String?
        var isEnabled: Bool
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentBlue.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    if let desc = plugin.description {
                        Text(desc)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
                Text("\(items.filter(\.isEnabled).count)/\(items.count)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
            }
            .padding(AXSpacing.lg)

            Divider().opacity(0.3)

            if isLoaded {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: AXSpacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.axTextPrimary)
                                    if let desc = item.description {
                                        Text(desc)
                                            .font(.system(size: 10))
                                            .foregroundColor(.axTextMuted)
                                    }
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { items[index].isEnabled },
                                    set: { newValue in
                                        items[index].isEnabled = newValue
                                        toggleItem(key: item.key, enabled: newValue)
                                    }
                                ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .tint(.axAccentBlue)
                            }
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)

                            if index < items.count - 1 {
                                Divider().opacity(0.2).padding(.leading, AXSpacing.lg)
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .task { await loadItems() }
    }

    private func loadItems() async {
        guard let ds = plugin.dataSource else { return }
        let cmd = HookPluginCommand(type: ds.type ?? .coreCmd, action: ds.action, payload: ds.payload)
        await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

        if let output = vm.resultOutput,
           let data = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = json[ds.rowsPath ?? "items"] as? [[String: Any]] {
            items = list.map { item in
                ToggleItem(
                    key: item["key"] as? String ?? item["id"] as? String ?? "",
                    label: item["label"] as? String ?? item["name"] as? String ?? "",
                    description: item["description"] as? String,
                    isEnabled: item["enabled"] as? Bool ?? false
                )
            }
        }
        isLoaded = true
    }

    private func toggleItem(key: String, enabled: Bool) {
        guard let command = plugin.command else { return }
        let payload: [String: AnyCodable] = ["key": AnyCodable(key), "enabled": AnyCodable(enabled)]
        let cmd = HookPluginCommand(type: command.type, action: command.action, payload: payload)
        Task {
            await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)
        }
    }
}
