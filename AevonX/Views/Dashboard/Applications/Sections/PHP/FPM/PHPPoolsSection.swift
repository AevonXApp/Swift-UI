//
//  PHPPoolsSection.swift
//  AevonX
//
//  FPM pool management & tuning.
//

import SwiftUI
import AevonXCoreBridge

struct PHPPoolsSection: View {
    let serverId: String
    @State private var isLoading = true
    @State private var pools: [[String: Any]] = []
    @State private var showCreateSheet = false
    @State private var isCreating = false

    @State private var newPoolName = ""
    @State private var newPoolPM = "dynamic"
    @State private var newPoolMaxChildren = "5"
    @State private var newPoolUser = "www-data"

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack {
                    AXSectionTitle(title: "FPM Pool Manager", icon: "square.stack.3d.up.fill")
                    Spacer()
                    Button {
                        showCreateSheet = true
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus.circle.fill")
                            Text(L10n.Apps.newPool).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md).padding(.vertical, 7)
                        .background(phpPurple)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if isLoading {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
                    }
                } else if pools.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        ForEach(pools.indices, id: \.self) { i in poolCard(pools[i]) }
                    }
                }

                poolCalculator
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .sheet(isPresented: $showCreateSheet) { createPoolSheet }
        .task { await loadPools() }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "square.stack.3d.up.fill").font(.system(size: 36)).foregroundColor(phpPurple.opacity(0.3))
            Text(L10n.Apps.noPoolsFound).font(AXTypography.body).foregroundColor(.axTextMuted)
            Text(L10n.Apps.fpmPoolsManageSeparateWorkerGroupsForDifferentApps)
                .font(AXTypography.caption).foregroundColor(.axTextTertiary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xxl)
    }

    private func poolCard(_ pool: [String: Any]) -> some View {
        let name = pool["name"] as? String ?? "unknown"
        let pm = pool["pm"] as? String ?? "dynamic"
        let maxChildren = pool["max_children"] as? Int ?? 0
        let listen = pool["listen"] as? String ?? ""
        let enabled = pool["enabled"] as? Bool ?? true
        let configPath = pool["config_path"] as? String ?? ""

        return VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text(name).font(.system(size: 15, weight: .bold)).foregroundColor(.axTextPrimary)
                Spacer()
                Text(enabled ? L10n.Status.active : L10n.Status.disabled)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(enabled ? .axSuccess : .axTextMuted)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background((enabled ? Color.axSuccess : .gray).opacity(0.12))
                    .cornerRadius(4)
            }
            VStack(alignment: .leading, spacing: 4) {
                poolDetail(icon: "gear", label: "PM Mode", value: pm)
                poolDetail(icon: "person.3.fill", label: "Max Workers", value: "\(maxChildren)")
                poolDetail(icon: "network", label: "Listen", value: listen)
            }
            HStack(spacing: AXSpacing.sm) {
                Button {
                    Task { await togglePool(configPath: configPath, enabled: enabled) }
                } label: {
                    Text(enabled ? "Disable" : "Enable")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(enabled ? .orange : .axSuccess)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background((enabled ? Color.orange : .axSuccess).opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
                if name != "www" {
                    Button {
                        Task { await deletePool(configPath: configPath) }
                    } label: {
                        Image(systemName: "trash").font(.system(size: 10)).foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    private func poolDetail(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(.axTextMuted).frame(width: 14)
            Text(label).font(.system(size: 11)).foregroundColor(.axTextMuted)
            Spacer()
            Text(value).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
        }
    }

    private var poolCalculator: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Pool Calculator", icon: "function")
            Text(L10n.Apps.optimalPmMaxChildrenTotalRamReservedAvgProcessMemory)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .padding(AXSpacing.md)
                .background(Color.axSurface.opacity(0.4))
                .cornerRadius(AXCornerRadius.md)
        }
    }

    private var createPoolSheet: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            Text(L10n.Apps.createFpmPool).font(.system(size: 16, weight: .bold)).foregroundColor(.axTextPrimary)
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sheetField(label: "Pool Name", text: $newPoolName, placeholder: "my_app")
                sheetField(label: "User", text: $newPoolUser, placeholder: "www-data")
                HStack {
                    Text(L10n.Apps.pmMode).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextSecondary)
                    Spacer()
                    Picker("", selection: $newPoolPM) {
                        Text("dynamic").tag("dynamic")
                        Text("static").tag("static")
                        Text("ondemand").tag("ondemand")
                    }
                    .frame(width: 150)
                }
                sheetField(label: "Max Children", text: $newPoolMaxChildren, placeholder: "5")
            }
            HStack {
                Button(L10n.Button.cancel) { showCreateSheet = false }.buttonStyle(PlainButtonStyle())
                Spacer()
                Button {
                    Task { await createPool() }
                } label: {
                    HStack {
                        if isCreating { ProgressView().scaleEffect(0.6) }
                        Text(L10n.Button.create).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg).padding(.vertical, 8)
                    .background(phpPurple)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(newPoolName.isEmpty || isCreating)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400)
        .background(Color.axBackground)
    }

    private func sheetField(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextSecondary).frame(width: 100, alignment: .leading)
            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, 6)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Pool Actions

    private func loadPools() async {
        isLoading = true
        let json = await bridge.listPools(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let list = resp["data"] as? [[String: Any]] {
            pools = list
        }
        isLoading = false
    }

    private func createPool() async {
        isCreating = true
        let config: [String: String] = [
            "name": newPoolName, "user": newPoolUser, "group": newPoolUser,
            "pm": newPoolPM, "max_children": newPoolMaxChildren,
            "listen": "/run/php/php-fpm-\(newPoolName).sock",
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: config),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            let result = await bridge.createPool(serverID: serverId, appID: "php-fpm", configJSON: jsonStr)
            if let d = result.data(using: .utf8),
               let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
               r["success"] as? Bool == true {
                toast.showSuccess("Pool '\(newPoolName)' created")
                showCreateSheet = false
                newPoolName = ""
                await loadPools()
            } else {
                toast.showError("Failed to create pool")
            }
        }
        isCreating = false
    }

    private func deletePool(configPath: String) async {
        let result = await bridge.deletePool(serverID: serverId, appID: "php-fpm", poolPath: configPath)
        if let d = result.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("Pool deleted")
            await loadPools()
        } else {
            toast.showError("Failed to delete pool")
        }
    }

    private func togglePool(configPath: String, enabled: Bool) async {
        let result: String
        if enabled {
            result = await bridge.disablePool(serverID: serverId, appID: "php-fpm", poolPath: configPath)
        } else {
            result = await bridge.enablePool(serverID: serverId, appID: "php-fpm", poolPath: configPath)
        }
        if let d = result.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess(enabled ? "Pool disabled" : "Pool enabled")
            await loadPools()
        } else {
            toast.showError("Failed to toggle pool")
        }
    }
}
