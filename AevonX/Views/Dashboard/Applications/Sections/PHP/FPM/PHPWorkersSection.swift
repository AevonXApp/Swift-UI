//
//  PHPWorkersSection.swift
//  AevonX
//
//  FPM worker processes.
//

import SwiftUI
import AevonXCoreBridge

struct PHPWorkersSection: View {
    let serverId: String
    @State private var workers: [BridgeWorkerInfo] = []
    @State private var isLoading = true

    private let bridge = ApplicationBridge.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "FPM Workers", icon: "person.3.fill")
                if isLoading {
                    VStack(spacing: AXSpacing.md) {
                        ForEach(0..<4, id: \.self) { _ in AXSkeletonRow() }
                    }
                } else if workers.isEmpty {
                    emptyWorkers
                } else {
                    ForEach(workers, id: \.pid) { w in workerRow(w) }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadWorkers() }
    }

    private var emptyWorkers: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "person.3.fill").font(.system(size: 28)).foregroundColor(.axTextMuted)
            Text(L10n.Apps.noActiveWorkers).font(AXTypography.body).foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xxl)
    }

    private func workerRow(_ w: BridgeWorkerInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "gearshape.fill").font(.system(size: 12)).foregroundColor(phpPurple)
            VStack(alignment: .leading, spacing: 2) {
                Text("PID \(w.pid)").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.axTextPrimary)
                Text(w.state).font(.system(size: 10)).foregroundColor(.axTextMuted)
            }
            Spacer()
            Text(String(format: "%.1f MB", w.memoryMB)).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
            Text(String(format: "%.1f%%", w.cpuPercent)).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func loadWorkers() async {
        let json = await bridge.getWorkers(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeWorkerInfo]>.self, from: data),
           r.success { workers = r.data ?? [] }
        isLoading = false
    }
}
