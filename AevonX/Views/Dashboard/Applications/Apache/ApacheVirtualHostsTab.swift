//
//  ApacheVirtualHostsTab.swift
//  AevonX
//
//  Manage Apache Virtual Hosts
//

import SwiftUI
import AevonXCore

struct ApacheVirtualHostsTab: View {
    let application: ApplicationInstance
    @Binding var apacheConfig: ApacheConfigData
    let serverId: String
    
    @State private var showingAddSheet = false
    @State private var pendingDeleteVHost: ApacheVHost?
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header & Controls
            HStack {
                Text("Virtual Hosts")
                    .font(AXTypography.title3)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Label("Add Virtual Host", systemImage: "plus")
                        .font(AXTypography.subheadline)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
            
            // VHost List
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    if apacheConfig.virtualHosts.isEmpty {
                        Text("No Virtual Hosts configured")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                            .padding(.top, AXSpacing.xl)
                    } else {
                        ForEach(apacheConfig.virtualHosts) { vhost in
                            VHostCard(
                                vhost: vhost,
                                onDelete: { pendingDeleteVHost = vhost },
                                onToggle: { toggleVHost(vhost) }
                            )
                        }
                    }
                }
                .padding(.bottom, AXSpacing.xl)
            }
            }

            if showingAddSheet {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { showingAddSheet = false }

                AddVHostSheet(isPresented: $showingAddSheet, onAdd: addVHost)
                    .frame(maxWidth: 720, maxHeight: 560)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
            }
        }
        .alert(item: $pendingDeleteVHost) { vhost in
            Alert(
                title: Text("Delete Virtual Host?"),
                message: Text("Are you sure you want to delete \(vhost.domain)? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteVHost(vhost)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func addVHost(_ vhost: ApacheVHost) {
        Task {
            do {
                try await ApplicationManager.shared.createApacheVirtualHost(vhost, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Virtual Host \(vhost.domain) created successfully")
                try await refreshData()
            } catch {
                GlobalToastManager.shared.showError("Failed to create Virtual Host: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteVHost(_ vhost: ApacheVHost) {
        Task {
            do {
                try await ApplicationManager.shared.deleteApacheVirtualHost(domain: vhost.domain, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Virtual Host \(vhost.domain) deleted successfully")
                try await refreshData()
            } catch {
                GlobalToastManager.shared.showError("Failed to delete Virtual Host: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleVHost(_ vhost: ApacheVHost) {
        Task {
            do {
                if vhost.isEnabled {
                    try await ApplicationManager.shared.disableApacheVirtualHost(domain: vhost.domain, serverId: serverId)
                    GlobalToastManager.shared.showSuccess("Virtual Host \(vhost.domain) disabled")
                } else {
                    try await ApplicationManager.shared.enableApacheVirtualHost(domain: vhost.domain, serverId: serverId)
                    GlobalToastManager.shared.showSuccess("Virtual Host \(vhost.domain) enabled")
                }
                try await refreshData()
            } catch {
                GlobalToastManager.shared.showError("Failed to toggle Virtual Host: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshData() async throws {
        let vhosts = try await ApplicationManager.shared.getApacheVirtualHosts(serverId: serverId)
        await MainActor.run {
            apacheConfig.virtualHosts = vhosts
        }
    }
}

private struct VHostCard: View {
    let vhost: ApacheVHost
    let onDelete: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Image(systemName: "globe")
                .font(.system(size: 20))
                .foregroundColor(.axAccentBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vhost.domain)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    if !vhost.isEnabled {
                        Text("Disabled")
                            .font(AXTypography.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axError.opacity(0.1))
                            .foregroundColor(.axError)
                            .cornerRadius(4)
                    }
                }
                
                Text(vhost.documentRoot)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                HStack(spacing: AXSpacing.md) {
                    Label("\(vhost.port)", systemImage: "network")
                    if vhost.isSslEnabled {
                        Label("SSL", systemImage: "lock.fill")
                            .foregroundColor(.axSuccess)
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            VStack(spacing: AXSpacing.sm) {
                Button(action: onToggle) {
                    Image(systemName: vhost.isEnabled ? "power" : "play.fill")
                        .foregroundColor(vhost.isEnabled ? .axWarning : .axSuccess)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }
}

private struct AddVHostSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (ApacheVHost) -> Void
    
    @State private var domain = ""
    @State private var documentRoot = "/var/www/html"
    @State private var port = 80
    @State private var adminEmail = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Virtual Host")
                    .font(AXTypography.headline)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Form {
                Section("Basic Info") {
                    TextField("Domain Name", text: $domain)
                        .textFieldStyle(.roundedBorder)
                    TextField("Document Root", text: $documentRoot)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Configuration") {
                    TextField("Port", value: $port, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                    TextField("Admin Email (Optional)", text: $adminEmail)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button("Create Virtual Host") {
                    let vhost = ApacheVHost(
                        domain: domain,
                        documentRoot: documentRoot,
                        port: port,
                        isEnabled: true,
                        isSslEnabled: false,
                        adminEmail: adminEmail.isEmpty ? nil : adminEmail
                    )
                    onAdd(vhost)
                    isPresented = false
                }
                .disabled(domain.isEmpty || documentRoot.isEmpty)
                .padding(.top)
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 500)
    }
}
