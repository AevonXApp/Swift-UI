//
//  ModernWebsitesTab.swift
//  AevonX
//
//  Modern website management tab using the new modular architecture
//  Production-ready implementation with real data flow
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Modern Websites Tab

/// Modern website management tab with full production architecture
struct ModernWebsitesTab: View {
    @EnvironmentObject var settings: AppSettingsManager
    @StateObject private var viewModel: WebsiteManagementViewModel
    @State private var websiteForDetail: WebsiteInfo?
    @State private var initialDetailTab: Int = 0
    @State private var websiteToDelete: WebsiteInfo?
    @State private var showDeleteConfirmation = false
    @State private var websiteToClone: WebsiteInfo?
    @State private var showCloneDialog = false
    @State private var cloneDomain = ""

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
                    Task { await viewModel.loadData(forceRefresh: true) }
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
        .overlay {
            if showDeleteConfirmation, let website = websiteToDelete {
                AXDeleteConfirmation(
                    title: "Delete Website",
                    itemName: website.name,
                    warning: "This action cannot be undone.",
                    onConfirm: {
                        showDeleteConfirmation = false
                        let w = website
                        websiteToDelete = nil
                        Task {
                            do { try await viewModel.deleteWebsite(w) }
                            catch { viewModel.errorMessage = error.localizedDescription }
                        }
                    },
                    onCancel: {
                        showDeleteConfirmation = false
                        websiteToDelete = nil
                    }
                )
            }
        }
        .alert("Clone Website", isPresented: $showCloneDialog) {
            TextField("New domain", text: $cloneDomain)
            Button(L10n.Button.cancel, role: .cancel) {}
            Button(L10n.Website.clone) {
                if let website = websiteToClone {
                    Task {
                        do {
                            try await viewModel.cloneWebsite(website, newDomain: cloneDomain)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            Text(L10n.Websites.enterANewDomainNameForTheClonedWebsite)
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading || viewModel.isWaitingForConnection {
            // SSH connecting or data loading → skeleton
            LoadingStateView()
        } else if !viewModel.isConnected && viewModel.allWebsites.isEmpty {
            // Connection failed → disconnected
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
                    if settings.shouldConfirm(for: SettingsKey.confirmDeleteWebsite) {
                        websiteToDelete = website
                        showDeleteConfirmation = true
                    } else {
                        Task {
                            do { try await viewModel.deleteWebsite(website) }
                            catch { viewModel.errorMessage = error.localizedDescription }
                        }
                    }
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
                    // SSL/TLS is in the security category — find its index dynamically
                    let items = ModernSidebarItem.items(for: website.runtime)
                    initialDetailTab = items.firstIndex(of: .sslTls) ?? 5
                    websiteForDetail = website
                },
                onClone: { website in
                    websiteToClone = website
                    cloneDomain = "clone-\(website.domain)"
                    showCloneDialog = true
                },
                onBackup: { website in
                    Task {
                        do {
                            try await viewModel.backupWebsite(website)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
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
            if viewModel.isLoading || viewModel.isWaitingForConnection {
                ForEach(0..<3, id: \.self) { _ in
                    AXSkeletonStatCard()
                }
            } else {
                AXStatCard(
                    icon: "globe",
                    label: "Total Sites",
                    value: "\(viewModel.totalWebsiteCount)",
                    color: .axAccentBlue,
                    layout: .horizontal
                )

                AXStatCard(
                    icon: "checkmark.circle.fill",
                    label: "Online",
                    value: "\(viewModel.onlineCount)",
                    color: .axSuccess,
                    layout: .horizontal
                )

                AXStatCard(
                    icon: "lock.shield.fill",
                    label: "SSL Secured",
                    value: "\(viewModel.sslSecuredCount)",
                    color: .axAccentGreen,
                    layout: .horizontal
                )
            }

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
            AXSearchBar(text: $viewModel.searchText, placeholder: "Search websites...")
                .frame(width: 280)

            if viewModel.showEngineFilters {
                HStack(spacing: AXSpacing.xxs) {
                    engineFilterChip("All", value: "all")
                    if viewModel.installedEngines.contains("nginx") {
                        engineFilterChip("Nginx", value: "nginx")
                    }
                    if viewModel.installedEngines.contains("apache") {
                        engineFilterChip("Apache", value: "apache")
                    }
                    if viewModel.installedEngines.contains("openlitespeed") {
                        engineFilterChip("OpenLiteSpeed", value: "openlitespeed")
                    }
                }
            }

            Spacer()

            // Add website button
            Button(action: { viewModel.showAddWebsite = true }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus")
                    Text(L10n.Websites.addWebsite)
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

    private func engineFilterChip(_ label: String, value: String) -> some View {
        let isActive = viewModel.engineFilter == value
        return Button(action: { viewModel.engineFilter = value }) {
            Text(label)
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(isActive ? .white : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                .background(isActive ? Color.axAccentBlue : Color.axSurface)
                .cornerRadius(AXCornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(isActive ? Color.clear : Color.axBorder.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: AXSpacing.md)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    websiteSkeletonCard
                }
            }
            .padding(.bottom, AXSpacing.xl)
        }
        .padding(.horizontal, AXSpacing.xl)
    }

    private var websiteSkeletonCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                Circle()
                    .fill(Color.axSurface)
                    .frame(width: 36, height: 36)
                    .shimmer()
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    AXSkeletonRow(width: 140, height: 14)
                    AXSkeletonRow(width: 90, height: 10)
                }
                Spacer()
                AXSkeletonRow(width: 60, height: 22, cornerRadius: AXCornerRadius.lg)
            }
            AXSkeletonBlock(lines: 2, height: 10)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Disconnected State View

struct DisconnectedStateView: View {
    var body: some View {
        AXPlaceholder(
            icon: "network.slash",
            title: "Not Connected",
            subtitle: "Please connect to a server to manage websites"
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: searchText.isEmpty ? "globe" : "magnifyingglass")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextMuted)

            if searchText.isEmpty {
                Text(L10n.Websites.noWebsites)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text(L10n.Websites.createYourFirstWebsiteToGetStarted)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            } else {
                Text(L10n.Websites.noResults)
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
