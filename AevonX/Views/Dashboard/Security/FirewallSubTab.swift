//
//  FirewallSubTab.swift
//  AevonX
//
//  Firewall port rules management — all data from real server
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Data Models

struct FirewallRule: Identifiable {
    let id = UUID()
    var protocolType: String     // tcp, udp
    var port: String
    var strategy: String         // ACCEPT, DROP
    var direction: String        // INPUT, OUTPUT
    var sourceIP: String         // "0.0.0.0/0" or specific IP
}

struct ListeningPort: Identifiable {
    let id = UUID()
    var protocolType: String     // tcp, udp
    var port: String
    var process: String          // service name
    var state: String            // LISTEN
}

// MARK: - View

struct FirewallSubTab: View {
    let serverId: String

    @State private var firewallEnabled = false
    @State private var blockICMP = false
    @State private var showAddRule = false
    @State private var searchText = ""
    @State private var directionFilter: DirectionFilter = .all
    @State private var rules: [FirewallRule] = []
    @State private var listeningPorts: [ListeningPort] = []
    @State private var isLoading = true
    @State private var isTogglingFirewall = false
    @State private var isTogglingICMP = false
    @State private var showTemplates = false
    @State private var isApplyingTemplate = false
    @State private var ruleError: String?

    private let securityManager = SecurityManager.shared

    enum DirectionFilter: String, CaseIterable {
        case all = "All Directions"
        case inbound = "Inbound"
        case outbound = "Outbound"
    }

    private var filteredRules: [FirewallRule] {
        rules.filter { rule in
            let matchesDirection: Bool = {
                switch directionFilter {
                case .all: return true
                case .inbound: return rule.direction == "INPUT"
                case .outbound: return rule.direction == "OUTPUT"
                }
            }()
            let matchesSearch = searchText.isEmpty || rule.port.contains(searchText)
            return matchesDirection && matchesSearch
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                togglesCard
                statsBar
                toolbarRow

                if showTemplates {
                    ruleTemplatesCard
                }

                listeningPortsTable
                rulesTable
            }
            .padding(AXSpacing.xxl)
        }
        .sheet(isPresented: $showAddRule) {
            PortRuleSheet(
                title: "Add Port Rule",
                onSave: { newRule in
                    Task {
                        await addRule(newRule)
                        await MainActor.run { showAddRule = false }
                    }
                }
            )
        }
        .task { await loadFirewallData() }
        .onAppear { Task { await refreshRules() } }
        .alert("Firewall Error", isPresented: Binding(
            get: { ruleError != nil },
            set: { if !$0 { ruleError = nil } }
        )) {
            Button("OK", role: .cancel) { ruleError = nil }
        } message: {
            Text(ruleError ?? "")
        }
    }

    // MARK: - Load Data

    private func loadFirewallData() async {
        let fwActive = await securityManager.firewallStatus(serverId: serverId)
        await MainActor.run { firewallEnabled = fwActive }
        await refreshRules()
    }

    private func refreshRules() async {
        await MainActor.run { isLoading = true }

        let coreRules = await securityManager.listFirewallRules(serverId: serverId)
        let corePorts = await securityManager.listeningPorts(serverId: serverId)

        await MainActor.run {
            rules = coreRules.map { r in
                let normalizedStrategy: String
                switch r.target.uppercased() {
                case "ALLOW": normalizedStrategy = "ACCEPT"
                case "DENY", "REJECT": normalizedStrategy = "DROP"
                default: normalizedStrategy = r.target
                }
                return FirewallRule(
                    protocolType: r.proto, port: r.port,
                    strategy: normalizedStrategy, direction: r.chain, sourceIP: r.source
                )
            }
            listeningPorts = corePorts.map { p in
                ListeningPort(
                    protocolType: p.proto, port: p.port,
                    process: p.service, state: "LISTEN"
                )
            }
            isLoading = false
        }
    }

    private func parseFirewallOutput(_ raw: String) -> ([FirewallRule], [ListeningPort]) {
        var firewallRules: [FirewallRule] = []
        var ports: [ListeningPort] = []
        var section = "" // "iptables" or "listening"

        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "---IPTABLES---" {
                section = "iptables"
                continue
            }
            if trimmed == "---LISTENING---" {
                section = "listening"
                continue
            }
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.components(separatedBy: "|")

            if section == "iptables" && parts.count >= 5 {
                let proto = parts[0].lowercased()
                let port = parts[1]
                let target = parts[2]
                let chain = parts[3]
                let source = parts[4]
                guard port != "*" else { continue }
                firewallRules.append(FirewallRule(
                    protocolType: proto, port: port, strategy: target,
                    direction: chain, sourceIP: source
                ))
            } else if section == "listening" && parts.count >= 4 {
                let proto = parts[0].lowercased()
                let port = parts[1]
                let proc = parts[2]
                let state = parts[3]
                guard !port.isEmpty, port != "*" else { continue }
                // Deduplicate by port+proto
                if !ports.contains(where: { $0.port == port && $0.protocolType == proto }) {
                    ports.append(ListeningPort(
                        protocolType: proto, port: port, process: proc, state: state
                    ))
                }
            }
        }

        // Sort ports numerically
        ports.sort { (Int($0.port) ?? 0) < (Int($1.port) ?? 0) }
        return (firewallRules, ports)
    }

    private func addRule(_ rule: FirewallRule) async {
        let (success, output) = await securityManager.addFirewallRule(
            proto: rule.protocolType.lowercased(),
            port: rule.port,
            strategy: rule.strategy,
            direction: rule.direction,
            sourceIP: rule.sourceIP,
            serverId: serverId
        )
        if !success {
            let detail = output.isEmpty ? "No response from server" : output
            await MainActor.run { ruleError = "Failed to add rule for port \(rule.port): \(detail)" }
        }
        await refreshRules()
    }

    private func deleteRule(_ rule: FirewallRule) async {
        let (success, output) = await securityManager.deleteFirewallRule(
            proto: rule.protocolType.lowercased(),
            port: rule.port,
            direction: rule.direction,
            serverId: serverId
        )
        if !success {
            let detail = output.isEmpty ? "No response from server" : output
            await MainActor.run { ruleError = "Failed to delete rule for port \(rule.port): \(detail)" }
        }
        await refreshRules()
    }

    // MARK: - Toggles Card

    private var togglesCard: some View {
        AXCard {
            HStack(spacing: AXSpacing.xxxl) {
                // Firewall toggle
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(firewallEnabled ? .axAccentBlue : .axTextMuted)

                    Text(L10n.Security.firewall)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    if isTogglingFirewall {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Toggle("", isOn: $firewallEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                            .labelsHidden()
                            .frame(width: 40)
                            .onChange(of: firewallEnabled) { _, newValue in
                                Task {
                                    isTogglingFirewall = true
                                    let _ = await securityManager.setFirewall(enabled: newValue, serverId: serverId)
                                    isTogglingFirewall = false
                                }
                            }
                    }
                }

                Divider()
                    .frame(height: 20)

                // ICMP toggle
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "network")
                        .font(.system(size: 16))
                        .foregroundColor(blockICMP ? .axWarning : .axTextMuted)

                    Text(L10n.Security.blockIcmp)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextSecondary)

                    if isTogglingICMP {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Toggle("", isOn: $blockICMP)
                            .toggleStyle(SwitchToggleStyle(tint: .axWarning))
                            .labelsHidden()
                            .frame(width: 40)
                            .onChange(of: blockICMP) { _, newValue in
                                Task {
                                    isTogglingICMP = true
                                    let _ = await securityManager.setICMPBlock(enabled: newValue, serverId: serverId)
                                    isTogglingICMP = false
                                }
                            }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: AXSpacing.lg) {
            AXStatCard(icon: "antenna.radiowaves.left.and.right", label: "Listening", value: "\(listeningPorts.count)", color: .axAccentBlue, layout: .horizontal, style: .pill)
            AXStatCard(icon: "list.bullet.rectangle", label: "Firewall Rules", value: "\(rules.count)", color: .axAccentPurple, layout: .horizontal, style: .pill)
            AXStatCard(icon: "arrow.down.to.line", label: "Inbound", value: "\(rules.filter { $0.direction == "INPUT" }.count)", color: .axAccentGreen, layout: .horizontal, style: .pill)
            AXStatCard(icon: "checkmark.shield", label: "Allowed", value: "\(rules.filter { $0.strategy == "ACCEPT" }.count)", color: .axSuccess, layout: .horizontal, style: .pill)
            Spacer()
        }
    }

    // MARK: - Rule Templates (Phase 2)

    private struct RuleTemplate: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        let description: String
        let rules: [(proto: String, port: String, strategy: String, direction: String)]
    }

    private var ruleTemplates: [RuleTemplate] {
        [
            RuleTemplate(
                name: "Web Server",
                icon: "globe",
                color: .axAccentBlue,
                description: "HTTP + HTTPS",
                rules: [
                    ("tcp", "80", "ACCEPT", "INPUT"),
                    ("tcp", "443", "ACCEPT", "INPUT")
                ]
            ),
            RuleTemplate(
                name: "SSH Access",
                icon: "terminal.fill",
                color: .axAccentGreen,
                description: "Port 22",
                rules: [
                    ("tcp", "22", "ACCEPT", "INPUT")
                ]
            ),
            RuleTemplate(
                name: "Database",
                icon: "cylinder.fill",
                color: .axAccentPurple,
                description: "MySQL + PostgreSQL",
                rules: [
                    ("tcp", "3306", "ACCEPT", "INPUT"),
                    ("tcp", "5432", "ACCEPT", "INPUT")
                ]
            ),
            RuleTemplate(
                name: "Mail Server",
                icon: "envelope.fill",
                color: .axWarning,
                description: "SMTP + IMAP",
                rules: [
                    ("tcp", "25", "ACCEPT", "INPUT"),
                    ("tcp", "587", "ACCEPT", "INPUT"),
                    ("tcp", "993", "ACCEPT", "INPUT")
                ]
            ),
            RuleTemplate(
                name: "DNS",
                icon: "network",
                color: .axAccentBlue,
                description: "TCP + UDP 53",
                rules: [
                    ("tcp", "53", "ACCEPT", "INPUT"),
                    ("udp", "53", "ACCEPT", "INPUT")
                ]
            ),
            RuleTemplate(
                name: "FTP",
                icon: "folder.fill",
                color: .axError,
                description: "FTP + Passive",
                rules: [
                    ("tcp", "21", "ACCEPT", "INPUT"),
                    ("tcp", "20", "ACCEPT", "INPUT")
                ]
            )
        ]
    }

    private var ruleTemplatesCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.axAccentPurple)
                    Text(L10n.Security.quickTemplates)
                        .font(AXTypography.title3)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    Text(L10n.Security.oneClickRuleGroups)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AXSpacing.md) {
                    ForEach(ruleTemplates) { template in
                        Button(action: {
                            Task { await applyTemplate(template) }
                        }) {
                            VStack(spacing: AXSpacing.sm) {
                                Image(systemName: template.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(template.color)

                                Text(template.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.axTextPrimary)

                                Text(template.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.axTextMuted)

                                Text("\(template.rules.count) rules")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(template.color)
                                    .padding(.horizontal, AXSpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(template.color.opacity(0.1))
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                    .fill(Color.axSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                            .stroke(template.color.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                if isApplyingTemplate {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.6)
                        Text(L10n.Security.applyingRules)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func applyTemplate(_ template: RuleTemplate) async {
        await MainActor.run { isApplyingTemplate = true }
        for rule in template.rules {
            let _ = await securityManager.addFirewallRule(
                proto: rule.proto,
                port: rule.port,
                strategy: rule.strategy,
                direction: rule.direction,
                sourceIP: "0.0.0.0/0",
                serverId: serverId
            )
        }
        await refreshRules()
        await MainActor.run { isApplyingTemplate = false }
    }

    // MARK: - Toolbar

    private var toolbarRow: some View {
        HStack(spacing: AXSpacing.md) {
            Button(action: { showAddRule = true }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text(L10n.Security.addPortRule)
                        .font(AXTypography.headline)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axAccentBlue)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())

            AXRefreshButton(isLoading: isLoading) {
                await refreshRules()
            }

            Button(action: {
                withAnimation(.spring(response: 0.3)) { showTemplates.toggle() }
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11))
                    Text(L10n.Security.templates)
                        .font(AXTypography.headline)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(showTemplates ? Color.axAccentPurple.opacity(0.1) : Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(showTemplates ? Color.axAccentPurple.opacity(0.3) : Color.axBorder, lineWidth: 1)
                        )
                )
                .foregroundColor(showTemplates ? .axAccentPurple : .axTextSecondary)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Direction filter
            HStack(spacing: 0) {
                ForEach(DirectionFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            directionFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(AXTypography.caption)
                            .foregroundColor(directionFilter == filter ? .axTextPrimary : .axTextMuted)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(directionFilter == filter ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            )

            // Search
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)

                TextField("Search port…", text: $searchText)
                    .font(AXTypography.body)
                    .textFieldStyle(.plain)
                    .frame(width: 120)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Listening Ports Table

    private var filteredListeningPorts: [ListeningPort] {
        listeningPorts.filter { p in
            searchText.isEmpty || p.port.contains(searchText) || p.process.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var listeningPortsTable: some View {
        AXDataTable(
            title: "Listening Ports",
            icon: "antenna.radiowaves.left.and.right",
            accentColor: .axAccentBlue,
            badgeText: "\(listeningPorts.count) active",
            columns: [
                AXDataColumn(title: "Protocol", width: 80),
                AXDataColumn(title: "Port", width: 80),
                AXDataColumn(title: "Service / Process", width: nil),
                AXDataColumn(title: "State", width: 80),
                AXDataColumn(title: "Firewall", width: 100),
                AXDataColumn(title: "Actions", width: 140),
            ],
            items: filteredListeningPorts,
            totalCount: listeningPorts.count,
            pageSize: 25,
            isLoading: isLoading,
            emptyIcon: "network.slash",
            emptyTitle: "No listening ports found"
        ) { port, _ in
            HStack(spacing: 0) {
                Text(port.protocolType)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 80, alignment: .leading)

                Text(port.port)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 80, alignment: .leading)

                Text(port.process.isEmpty ? "—" : port.process)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axAccentBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(L10n.Literal.listen)
                    .font(AXTypography.caption)
                    .foregroundColor(.axAccentGreen)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentGreen.opacity(0.1))
                    )
                    .frame(width: 80, alignment: .leading)

                firewallStatusForPort(port)
                    .frame(width: 100, alignment: .leading)

                portActions(port)
                    .frame(width: 140, alignment: .center)
            }
        }
    }

    /// Check if a listening port has a matching firewall rule
    private func firewallRuleForPort(_ port: ListeningPort) -> FirewallRule? {
        rules.first(where: {
            let rulePort = $0.port.components(separatedBy: "/").first ?? $0.port
            return rulePort == port.port && ($0.protocolType.isEmpty || $0.protocolType == port.protocolType)
        })
    }

    @ViewBuilder
    private func firewallStatusForPort(_ port: ListeningPort) -> some View {
        if let rule = firewallRuleForPort(port) {
            let isAllowed = rule.strategy == "ACCEPT"
            HStack(spacing: AXSpacing.xxs) {
                Circle()
                    .fill(isAllowed ? Color.axAccentGreen : Color.axError)
                    .frame(width: 6, height: 6)
                Text(isAllowed ? "Allowed" : "Blocked")
                    .font(AXTypography.caption2)
                    .foregroundColor(isAllowed ? .axAccentGreen : .axError)
            }
        } else {
            HStack(spacing: AXSpacing.xxs) {
                Circle()
                    .fill(Color.axTextMuted)
                    .frame(width: 6, height: 6)
                Text(L10n.Security.noRule)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
        }
    }

    @ViewBuilder
    private func portActions(_ port: ListeningPort) -> some View {
        HStack(spacing: AXSpacing.sm) {
            if let existingRule = firewallRuleForPort(port) {
                // Has a rule — show toggle action
                if existingRule.strategy == "ACCEPT" {
                    Button(action: {
                        Task {
                            // Delete the ACCEPT rule and add DROP
                            await deleteRule(existingRule)
                            let blockRule = FirewallRule(
                                protocolType: port.protocolType, port: port.port,
                                strategy: "DROP", direction: "INPUT", sourceIP: "0.0.0.0/0"
                            )
                            await addRule(blockRule)
                        }
                    }) {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 9))
                            Text(L10n.Security.block)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.axError)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(Color.axError.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        Task {
                            await deleteRule(existingRule)
                            let allowRule = FirewallRule(
                                protocolType: port.protocolType, port: port.port,
                                strategy: "ACCEPT", direction: "INPUT", sourceIP: "0.0.0.0/0"
                            )
                            await addRule(allowRule)
                        }
                    }) {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                            Text(L10n.Security.allow)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.axAccentGreen)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(Color.axAccentGreen.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .stroke(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Delete rule button
                Button(action: {
                    Task { await deleteRule(existingRule) }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.axError.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // No rule — offer Allow or Block
                Button(action: {
                    Task {
                        let allowRule = FirewallRule(
                            protocolType: port.protocolType, port: port.port,
                            strategy: "ACCEPT", direction: "INPUT", sourceIP: "0.0.0.0/0"
                        )
                        await addRule(allowRule)
                    }
                }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 9))
                        Text(L10n.Security.allow)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.axAccentGreen)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentGreen.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    Task {
                        let blockRule = FirewallRule(
                            protocolType: port.protocolType, port: port.port,
                            strategy: "DROP", direction: "INPUT", sourceIP: "0.0.0.0/0"
                        )
                        await addRule(blockRule)
                    }
                }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "hand.raised")
                            .font(.system(size: 9))
                        Text(L10n.Security.block)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.axError)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axError.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Firewall Rules Table

    private var rulesTable: some View {
        AXDataTable(
            title: "Firewall Rules",
            icon: "flame.fill",
            accentColor: .axAccentPurple,
            badgeText: "\(rules.count) rules",
            columns: [
                AXDataColumn(title: "Protocol", width: 90),
                AXDataColumn(title: "Port", width: 110),
                AXDataColumn(title: "Strategy", width: 100),
                AXDataColumn(title: "Direction", width: 100),
                AXDataColumn(title: "Source IP", width: nil),
                AXDataColumn(title: "Actions", width: 80),
            ],
            items: filteredRules,
            totalCount: rules.count,
            pageSize: 25,
            isLoading: isLoading,
            emptyIcon: "shield.slash",
            emptyTitle: "No firewall rules configured"
        ) { rule, _ in
            HStack(spacing: 0) {
                Text(rule.protocolType)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 90, alignment: .leading)

                Text(rule.port)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 110, alignment: .leading)

                strategyBadge(rule.strategy)
                    .frame(width: 100, alignment: .leading)

                Text(rule.direction == "INPUT" ? "Inbound" : "Outbound")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 100, alignment: .leading)

                Text(rule.sourceIP)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AXActionButton(label: L10n.Button.delete, icon: "trash", style: .destructive, size: .small) {
                    Task { await deleteRule(rule) }
                }
                .frame(width: 80, alignment: .center)
            }
        }
    }

    private func strategyBadge(_ strategy: String) -> some View {
        let color: Color = {
            switch strategy {
            case "ACCEPT": return .axAccentGreen
            case "DROP": return .axError
            case "DOCKER", "DOCKER-USER", "DOCKER-FORWARD", "DOCKER-CT":
                return .axAccentPurple
            default: return .axTextMuted
            }
        }()

        return Text(strategy)
            .font(AXTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxxs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.1))
            )
    }
}

// MARK: - Port Rule Sheet (Improved Design)

struct PortRuleSheet: View {
    let title: String
    let onSave: (FirewallRule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var protocolType = "tcp"
    @State private var port = ""
    @State private var sourceIP = "All"
    @State private var strategy = "ACCEPT"
    @State private var direction = "INPUT"
    @State private var specificIP = ""
    @State private var portError: String? = nil

    private let protocols = ["tcp", "udp"]
    private let strategies = ["ACCEPT", "DROP"]
    private let directions = ["INPUT", "OUTPUT"]

    private var isValid: Bool {
        !port.isEmpty && portError == nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ruleSheetHeader
            Divider().background(Color.axBorder)
            VStack(spacing: AXSpacing.xl) {
                protocolPicker
                portField
                sourceIPField
                strategyPicker
                directionPicker
            }
            .padding(AXSpacing.xl)
            Spacer()
            Divider().background(Color.axBorder)
            ruleSheetFooter
        }
        .frame(width: 460, height: 620)
        .background(Color.axBackgroundSecondary)
    }

    // MARK: - Header & Footer

    @ViewBuilder private var ruleSheetHeader: some View {
        HStack {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "shield.lefthalf.filled").font(.system(size: 18)).foregroundColor(.axAccentBlue)
                Text(title).font(AXTypography.title2).foregroundColor(.axTextPrimary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackgroundTertiary.opacity(0.5))
    }

    @ViewBuilder private var ruleSheetFooter: some View {
        HStack {
            Label("Supports ranges like 8000-9000", systemImage: "info.circle").font(AXTypography.caption).foregroundColor(.axTextMuted)
            Spacer()
            Button(L10n.Button.cancel) { dismiss() }
                .buttonStyle(PlainButtonStyle()).foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.xl).padding(.vertical, AXSpacing.sm)
            Button(action: saveRule) {
                Text(L10n.Button.confirm).font(AXTypography.headline).foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xxl).padding(.vertical, AXSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(isValid ? Color.axAccentGreen : Color.axTextMuted))
            }
            .buttonStyle(PlainButtonStyle()).disabled(!isValid)
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Form Fields

    @ViewBuilder private var protocolPicker: some View {
        formSection("Protocol") {
            HStack(spacing: AXSpacing.sm) {
                ForEach(protocols, id: \.self) { proto in
                    Button(action: { protocolType = proto }) {
                        Text(proto.uppercased()).font(.system(size: 13, weight: .semibold))
                            .foregroundColor(protocolType == proto ? .white : .axTextSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                            .background(segmentBackground(selected: protocolType == proto))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder private var portField: some View {
        formSection(L10n.Field.port) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                TextField("e.g. 80, 443 or 8000-9000", text: $port)
                    .textFieldStyle(.plain).font(.system(size: 14, weight: .medium, design: .monospaced))
                    .padding(AXSpacing.md)
                    .background(RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axBackgroundTertiary)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(portError != nil ? Color.axError : Color.axBorder, lineWidth: 1)))
                    .onChange(of: port) { _, newValue in
                        let filtered = newValue.filter { $0.isASCII && ($0.isNumber || $0 == "," || $0 == "-" || $0 == ":") }
                        if filtered != newValue { port = filtered; portError = "Only English digits (0-9), commas, and hyphens allowed" }
                        else { portError = nil }
                    }
                if let error = portError { Text(error).font(AXTypography.caption2).foregroundColor(.axError) }
            }
        }
    }

    @ViewBuilder private var sourceIPField: some View {
        formSection("Source IP") {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.sm) {
                    ForEach(["All", "Specific IP"], id: \.self) { opt in
                        Button(action: { sourceIP = opt }) {
                            Text(opt).font(.system(size: 13, weight: .medium))
                                .foregroundColor(sourceIP == opt ? .white : .axTextSecondary)
                                .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                                .background(segmentBackground(selected: sourceIP == opt))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                if sourceIP == "Specific IP" {
                    TextField("Enter IP address", text: $specificIP)
                        .textFieldStyle(.plain).font(.system(size: 13, design: .monospaced)).padding(AXSpacing.md)
                        .background(RoundedRectangle(cornerRadius: AXCornerRadius.md).fill(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1)))
                }
            }
        }
    }

    @ViewBuilder private var strategyPicker: some View {
        formSection("Strategy") {
            HStack(spacing: AXSpacing.sm) {
                ForEach(strategies, id: \.self) { s in
                    Button(action: { strategy = s }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: s == "ACCEPT" ? "checkmark.circle" : "xmark.circle").font(.system(size: 12))
                            Text(s == "ACCEPT" ? "Allow" : "Deny").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(strategy == s ? .white : .axTextSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                        .background(RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(strategy == s ? (s == "ACCEPT" ? Color.axAccentGreen : Color.axError) : Color.axSurface)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(strategy == s ? Color.clear : Color.axBorder, lineWidth: 1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder private var directionPicker: some View {
        formSection("Direction") {
            HStack(spacing: AXSpacing.sm) {
                ForEach(directions, id: \.self) { d in
                    Button(action: { direction = d }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: d == "INPUT" ? "arrow.down.to.line" : "arrow.up.to.line").font(.system(size: 12))
                            Text(d == "INPUT" ? "Inbound" : "Outbound").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(direction == d ? .white : .axTextSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                        .background(segmentBackground(selected: direction == d))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder private func formSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(label).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextMuted).textCase(.uppercase)
            content()
        }
    }

    private func segmentBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.md)
            .fill(selected ? Color.axAccentBlue : Color.axSurface)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(selected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1))
    }

    private func saveRule() {
        let resolvedSourceIP = sourceIP == "All" ? "0.0.0.0/0" : specificIP
        let rule = FirewallRule(
            protocolType: protocolType,
            port: port,
            strategy: strategy,
            direction: direction,
            sourceIP: resolvedSourceIP
        )
        onSave(rule)
    }
}
