//
//  ServerSettingsContentView.swift
//  AevonX
//
//  Main coordinator view for server settings.
//  Composes section views — contains no business logic.
//

import SwiftUI

struct ServerSettingsContentView: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    @StateObject private var vm: ServerSettingsViewModel
    @EnvironmentObject var settings: AppSettingsManager

    @State private var showRemoveAlert = false
    @State private var showDeleteUserConfirmation = false
    @State private var userToDelete = ""

    init(server: Server, serverId: String, connectionViewModel: ServerConnectionViewModel) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        _vm = StateObject(wrappedValue: ServerSettingsViewModel(serverId: serverId))
    }

    private var isConnected: Bool { connectionViewModel.isConnected }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                SSHeroSection(vm: vm, connectionVM: connectionViewModel, server: server)

                twoColumnLayout

                if isConnected {
                    UpdateManagementSection(vm: vm)
                    PasswordManagementSection(vm: vm)
                    UserManagementSection(vm: vm, showDeleteConfirmation: $showDeleteUserConfirmation, userToDelete: $userToDelete)
                } else {
                    disconnectedBanner
                }

                DangerZoneSection(server: server, showRemoveAlert: $showRemoveAlert)
            }
            .padding(AXSpacing.xl)
        }
        .task { await vm.loadAll() }
        .onChange(of: connectionViewModel.isConnected) { _, connected in
            if connected { Task { await vm.loadAll() } }
        }
        .overlay { confirmationOverlays }
    }

    private var disconnectedBanner: some View {
        AXCard {
            VStack(spacing: AXSpacing.lg) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.axTextMuted)
                Text(L10n.ServerSettings.notConnected)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.ServerSettings.connectToManage)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xxxl)
        }
    }

    private var twoColumnLayout: some View {
        HStack(alignment: .top, spacing: AXSpacing.lg) {
            ServerInfoSection(vm: vm)
                .frame(maxWidth: .infinity)
            VStack(spacing: AXSpacing.lg) {
                ConnectionSection(vm: vm, connectionVM: connectionViewModel, server: server)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var confirmationOverlays: some View {
        if showRemoveAlert {
            AXDeleteConfirmation(
                title: L10n.ServerSettings.removeServerTitle,
                itemName: server.name,
                warning: L10n.ServerSettings.removeServerWarning,
                requireTypeConfirm: true,
                onConfirm: { showRemoveAlert = false },
                onCancel: { showRemoveAlert = false }
            )
        }
        if showDeleteUserConfirmation {
            AXDeleteConfirmation(
                title: L10n.ServerSettings.deleteUserTitle,
                itemName: userToDelete,
                icon: "person.crop.circle.badge.minus",
                warning: L10n.ServerSettings.deleteUserWarning,
                onConfirm: {
                    let name = userToDelete
                    showDeleteUserConfirmation = false
                    Task { await vm.deleteUser(name) }
                },
                onCancel: { showDeleteUserConfirmation = false }
            )
        }
    }
}
