//
//  UsersSection.swift
//  AevonX
//
//  Users & Permissions section — system user audit.
//  UI only — all data comes from SecurityManager in AevonXCore.
//

import SwiftUI
import AevonXCore

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
                AXCard(padding: 0) {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            AXSectionTitle(title: "System Users", icon: "person.2.fill")
                            AXRefreshButton(isLoading: isLoading) {
                                Task { await loadUsers() }
                            }
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)

                        Divider().background(Color.axBorder)

                        // Table header row
                        HStack(spacing: 0) {
                            Text("User").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("UID").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .leading)
                            Text("Shell").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 120, alignment: .leading)
                            Text("Home").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 150, alignment: .leading)
                            Text("Sudo").font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .center)
                        }
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axBackgroundTertiary.opacity(0.5))

                        Divider().background(Color.axBorder)

                        if isLoading {
                            AXLoadingState(message: "Loading users…", style: .inline)
                        } else {
                            ForEach(Array(filteredUsers.enumerated()), id: \.offset) { index, user in
                                HStack(spacing: 0) {
                                    Text(user.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.axTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(user.uid)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axTextSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    Text(user.shell)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.axTextSecondary)
                                        .frame(width: 120, alignment: .leading)
                                        .lineLimit(1)
                                    Text(user.home)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.axTextSecondary)
                                        .frame(width: 150, alignment: .leading)
                                        .lineLimit(1)
                                    HStack {
                                        if user.hasSudo {
                                            Image(systemName: "checkmark.shield.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.axWarning)
                                        }
                                    }
                                    .frame(width: 60, alignment: .center)
                                }
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
