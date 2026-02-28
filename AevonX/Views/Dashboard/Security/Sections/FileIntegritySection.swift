//
//  FileIntegritySection.swift
//  AevonX
//
//  File integrity monitoring — SUID/SGID and world-writable files.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

struct FileIntegritySection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var suidFiles: [String] = []
    @State private var writableFiles: [String] = []
    @State private var selectedTab = 0

    private let securityManager = SecurityManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Stats
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(icon: "lock.open.fill", label: "SUID/SGID Files", value: "\(suidFiles.count)", color: .axWarning)
                    AXStatCard(icon: "pencil.circle.fill", label: "World-Writable", value: "\(writableFiles.count)", color: .axError)
                    Spacer()
                }

                // Tabs
                AXTabSwitcher(
                    labels: ["SUID/SGID Files", "World-Writable Files"],
                    selected: $selectedTab
                )

                // Content
                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            AXSectionTitle(
                                title: selectedTab == 0 ? "SUID/SGID Files" : "World-Writable Files",
                                icon: selectedTab == 0 ? "lock.open.fill" : "pencil.circle.fill",
                                iconColor: selectedTab == 0 ? .axWarning : .axError
                            )
                            AXRefreshButton(isLoading: isLoading) {
                                Task { await loadData() }
                            }
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)

                        Divider().background(Color.axBorder)

                        let currentFiles = selectedTab == 0 ? suidFiles : writableFiles

                        if isLoading {
                            AXLoadingState(message: "Scanning file system…", style: .inline)
                        } else if currentFiles.isEmpty {
                            AXPlaceholder(
                                icon: "checkmark.shield.fill",
                                title: "No suspicious files found"
                            )
                        } else {
                            ForEach(Array(currentFiles.enumerated()), id: \.offset) { index, file in
                                Text(file)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, AXSpacing.lg)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadData() }
    }



    // MARK: - Data (from Core)

    private func loadData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        async let suid = securityManager.scanSUIDFiles(serverId: serverId)
        async let writable = securityManager.scanWorldWritableFiles(serverId: serverId)

        let (s, w) = await (suid, writable)
        await MainActor.run {
            suidFiles = s
            writableFiles = w
        }
    }
}
