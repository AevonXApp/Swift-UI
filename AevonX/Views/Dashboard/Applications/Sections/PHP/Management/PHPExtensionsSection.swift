//
//  PHPExtensionsSection.swift
//  AevonX
//
//  aaPanel-style PHP extension manager — shows catalog with
//  install/uninstall, type, description, and live status.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Catalog Model

private struct ExtCatalogEntry: Codable, Identifiable {
    let name: String
    let type: String
    let description: String
    var id: String { name }
}

// MARK: - View

struct PHPExtensionsSection: View {
    let serverId: String
    let modules: [BridgeModuleInfo]
    var onRefresh: () async -> Void

    @State private var search = ""
    @State private var catalog: [ExtCatalogEntry] = []
    @State private var actionInProgress: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    // MARK: - Computed

    private var loadedNames: Set<String> {
        Set(modules.map { $0.name.lowercased() })
    }

    private var displayItems: [ExtCatalogEntry] {
        let items = catalog.isEmpty ? catalogFromModules : mergedCatalog
        guard !search.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.type.localizedCaseInsensitiveContains(search) ||
            $0.description.localizedCaseInsensitiveContains(search)
        }
    }

    /// Merge catalog with actual loaded modules (catalog first, then extras)
    private var mergedCatalog: [ExtCatalogEntry] {
        var items = catalog
        let catalogNames = Set(catalog.map { $0.name.lowercased() })
        for mod in modules {
            if !catalogNames.contains(mod.name.lowercased()) {
                items.append(ExtCatalogEntry(
                    name: mod.name, type: "Loaded", description: ""
                ))
            }
        }
        return items
    }

    /// Fallback if catalog is empty
    private var catalogFromModules: [ExtCatalogEntry] {
        modules.map { ExtCatalogEntry(name: $0.name, type: "Loaded", description: "") }
    }

    func isInstalled(_ name: String) -> Bool {
        loadedNames.contains(name.lowercased())
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass").foregroundColor(.axTextMuted)
                TextField("Search extensions...", text: $search)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                Spacer()
                Text("\(modules.count) loaded")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            // Table header
            tableHeader

            Divider().opacity(0.3)

            // Table body
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(displayItems) { item in
                        extensionRow(item)
                        Divider().opacity(0.15)
                    }
                }
            }
        }
        .onAppear { loadCatalog() }
    }

    // MARK: - Table Header

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(width: 140, alignment: .leading)
            Text("Type")
                .frame(width: 120, alignment: .leading)
            Text("Description")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Status")
                .frame(width: 70, alignment: .center)
            Text("Action")
                .frame(width: 90, alignment: .center)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.axTextSecondary)
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.4))
    }

    // MARK: - Extension Row

    private func extensionRow(_ item: ExtCatalogEntry) -> some View {
        let installed = isInstalled(item.name)
        let isActioning = actionInProgress == item.name

        return HStack(spacing: 0) {
            // Name
            Text(item.name)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 140, alignment: .leading)

            // Type
            Text(item.type)
                .font(.system(size: 11))
                .foregroundColor(typeColor(item.type))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(typeColor(item.type).opacity(0.1))
                .cornerRadius(4)
                .frame(width: 120, alignment: .leading)

            // Description
            Text(item.description.isEmpty ? "—" : item.description)
                .font(.system(size: 11))
                .foregroundColor(.axTextSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Status icon
            Group {
                if installed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.axSuccess)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.axTextMuted)
                }
            }
            .frame(width: 70, alignment: .center)

            // Action button
            Group {
                if isActioning {
                    ProgressView().controlSize(.small)
                } else if installed {
                    Button {
                        Task { await uninstallExt(item.name) }
                    } label: {
                        Text("Uninstall")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(actionInProgress != nil)
                } else {
                    Button {
                        Task { await installExt(item.name) }
                    } label: {
                        Text("Install")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(actionInProgress != nil)
                }
            }
            .frame(width: 90, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(isActioning ? Color.axAccentBlue.opacity(0.04) : Color.clear)
        .opacity(actionInProgress != nil && !isActioning ? 0.5 : 1)
    }

    // MARK: - Actions

    private func installExt(_ name: String) async {
        actionInProgress = name
        toast.showSuccess("Installing \(name)...")
        let json = await bridge.installExtension(serverID: serverId, appID: "php-fpm", name: name)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("\(name) installed — reloading PHP-FPM")
            await onRefresh()
        } else {
            toast.showError("Failed to install \(name)")
        }
        actionInProgress = nil
    }

    private func uninstallExt(_ name: String) async {
        actionInProgress = name
        toast.showSuccess("Uninstalling \(name)...")
        let json = await bridge.uninstallExtension(serverID: serverId, appID: "php-fpm", name: name)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("\(name) uninstalled — reloading PHP-FPM")
            await onRefresh()
        } else {
            toast.showError("Failed to uninstall \(name)")
        }
        actionInProgress = nil
    }

    // MARK: - Load Catalog

    private func loadCatalog() {
        let json = bridge.extensionCatalog()
        guard let data = json.data(using: .utf8),
              let resp = try? JSONDecoder().decode(BridgeCatalogResponse.self, from: data),
              let items = resp.data else { return }
        catalog = items
    }

    // MARK: - Helpers

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "Cache": return .orange
        case "Database": return .blue
        case "Network": return .purple
        case "Debugger": return .red
        case "Image Processing": return .green
        case "Encryption": return .yellow
        case "Math": return .cyan
        case "Web Services": return .mint
        case "String": return .teal
        case "General": return .axTextSecondary
        default: return .axTextMuted
        }
    }
}

// MARK: - Bridge Response

private struct BridgeCatalogResponse: Codable {
    let success: Bool
    let data: [ExtCatalogEntry]?
}
