
import SwiftUI
import AevonXCoreBridge

struct DockerDetailView: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel

    // Internal state for Docker tabs
    @State private var selectedTab: DockerTab = .overview
    @State private var isDockerInstalled: Bool? = nil
    @State private var isCheckingInstallation = true

    // Sheet states for advanced features
    @State private var showAICompose = false
    @State private var showDockerfileBuilder = false
    @State private var showEventsStream = false // kept for backward compat
    @State private var showExportImport = false
    @State private var showCustomTemplate = false
    @State private var showSystemPrune = false
    @State private var showVolumeBrowser = false
    @State private var showPaywall = false

    // Feature gate cache (loaded from signed permit)
    @State private var featureGates: [String: Bool] = [:]

    enum DockerTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case containers = "Containers"
        case images = "Images"
        case volumes = "Volumes"
        case networks = "Networks"
        case compose = "Compose"
        case health = "Health"
        case security = "Security"
        case logs = "Logs"
        case tools = "Tools"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .containers: return "shippingbox.fill"
            case .images: return "photo.stack.fill"
            case .volumes: return "internaldrive.fill"
            case .networks: return "network"
            case .compose: return "square.stack.3d.up.fill"
            case .health: return "heart.fill"
            case .security: return "shield.lefthalf.filled"
            case .logs: return "text.line.first.and.arrowtriangle.forward"
            case .tools: return "wrench.and.screwdriver.fill"
            }
        }

        /// Feature gate key from backend. nil = free (no gate).
        var featureGateKey: String? {
            switch self {
            case .overview, .containers, .images, .volumes, .networks:
                return nil
            case .compose:  return "feature_docker_compose"
            case .health:   return "feature_docker_health"
            case .security: return "feature_docker_security"
            case .logs:     return "feature_docker_logs"
            case .tools:    return "feature_docker_tools"
            }
        }
    }

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            headerSection

            if isDockerInstalled == true {
                quickActionsBar
            }

            tabBar

            Divider()

            contentArea
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.lg)
        .onAppear {
            checkInstallation()
            Task { await loadFeatureGates() }
        }
        .sheet(isPresented: $showAICompose) {
            DockerAIComposeGenerator(serverId: serverId)
        }
        .sheet(isPresented: $showDockerfileBuilder) {
            DockerfileBuilder(serverId: serverId)
        }
        .sheet(isPresented: $showExportImport) {
            DockerContainerExportImport(serverId: serverId)
        }
        .sheet(isPresented: $showCustomTemplate) {
            DockerCustomTemplateCreator(serverId: serverId)
        }
        .sheet(isPresented: $showSystemPrune) {
            DockerSystemPrune(serverId: serverId)
        }
        .sheet(isPresented: $showVolumeBrowser) {
            DockerVolumeBrowser(serverId: serverId)
        }
        .overlay {
            if showPaywall {
                FeaturePaywallView(
                    featureTitle: "Unlock Docker Pro",
                    featureDescription: "Upgrade to Pro to access Compose, Health Monitoring, Security Scanning, Logs, AI Tools, and more.",
                    isPresented: $showPaywall
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Docker Management")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)

                Text(server.name)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                if isCheckingInstallation {
                    ProgressView().controlSize(.small)
                } else {
                    Circle()
                        .fill(isDockerInstalled == true ? Color.axSuccess : Color.axError)
                        .frame(width: 8, height: 8)
                    Text(isDockerInstalled == true ? "Engine Running" : "Not Installed")
                        .font(AXTypography.subheadline)
                        .foregroundColor(isDockerInstalled == true ? .axSuccess : .axError)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((isDockerInstalled == true ? Color.axSuccess : Color.axError).opacity(0.1))
            .cornerRadius(16)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                // PRO quick actions
                proQuickAction(icon: "sparkles", label: "AI Compose", color: .purple, gateKey: "feature_docker_ai_compose") {
                    showAICompose = true
                }
                proQuickAction(icon: "hammer.fill", label: "Dockerfile", color: .orange, gateKey: "feature_docker_dockerfile") {
                    showDockerfileBuilder = true
                }
                proQuickAction(icon: "arrow.left.arrow.right", label: "Export/Import", color: .axAccentBlue, gateKey: "feature_docker_export") {
                    showExportImport = true
                }
                proQuickAction(icon: "plus.rectangle.on.folder.fill", label: "Template", color: .green, gateKey: "feature_docker_templates") {
                    showCustomTemplate = true
                }

                // Free quick actions
                quickActionButton(icon: "folder.fill", label: "Volumes", color: .cyan) {
                    showVolumeBrowser = true
                }
                quickActionButton(icon: "trash.circle.fill", label: "Prune", color: .red) {
                    showSystemPrune = true
                }
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.md) {
                ForEach(DockerTab.allCases) { tab in
                    let locked = isTabLocked(tab)
                    Button(action: {
                        if locked {
                            showPaywall = true
                        } else {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: locked ? "lock.fill" : tab.icon)
                                .font(.system(size: locked ? 11 : 14))
                            Text(tab.rawValue)
                                .font(AXTypography.subheadline)
                                .fontWeight(.medium)
                            if locked {
                                Text("PRO")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.axAccentBlue))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(locked
                                      ? Color.axSurface.opacity(0.5)
                                      : (selectedTab == tab ? Color.axAccentBlue.opacity(0.15) : Color.axSurface))
                        )
                        .foregroundColor(locked
                                         ? .axTextMuted
                                         : (selectedTab == tab ? .axAccentBlue : .axTextSecondary))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(locked
                                        ? Color.axBorder.opacity(0.3)
                                        : (selectedTab == tab ? Color.axAccentBlue.opacity(0.5) : Color.clear),
                                        lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if isCheckingInstallation {
            VStack {
                Spacer()
                ProgressView("Checking Docker installation...")
                Spacer()
            }
        } else if isDockerInstalled == false {
            DockerInstallationView(serverId: serverId) {
                checkInstallation()
            }
        } else {
            switch selectedTab {
            case .logs:
                DockerLogsTab(serverId: serverId)
            case .tools:
                DockerToolsTab(serverId: serverId)
            case .security:
                ScrollView {
                    DockerSecurityTab(serverId: serverId)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.bottom, AXSpacing.xl)
                }
            default:
                ScrollView {
                    switch selectedTab {
                    case .overview:
                        DockerOverviewTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                    case .containers:
                        DockerContainersTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                    case .images:
                        DockerImagesTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                    case .volumes:
                        DockerVolumesTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                    case .networks:
                        DockerNetworksTab(serverId: serverId)
                    case .compose:
                        DockerComposeTab(serverId: serverId)
                    case .health:
                        DockerHealthTab(serverId: serverId)
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }

    // MARK: - Feature Gate Helpers

    private func isTabLocked(_ tab: DockerTab) -> Bool {
        guard let gateKey = tab.featureGateKey else { return false }
        return !(featureGates[gateKey] ?? false)
    }

    private func isGateLocked(_ gateKey: String) -> Bool {
        return !(featureGates[gateKey] ?? false)
    }

    private func loadFeatureGates() async {
        // Refresh subscription status (fetches fresh permit if cache expired)
        let _ = try? await SubscriptionManager.shared.getSubscriptionStatus()

        let fgm = FeatureGateManager.shared
        let allKeys = [
            "feature_docker_compose", "feature_docker_health", "feature_docker_security",
            "feature_docker_logs", "feature_docker_tools", "feature_docker_ai_compose",
            "feature_docker_dockerfile", "feature_docker_export", "feature_docker_templates",
        ]
        for key in allKeys {
            featureGates[key] = await fgm.isFeatureEnabled(key)
        }
    }

    // MARK: - Buttons

    private func checkInstallation() {
        isCheckingInstallation = true
        Task {
            do {
                let installed = try await DockerService.shared.isInstalled(serverId: serverId)
                await MainActor.run {
                    self.isDockerInstalled = installed
                    self.isCheckingInstallation = false
                }
            } catch {
                await MainActor.run {
                    self.isDockerInstalled = false
                    self.isCheckingInstallation = false
                }
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.08))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func proQuickAction(icon: String, label: String, color: Color, gateKey: String, action: @escaping () -> Void) -> some View {
        let locked = isGateLocked(gateKey)
        return Button(action: {
            if locked {
                showPaywall = true
            } else {
                action()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: locked ? "lock.fill" : icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                if locked {
                    Text("PRO")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.axAccentBlue))
                }
            }
            .foregroundColor(locked ? .axTextMuted : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((locked ? Color.axTextMuted : color).opacity(0.08))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke((locked ? Color.axBorder : color).opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
