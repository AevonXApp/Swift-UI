//
//  EnhancedServerListView.swift
//  AevonX
//
//  Enhanced server list view with zero-knowledge encryption and subscription management
//

import SwiftUI
import AevonXCore

struct EnhancedServerListView: View {
    @StateObject private var viewModel = ServerListViewModel()
    @State private var showAddServer = false
    @State private var showHostKeyAlert = false
    @State private var selectedServerForAlert: ServerViewModel?
    @State private var hostKeyAlertData: (expected: String, actual: String)?
    
    var body: some View {
        List {
            // Subscription Status Section
            if let status = viewModel.subscriptionStatus {
                SubscriptionStatusSection(status: status, remainingSlots: viewModel.remainingSlots)
            }
            
            // Servers Section
            if viewModel.decryptedServers.isEmpty {
                EmptyServersView()
            } else {
                ForEach(viewModel.decryptedServers) { server in
                    ServerRowView(
                        server: server,
                        connectionProgress: viewModel.connectionProgress[server.id],
                        connectionResult: viewModel.connectionResults[server.id]
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Only allow tapping accessible servers
                        if server.accessLevel == .full {
                            // Navigate to server details
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if server.accessLevel == .full {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteServer(id: server.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .contextMenu {
                        ServerContextMenu(
                            server: server,
                            onTestConnection: {
                                Task {
                                    await viewModel.testConnection(serverId: server.id)
                                }
                            }
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddServer = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.canAddServer)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showAddServer) {
            AddServerView { request in
                Task {
                    await viewModel.addServer(request)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .hostKeyChangeAlert(
            isPresented: $showHostKeyAlert,
            serverName: selectedServerForAlert?.name ?? "",
            expectedFingerprint: hostKeyAlertData?.expected ?? "",
            actualFingerprint: hostKeyAlertData?.actual ?? "",
            onAccept: {
                // Accept new host key
            },
            onCancel: {
                // Cancel connection
            }
        )
        .task {
            await viewModel.initialize()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Supporting Views

struct SubscriptionStatusSection: View {
    let status: SubscriptionStatus
    let remainingSlots: Int
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Plan: \(status.plan.capitalized)")
                        .font(.headline)
                    
                    Spacer()
                    
                    if status.subscription.active {
                        Label("Active", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Label("Free", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                HStack {
                    Text("Servers: \(status.currentServerCount)/\(status.serverLimit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if remainingSlots > 0 {
                        Text("\(remainingSlots) slot\(remainingSlots == 1 ? "" : "s") remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Limit reached")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(status.subscription.active ? Color.green : Color.orange)
                            .frame(
                                width: geometry.size.width * CGFloat(status.currentServerCount) / CGFloat(max(status.serverLimit, 1)),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        }
    }
}

struct EmptyServersView: View {
    var body: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "server.rack")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No Servers Yet")
                    .font(.headline)
                
                Text("Add your first server to get started with secure remote management.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}

struct ServerRowView: View {
    let server: ServerViewModel
    var connectionProgress: ConnectionProgress?
    var connectionResult: ConnectionTestResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: server.iconName)
                    .font(.title2)
                    .foregroundColor(server.accessLevel == .full ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(server.name)
                        .font(.headline)
                    
                    Text("Created \(server.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Access level indicator
                AccessLevelBadge(level: server.accessLevel)
            }
            
            // Connection progress
            if let progress = connectionProgress {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: progress.percentComplete)
                        .progressViewStyle(.linear)
                }
                .padding(.top, 4)
            }
            
            // Connection result
            if let result = connectionResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.success ? .green : .red)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let latency = result.latencyMs {
                        Spacer()
                        Text("\(String(format: "%.0f", latency))ms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .opacity(server.accessLevel == .none ? 0.5 : 1.0)
    }
}

struct AccessLevelBadge: View {
    let level: ServerAccessLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(text)
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch level {
        case .full:
            return "checkmark.seal.fill"
        case .readOnly:
            return "eye.fill"
        case .none:
            return "lock.fill"
        }
    }
    
    private var text: String {
        switch level {
        case .full:
            return "Full Access"
        case .readOnly:
            return "Read Only"
        case .none:
            return "Locked"
        }
    }
    
    private var backgroundColor: Color {
        switch level {
        case .full:
            return .green.opacity(0.2)
        case .readOnly:
            return .orange.opacity(0.2)
        case .none:
            return .red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch level {
        case .full:
            return .green
        case .readOnly:
            return .orange
        case .none:
            return .red
        }
    }
}

struct ServerContextMenu: View {
    let server: ServerViewModel
    let onTestConnection: () -> Void
    
    var body: some View {
        if server.accessLevel == .full {
            Button {
                onTestConnection()
            } label: {
                Label("Test Connection", systemImage: "network.badge.shield.half.filled")
            }
            
            Button {
                // Edit server
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        
        Button {
            // View details
        } label: {
            Label("View Details", systemImage: "info.circle")
        }
        
        if server.accessLevel == .readOnly {
            Button {
                // Upgrade prompt
            } label: {
                Label("Upgrade to Access", systemImage: "arrow.up.circle")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EnhancedServerListView()
    }
}
