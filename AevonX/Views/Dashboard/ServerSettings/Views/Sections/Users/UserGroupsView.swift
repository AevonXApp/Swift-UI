//
//  UserGroupsView.swift
//  AevonX
//
//  System groups with members, add/delete groups, sudo management.
//

import SwiftUI

extension AdvancedUserSection {

    var groupsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.groupsSudo, icon: "person.3.sequence.fill")

            // Sudo users banner
            if !vm.sudoUsers.isEmpty {
                sudoBanner
            }

            // Group list
            ForEach(vm.groups) { group in
                groupRow(group)
            }

            // Add group
            addGroupRow
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private var sudoBanner: some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: "shield.checkered")
                .font(AXTypography.caption2).foregroundColor(.axWarning)
            Text(L10n.ServerSettings.sudoUsers)
                .font(AXTypography.caption2).foregroundColor(.axTextMuted)
            Text(vm.sudoUsers.joined(separator: ", "))
                .font(AXTypography.monoXs).foregroundColor(.axWarning)
        }
        .padding(AXSpacing.xs)
        .background(Color.axWarning.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func groupRow(_ group: SystemGroup) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(group.name)
                .font(AXTypography.monoXs).fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
                .frame(width: 80, alignment: .leading)
            Text(L10n.ServerSettings.gidLabel(Int(group.gid) ?? 0))
                .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                .frame(width: 55, alignment: .leading)
            Text(group.members.isEmpty ? "—" : group.members.joined(separator: ", "))
                .font(AXTypography.caption2).foregroundColor(.axTextSecondary)
                .lineLimit(1)
            Spacer()
            if !["root", "sudo", "wheel"].contains(group.name) {
                Button(action: { Task { await vm.deleteGroup(group.name) } }) {
                    Image(systemName: "trash")
                        .font(AXTypography.caption2).foregroundColor(.axError)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, AXSpacing.xxxs)
    }

    private var addGroupRow: some View {
        HStack(spacing: AXSpacing.xs) {
            TextField(L10n.ServerSettings.newGroupPlaceholder, text: $vm.newGroupName)
                .font(AXTypography.caption).textFieldStyle(.plain)
                .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
            Button(action: { Task { await vm.addGroup() } }) {
                Image(systemName: "plus.circle.fill")
                    .font(AXTypography.body).foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(vm.newGroupName.isEmpty)
        }
    }
}
