//
//  PasswordManagementSection.swift
//  AevonX
//
//  Password management card for root, MySQL, PostgreSQL.
//

import SwiftUI

struct PasswordManagementSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    SettingsPasswordRow(
                        title: L10n.ServerSettings.rootPassword, subtitle: L10n.ServerSettings.linuxRootUser, icon: "person.badge.key",
                        newPwd: $vm.rootNewPwd, confirmPwd: $vm.rootConfirmPwd,
                        isChanging: vm.isChangingRoot, message: vm.rootMsg, action: vm.changeRootPassword
                    )

                    Divider().background(Color.axBorder.opacity(0.4))

                    SettingsPasswordRow(
                        title: L10n.ServerSettings.mysqlRoot, subtitle: L10n.ServerSettings.mysqlRootDesc, icon: "cylinder.split.1x2",
                        newPwd: $vm.mysqlNewPwd, confirmPwd: $vm.mysqlConfirmPwd,
                        isChanging: vm.isChangingMySQL, message: vm.mysqlMsg, action: vm.changeMySQLPassword
                    )

                    Divider().background(Color.axBorder.opacity(0.4))

                    SettingsPasswordRow(
                        title: L10n.ServerSettings.postgresql, subtitle: L10n.ServerSettings.postgresqlDesc, icon: "cylinder",
                        newPwd: $vm.pgNewPwd, confirmPwd: $vm.pgConfirmPwd,
                        isChanging: vm.isChangingPG, message: vm.pgMsg, action: vm.changePGPassword
                    )
                }
            }
        }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "lock.rotation", title: L10n.ServerSettings.passwordManagement,
            subtitle: L10n.ServerSettings.changePasswords, gradient: [.axWarning, .orange],
            isExpanded: $isExpanded
        )
    }
}
