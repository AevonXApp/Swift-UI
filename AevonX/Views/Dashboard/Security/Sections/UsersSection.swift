//
//  UsersSection.swift
//  AevonX
//
//  Users & Permissions section — system user audit.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

private struct IndexedUser: Identifiable {
    let id: Int
    let user: SystemUser
    init(_ i: Int, _ u: SystemUser) { self.id = i; self.user = u }
}

struct UsersSection: View {
    let serverId: String

    @State private var isLoading = true
    @State private var users: [SystemUser] = []
    @State private var searchText = ""

    private let securityManager = SecurityManager.shared

    private var filteredUsers: [SystemUser] {
        if searchText.isEmpty { return users }
        return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Stats
                HStack(spacing: AXSpacing.lg) {
                    AXStatCard(icon: "person.2.fill", label: "Total Users", value: "\(users.count)", color: .axAccentBlue)
                    AXStatCard(icon: "shield.fill", label: "Sudo Users", value: "\(users.filter(\.hasSudo).count)", color: .axWarning)
                    AXStatCard(icon: "terminal.fill", label: "Shell Users", value: "\(users.filter { !$0.shell.contains("nologin") && !$0.shell.contains("false") }.count)", color: .axAccentGreen)
                    Spacer()
                }

                // Search
                AXSearchBar(text: $searchText, placeholder: "Search users…")

                // Users Table
                AXDataTable(
                    title: "System Users",
                    icon: "person.2.fill",
                    accentColor: .axAccentBlue,
                    badgeText: "\(users.count) users",
                    columns: [
                        AXDataColumn(title: "User", width: nil),
                        AXDataColumn(title: "UID", width: 60),
                        AXDataColumn(title: "Shell", width: 120),
                        AXDataColumn(title: "Home", width: 150),
                        AXDataColumn(title: "Sudo", width: 60, alignment: .center),
                    ],
                    items: filteredUsers.enumerated().map { IndexedUser($0.offset, $0.element) },
                    totalCount: users.count,
                    isLoading: isLoading,
                    emptyIcon: "person.slash",
                    emptyTitle: "No users found"
                ) { item, _ in
                    HStack(spacing: 0) {
                        Text(item.user.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(item.user.uid)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 60, alignment: .leading)
                        Text(item.user.shell)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 120, alignment: .leading)
                            .lineLimit(1)
                        Text(item.user.home)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 150, alignment: .leading)
                            .lineLimit(1)
                        HStack {
                            if item.user.hasSudo {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axWarning)
                            }
                        }
                        .frame(width: 60, alignment: .center)
                    }
                } trailingContent: {
                    AXRefreshButton(isLoading: isLoading) {
                        Task { await loadUsers() }
                    }
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadUsers() }
    }



    // MARK: - Load Data (from Core)

    private func loadUsers() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        let result = await securityManager.listSystemUsers(serverId: serverId)
        await MainActor.run { users = result }
    }
}
