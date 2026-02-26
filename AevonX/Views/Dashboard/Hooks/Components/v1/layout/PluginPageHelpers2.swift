//
//  PluginPageHelpers2.swift
//  AevonX
//
//  Additional helper views for PluginPageComponent:
//  DashboardDataTableCard, DashboardChartCard, PluginLayoutCardView, ScanProgressData
//

import SwiftUI
import AevonXCore

// MARK: - Dashboard Data Table Card

struct DashboardDataTableCard: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil
    @State private var refreshID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = card.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.12)).frame(width: 32, height: 32)
                        Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title).font(AXTypography.subheadline).fontWeight(.semibold).foregroundColor(.axTextPrimary)
                    if let desc = card.description { Text(desc).font(AXTypography.caption).foregroundColor(.axTextSecondary) }
                }
                Spacer()
            }.padding(.horizontal, AXSpacing.xxl).padding(.vertical, AXSpacing.md)
            PluginDataTableComponent(plugin: buildPluginDefinition(), serverId: serverId, context: context).id(refreshID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginScanCompleted)) { _ in refreshID = UUID() }
    }

    private func buildPluginDefinition() -> HookPluginDefinition {
        HookPluginDefinition(
            id: "dashboard_table_\(card.title.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: card.title, description: card.description, version: nil, enabled: true,
            hook: .sidebarTabs, component: .dataTable, label: nil, icon: card.icon, style: nil,
            command: nil, layout: nil, dataSource: card.dataSource, columns: card.columns,
            conditions: nil, permissions: nil, confirmationMessage: nil, chartType: nil,
            dependencies: nil, namespace: namespace, fields: nil, onRowTap: nil, batchActions: nil,
            rowActions: card.rowActions, searchable: card.searchable, searchKeys: card.searchKeys
        )
    }
}

// MARK: - Dashboard Chart Card

struct DashboardChartCard: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = card.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.12)).frame(width: 32, height: 32)
                        Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title).font(AXTypography.subheadline).fontWeight(.semibold).foregroundColor(.axTextPrimary)
                    if let desc = card.description { Text(desc).font(AXTypography.caption).foregroundColor(.axTextSecondary) }
                }
                Spacer()
            }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md)
            PluginChartComponent(plugin: buildChartPlugin(), serverId: serverId, context: context).frame(height: 280)
        }
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface)
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
    }

    private func buildChartPlugin() -> HookPluginDefinition {
        HookPluginDefinition(
            id: "dashboard_chart_\(card.title.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: card.title, description: card.description, hook: .sidebarTabs, component: .chart,
            icon: card.icon, dataSource: card.dataSource, columns: card.columns,
            chartType: card.chartType, chartConfig: card.chartConfig, namespace: namespace
        )
    }
}

// MARK: - Layout Card View

struct PluginLayoutCardView: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil
    @StateObject private var vm = HookPluginViewModel()
    @State private var showProgress = false
    @State private var progressData: ScanProgressData?
    @State private var pollingTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                if let icon = card.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axAccentBlue.opacity(0.12)).frame(width: 32, height: 32)
                        Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.axAccentBlue)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title).font(AXTypography.subheadline).fontWeight(.semibold).foregroundColor(.axTextPrimary)
                    if let desc = card.description { Text(desc).font(AXTypography.caption).foregroundColor(.axTextSecondary).lineLimit(2) }
                }
                Spacer()
                if vm.isSuccess { Image(systemName: "checkmark.circle.fill").foregroundColor(.axSuccess).font(.system(size: 14)) }
                if progressData != nil {
                    Button(action: { withAnimation { showProgress.toggle() } }) {
                        Image(systemName: showProgress ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 14)).foregroundColor(.axTextMuted)
                    }.buttonStyle(.plain)
                }
            }
            if showProgress, let progress = progressData {
                scanProgressView(progress).transition(.opacity.combined(with: .move(edge: .top)))
            }
            if !showProgress, let output = vm.resultOutput, !output.isEmpty {
                if let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let configInfo = json["config_info"] as? [String: Any] { cardConfigInfoView(configInfo) }
                    else { cardKeyValueView(json) }
                } else {
                    ScrollView {
                        Text(output).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(maxHeight: 120).padding(AXSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axBackground))
                }
            }
            if let error = vm.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10))
                    Text(error).font(AXTypography.caption2)
                }.foregroundColor(.axError)
            }
            if card.component != .card, let command = card.command {
                Button(action: {
                    Task {
                        await vm.execute(command: command, pluginId: "card_\(card.title)", serverId: serverId, context: context, namespace: namespace)
                        if command.action.contains("scan") {
                            startProgressPolling()
                            Task { try? await Task.sleep(nanoseconds: 4_000_000_000); NotificationCenter.default.post(name: .pluginScanCompleted, object: nil) }
                        }
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue)).scaleEffect(0.65) }
                        else if vm.isSuccess { Image(systemName: "checkmark.circle.fill").foregroundColor(.axSuccess) }
                        else if let icon = card.icon { Image(systemName: icon).font(.system(size: 11)) }
                        Text(vm.isSuccess ? "Done" : "Run").font(AXTypography.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(vm.isSuccess ? .axSuccess : .axAccentBlue).frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(vm.isSuccess ? Color.axSuccess.opacity(0.08) : Color.axAccentBlue.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(vm.isSuccess ? Color.axSuccess.opacity(0.3) : Color.axAccentBlue.opacity(0.25), lineWidth: 1))
                }.buttonStyle(.plain).disabled(vm.isLoading)
            }
        }
        .padding(AXSpacing.lg)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface)
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2))
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.5), lineWidth: 1))
        .onDisappear { pollingTask?.cancel() }
        .task {
            if card.component == .card, let command = card.command {
                await vm.execute(command: command, pluginId: "card_\(card.title)", serverId: serverId, context: context, namespace: namespace)
            }
        }
    }

    @ViewBuilder
    private func cardConfigInfoView(_ info: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            if let version = info["version"] as? String {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "tag.fill").font(.system(size: 10)).foregroundColor(.axTextMuted)
                    Text("v\(version)").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
                }
            }
            if let copyright = info["copyright"] as? String {
                Text(copyright.replacingOccurrences(of: "{YEAR}", with: "\(Calendar.current.component(.year, from: Date()))"))
                    .font(.system(size: 10)).foregroundColor(.axTextMuted)
            }
            let linkKeys: [(key: String, label: String, icon: String)] = [
                ("docs_url", "Documentation", "book.fill"), ("github_url", "Source Code", "chevron.left.forwardslash.chevron.right"),
                ("feedback_url", "Report Issue", "exclamationmark.bubble.fill"), ("discord_url", "Community", "bubble.left.and.bubble.right.fill")
            ]
            let availableLinks = linkKeys.filter { info[$0.key] as? String != nil }
            if !availableLinks.isEmpty {
                Divider().opacity(0.3)
                ForEach(availableLinks, id: \.key) { link in
                    if let url = info[link.key] as? String, let linkURL = URL(string: url) {
                        Link(destination: linkURL) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: link.icon).font(.system(size: 11)).foregroundColor(.axAccentBlue).frame(width: 16)
                                Text(link.label).font(.system(size: 12, weight: .medium)).foregroundColor(.axAccentBlue)
                                Spacer()
                                Image(systemName: "arrow.up.right").font(.system(size: 9)).foregroundColor(.axTextMuted)
                            }.padding(.vertical, 3)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cardKeyValueView(_ json: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let sortedKeys = json.keys.sorted().prefix(8)
            ForEach(Array(sortedKeys), id: \.self) { key in
                HStack {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized).font(.system(size: 11, weight: .medium)).foregroundColor(.axTextMuted)
                    Spacer()
                    Text(cardStringValue(json[key])).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextPrimary).lineLimit(1)
                }
            }
        }.padding(AXSpacing.sm).background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axBackground.opacity(0.5)))
    }

    private func cardStringValue(_ val: Any?) -> String {
        guard let val = val else { return "—" }
        if val is NSNull { return "—" }
        if let dict = val as? [String: Any] { return "{\(dict.count) items}" }
        if let arr = val as? [Any] { return "[\(arr.count) items]" }
        let str = "\(val)"; return str.count > 40 ? String(str.prefix(37)) + "…" : str
    }

    @ViewBuilder
    private func scanProgressView(_ progress: ScanProgressData) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Scanning…").font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextPrimary)
                    Spacer()
                    Text("\(Int(progress.progress))%").font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(progress.status == "done" ? .axSuccess : .axAccentBlue)
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.axBackground).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4).fill(progress.status == "done" ? Color.axSuccess : Color.axAccentBlue)
                            .frame(width: geometry.size.width * CGFloat(progress.progress / 100), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress.progress)
                    }
                }.frame(height: 8)
            }
            HStack(spacing: AXSpacing.lg) {
                statLabel(icon: "doc.fill", value: "\(progress.filesScanned)/\(progress.filesTotal)", label: "Files")
                statLabel(icon: "exclamationmark.triangle.fill", value: "\(progress.findingsSoFar)", label: "Findings")
                if progress.status == "done" { statLabel(icon: "checkmark.circle.fill", value: "Complete", label: "Status") }
            }
            if !progress.currentFile.isEmpty && progress.status != "done" {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill").font(.system(size: 9)).foregroundColor(.axAccentBlue)
                    Text(progress.currentFile.components(separatedBy: "/").suffix(3).joined(separator: "/"))
                        .font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted).lineLimit(1).truncationMode(.middle)
                }
            }
        }.padding(AXSpacing.md).background(RoundedRectangle(cornerRadius: AXCornerRadius.sm).fill(Color.axBackground))
    }

    private func statLabel(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(.axTextMuted)
            Text(value).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
            Text(label).font(.system(size: 10)).foregroundColor(.axTextMuted)
        }
    }

    private func startProgressPolling() {
        showProgress = true; pollingTask?.cancel()
        pollingTask = Task {
            let cmdType: HookCommandType = namespace != nil ? .pluginCmd : .coreCmd
            let actionName = namespace != nil ? "progress" : "phpscan.scan.progress"
            let progressCmd = HookPluginCommand(type: cmdType, action: actionName)
            let progressVM = HookPluginViewModel()
            while !Task.isCancelled {
                let delay: UInt64 = progressData == nil ? 500_000_000 : 2_000_000_000
                try? await Task.sleep(nanoseconds: delay); guard !Task.isCancelled else { break }
                await progressVM.execute(command: progressCmd, pluginId: "progress_poll", serverId: serverId, context: context, namespace: namespace)
                if let output = progressVM.resultOutput, let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        progressData = ScanProgressData(
                            status: json["status"] as? String ?? "idle", progress: json["progress"] as? Double ?? 0,
                            filesTotal: json["files_total"] as? Int ?? 0, filesScanned: json["files_scanned"] as? Int ?? 0,
                            currentFile: json["current_file"] as? String ?? "", findingsSoFar: json["findings_so_far"] as? Int ?? 0
                        )
                    }
                    let status = json["status"] as? String ?? ""
                    if status == "done" || status == "idle" { break }
                }
            }
        }
    }
}

// MARK: - Scan Progress Data

struct ScanProgressData {
    let status: String
    let progress: Double
    let filesTotal: Int
    let filesScanned: Int
    let currentFile: String
    let findingsSoFar: Int
}
