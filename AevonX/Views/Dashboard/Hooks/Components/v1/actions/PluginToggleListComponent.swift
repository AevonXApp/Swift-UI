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
    @State private var loadError: String?
    @State private var executingToggles: Set<String> = []

    struct ToggleItem: Identifiable {
        let id = UUID()
        let key: String
        let label: String
        let description: String?
        var isEnabled: Bool
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider().opacity(0.3)
            contentArea
        }
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .task { await loadItems() }
    }

    // MARK: - Header

    @ViewBuilder private var headerRow: some View {
        HStack(spacing: AXSpacing.sm) {
            if let icon = plugin.icon {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.12)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.axAccentBlue)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                if let desc = plugin.description {
                    Text(desc).font(.system(size: 11)).foregroundColor(.axTextSecondary)
                }
            }
            Spacer()
            if isLoaded && loadError == nil {
                Text("\(items.filter(\.isEnabled).count)/\(items.count)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
            }
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Content

    @ViewBuilder private var contentArea: some View {
        if isLoaded {
            if let error = loadError {
                errorState(error)
            } else if items.isEmpty {
                Text("No items").font(.system(size: 12)).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity).padding(AXSpacing.lg)
            } else {
                itemsList
            }
        } else {
            HStack { Spacer(); ProgressView().padding(); Spacer() }
        }
    }

    @ViewBuilder private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: AXSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextPrimary)
                            if let desc = item.description {
                                Text(desc).font(.system(size: 10)).foregroundColor(.axTextMuted)
                            }
                        }
                        Spacer()
                        if executingToggles.contains(item.key) {
                            ProgressView().scaleEffect(0.6).frame(width: 40)
                        } else {
                            Toggle("", isOn: Binding(
                                get: { items[index].isEnabled },
                                set: { newValue in
                                    let oldValue = items[index].isEnabled
                                    items[index].isEnabled = newValue
                                    executingToggles.insert(item.key)
                                    Task {
                                        let success = await performToggle(key: item.key, enabled: newValue)
                                        if !success { items[index].isEnabled = oldValue }
                                        executingToggles.remove(item.key)
                                    }
                                }
                            ))
                            .toggleStyle(.switch).labelsHidden().tint(.axAccentBlue)
                        }
                    }
                    .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.sm)
                    if index < items.count - 1 {
                        Divider().opacity(0.2).padding(.leading, AXSpacing.lg)
                    }
                }
            }
        }
    }

    @ViewBuilder private func errorState(_ error: String) -> some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 20)).foregroundColor(.axError)
            Text(error).font(.system(size: 11)).foregroundColor(.axTextSecondary).multilineTextAlignment(.center)
            Button("Retry") { Task { isLoaded = false; loadError = nil; await loadItems() } }
                .buttonStyle(.plain).font(.system(size: 11, weight: .semibold)).foregroundColor(.axAccentBlue)
        }
        .frame(maxWidth: .infinity).padding(AXSpacing.lg)
    }

    // MARK: - Data Loading

    private func loadItems() async {
        guard let ds = plugin.dataSource else { isLoaded = true; return }
        let cmd = HookPluginCommand(type: ds.type ?? .coreCmd, action: ds.action, payload: ds.payload)
        await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)

        if vm.isSuccess,
           let output = vm.resultOutput,
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
            loadError = nil
        } else {
            loadError = vm.errorMessage ?? "Failed to load items"
        }
        isLoaded = true
    }

    private func performToggle(key: String, enabled: Bool) async -> Bool {
        guard let command = plugin.command else {
            HookToastManager.shared.error("No command configured for toggle")
            return false
        }
        let payload: [String: AnyCodable] = ["key": AnyCodable(key), "enabled": AnyCodable(enabled)]
        let cmd = HookPluginCommand(type: command.type, action: command.action, payload: payload)
        await vm.execute(command: cmd, pluginId: plugin.id, serverId: serverId, context: context, namespace: plugin.namespace)
        if vm.isSuccess {
            let msg = command.onSuccess ?? "\(key) \(enabled ? "enabled" : "disabled")"
            HookToastManager.shared.success(msg)
            return true
        } else {
            let error = vm.errorMessage ?? "Toggle failed"
            HookToastManager.shared.error(command.onError ?? error)
            return false
        }
    }
}
