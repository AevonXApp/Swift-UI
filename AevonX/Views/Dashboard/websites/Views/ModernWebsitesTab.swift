//
//  ModernWebsitesTab.swift
//  AevonX
//
//  Modern website management tab using the new modular architecture
//  Production-ready implementation with real data flow
//

import SwiftUI
import AevonXCore

// MARK: - Modern Websites Tab

/// Modern website management tab with full production architecture
struct ModernWebsitesTab: View {
    @StateObject private var viewModel: WebsiteManagementViewModel
    @State private var websiteForDetail: WebsiteInfo?
    @State private var initialDetailTab: Int = 0
    @State private var websiteToDelete: WebsiteInfo?
    @State private var showDeleteConfirmation = false

    init(server: Server? = nil, serverId: String? = nil, connectionViewModel: ServerConnectionViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: WebsiteManagementViewModel(
            server: server,
            serverId: serverId,
            connectionViewModel: connectionViewModel
        ))
    }

    var body: some View {
        Group {
            if let website = websiteForDetail {
                // Full-page website detail view
                WebsiteDetailView(
                    website: website,
                    serverId: viewModel.serverId,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            websiteForDetail = nil
                        }
                    },
                    initialTab: initialDetailTab
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Normal websites list view
                VStack(spacing: 0) {
                    WebsiteStatsBar(viewModel: viewModel)
                    WebsiteToolbar(viewModel: viewModel)
                    contentArea
                        .padding(.top, AXSpacing.md)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddWebsite) {
            AddWebsiteView(
                serverId: viewModel.serverId,
                onCreated: {
                    Task { await viewModel.loadData() }
                }
            )
        }
        .sheet(isPresented: $viewModel.showWebsiteDetail) {
            if let website = viewModel.selectedWebsite {
                WebsiteDetailView(
                    website: website,
                    serverId: viewModel.serverId,
                    onBack: {
                        viewModel.showWebsiteDetail = false
                    }
                )
            }
        }
        .alert("Delete Website", isPresented: $showDeleteConfirmation, presenting: websiteToDelete) { website in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteWebsite(website)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
        } message: { website in
            Text("Are you sure you want to delete \(website.name)? This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading && viewModel.allWebsites.isEmpty {
            LoadingStateView()
        } else if !viewModel.isConnected {
            DisconnectedStateView()
        } else if viewModel.filteredWebsites.isEmpty {
            EmptyStateView(searchText: viewModel.searchText)
        } else {
            WebsiteTableView(
                websites: viewModel.filteredWebsites,
                onSelect: { website in
                    initialDetailTab = 0
                    websiteForDetail = website
                },
                onToggle: { website in
                    Task {
                        do {
                            try await viewModel.toggleWebsite(website)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                },
                onDeploy: { website in
                    Task {
                        do {
                            try await viewModel.deployWebsite(website)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                },
                onDelete: { website in
                    websiteToDelete = website
                    showDeleteConfirmation = true
                },
                onLogs: { website in
                    initialDetailTab = 3
                    websiteForDetail = website
                },
                onConfig: { website in
                    initialDetailTab = 1
                    websiteForDetail = website
                },
                onSSL: { website in
                    initialDetailTab = 4 // SSL/TLS tab
                    websiteForDetail = website
                }
            )
        }
    }
}

// MARK: - Website Stats Bar

struct WebsiteStatsBar: View {
    @ObservedObject var viewModel: WebsiteManagementViewModel

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            WebsiteStatCard(
                title: "Total Sites",
                value: "\(viewModel.totalWebsiteCount)",
                icon: "globe",
                color: .axAccentBlue
            )

            WebsiteStatCard(
                title: "Online",
                value: "\(viewModel.onlineCount)",
                icon: "checkmark.circle.fill",
                color: .axSuccess
            )

            WebsiteStatCard(
                title: "SSL Secured",
                value: "\(viewModel.sslSecuredCount)",
                icon: "lock.shield.fill",
                color: .axAccentGreen
            )

            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
}

// MARK: - Website Toolbar

struct WebsiteToolbar: View {
    @ObservedObject var viewModel: WebsiteManagementViewModel

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Search field
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.axTextMuted)

                TextField("Search websites...", text: $viewModel.searchText)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.md)
            .frame(width: 280)

            Spacer()

            // Add website button
            Button(action: { viewModel.showAddWebsite = true }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Website")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isConnected)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading websites...")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Disconnected State View

struct DisconnectedStateView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "network.slash")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)

            Text("Not Connected")
                .font(AXTypography.title)
                .foregroundColor(.axTextPrimary)

            Text("Please connect to a server to manage websites")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: searchText.isEmpty ? "globe" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)

            if searchText.isEmpty {
                Text("No Websites")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text("Create your first website to get started")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            } else {
                Text("No Results")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text("No websites match '\(searchText)'")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ModernWebsitesTab()
        .padding()
        .background(Color.axBackground)
}
