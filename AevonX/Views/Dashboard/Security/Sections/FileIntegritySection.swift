//
//  FileIntegritySection.swift
//  AevonX
//
//  File integrity monitoring — SUID/SGID and world-writable files.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCoreBridge

private struct FileItem: Identifiable {
    let id: Int
    let path: String
    init(index: Int, path: String) { self.id = index; self.path = path }
}

struct FileIntegritySection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var suidFiles: [String] = []
    @State private var writableFiles: [String] = []
    @State private var selectedTab = 0
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    private var currentFiles: [String] {
        selectedTab == 0 ? suidFiles : writableFiles
    }

    private var filteredFiles: [String] {
        if searchText.isEmpty { return currentFiles }
        return currentFiles.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

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

                // Search
                AXSearchBar(text: $searchText, placeholder: "Search file paths…")

                // Content
                AXDataTable(
                    title: selectedTab == 0 ? "SUID/SGID Files" : "World-Writable Files",
                    icon: selectedTab == 0 ? "lock.open.fill" : "pencil.circle.fill",
                    iconColor: selectedTab == 0 ? .axWarning : .axError,
                    accentColor: selectedTab == 0 ? .axWarning : .axError,
                    badgeText: "\(currentFiles.count) files",
                    columns: [
                        AXDataColumn(title: "File Path", width: nil),
                    ],
                    items: filteredFiles.enumerated().map { FileItem(index: $0.offset, path: $0.element) },
                    totalCount: currentFiles.count,
                    isLoading: isLoading,
                    emptyIcon: "checkmark.shield.fill",
                    emptyTitle: "No suspicious files found"
                ) { file, _ in
                    Text(file.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } trailingContent: {
                    AXRefreshButton(isLoading: isLoading) {
                        Task { await loadData() }
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
