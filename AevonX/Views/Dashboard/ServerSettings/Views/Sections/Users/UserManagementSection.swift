//
//  UserManagementSection.swift
//  AevonX
//
//  User management card — list, add, delete system users.
//

import SwiftUI

struct UserManagementSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @Binding var showDeleteConfirmation: Bool
    @Binding var userToDelete: String

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "person.2.fill", title: L10n.ServerSettings.userManagement, subtitle: L10n.ServerSettings.systemUsersAccess, gradient: [.cyan, .axAccentBlue])
                Divider().background(Color.axBorder)

                if vm.isLoadingUsers {
                    AXSkeletonBlock(lines: 4)
                } else {
                    userList
                    Divider().background(Color.axBorder.opacity(0.4))
                    addUserRow
                    if let msg = vm.userMsg { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }
                }
            }
        }
    }

    private var userList: some View {
        ForEach(Array(vm.systemUsers.enumerated()), id: \.offset) { _, user in
            UserRow(user: user) {
                userToDelete = user.name
                showDeleteConfirmation = true
            }
        }
    }

    private var addUserRow: some View {
        HStack(spacing: AXSpacing.sm) {
            TextField(L10n.Field.username, text: $vm.newUsername)
                .font(AXTypography.subheadline)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, 5)
                .background(Color.axBackgroundTertiary)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                .cornerRadius(AXCornerRadius.sm)
            SecureField(L10n.Field.password, text: $vm.newUserPassword)
                .font(AXTypography.subheadline)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, 5)
                .background(Color.axBackgroundTertiary)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                .cornerRadius(AXCornerRadius.sm)
            Button(action: { Task { await vm.addUser() } }) {
                HStack(spacing: 3) {
                    if vm.isAddingUser { ProgressView().scaleEffect(0.5) }
                    else { Image(systemName: "plus").font(AXTypography.caption).fontWeight(.bold) }
                    Text(L10n.Button.add).font(AXTypography.footnote).fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md).padding(.vertical, 5)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(vm.isAddingUser || vm.newUsername.isEmpty)
        }
    }
}

// MARK: - User Row

private struct UserRow: View {
    let user: (name: String, uid: String, shell: String, lastLogin: String)
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                Circle().fill(user.name == "root" ? Color.axError.opacity(0.15) : Color.axAccentBlue.opacity(0.15))
                    .frame(width: 30, height: 30)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(AXTypography.caption).fontWeight(.bold)
                    .foregroundColor(user.name == "root" ? .axError : .axAccentBlue)
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: AXSpacing.xs) {
                    Text(user.name).font(AXTypography.callout).fontWeight(.semibold).foregroundColor(.axTextPrimary)
                    Text(L10n.ServerSettings.uidLabel(Int(user.uid) ?? 0)).font(AXTypography.caption).foregroundColor(.axTextTertiary)
                }
                Text(user.shell).font(AXTypography.monoXs).foregroundColor(.axTextTertiary)
            }
            Spacer()
            if user.name != "root" {
                Button(action: onDelete) {
                    Image(systemName: "trash").font(AXTypography.caption).foregroundColor(.axError.opacity(0.7))
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, AXSpacing.xxs)
    }
}
