//
//  DomainSection.swift
//  AevonX
//
//  Unified domain management section — merges Domain & DNS + Advanced Domain
//  Internal tabs: Overview, Aliases, Subdomains, DNS, Redirects
//

import SwiftUI
import AevonXCore

struct DomainSection: View {
    @ObservedObject var viewModel: AdvancedDomainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Domain Management", icon: "globe.americas.fill")

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(AdvancedDomainViewModel.DomainTab.allCases) { tab in
                        tabButton(tab)
                    }
                }
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)

                switch viewModel.selectedTab {
                case .aliases: aliasesContent
                case .subdomains: subdomainsContent
                case .dns: dnsContent
                case .redirects: redirectsContent
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadAliases() } }
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: AdvancedDomainViewModel.DomainTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) { viewModel.selectedTab = tab }
            switch tab {
            case .aliases: Task { await viewModel.loadAliases() }
            case .subdomains: Task { await viewModel.loadSubdomains() }
            case .dns: Task { await viewModel.lookupDNS() }
            case .redirects: break
            }
        }) {
            VStack(spacing: 4) {
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(viewModel.selectedTab == tab ? .axAccentBlue : .axTextSecondary)
                Rectangle()
                    .fill(viewModel.selectedTab == tab ? Color.axAccentBlue : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Aliases

    private var aliasesContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Primary domain display
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.axWarning)
                Text("Primary Domain")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextMuted)
            }

            HStack {
                Text(viewModel.domain)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text("PRIMARY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.axSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.axSuccess.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axSuccess.opacity(0.2), lineWidth: 1))

            // Aliases
            AXConfigCard(icon: "link.badge.plus", title: "Domain Aliases (\(viewModel.aliases.count))", subtitle: "Additional domains pointing to this site") {
                VStack(spacing: AXSpacing.sm) {
                    HStack {
                        TextField("alias.example.com", text: $viewModel.newAlias)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        Button(action: { Task { await viewModel.addAlias() } }) {
                            Label("Add Alias", systemImage: "plus.circle.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(viewModel.newAlias.isEmpty)
                    }

                    if viewModel.aliases.isEmpty && !viewModel.isLoading {
                        AXPlaceholder(icon: "link", title: "No aliases configured")
                    } else {
                        ForEach(viewModel.aliases, id: \.self) { alias in
                            HStack {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axAccentBlue.opacity(0.6))
                                Text(alias)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                                Button(action: { Task { await viewModel.removeAlias(alias) } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.axError.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subdomains

    private var subdomainsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXConfigCard(icon: "network", title: "Subdomains", subtitle: "Sub-sites under \(viewModel.domain)") {
                VStack(spacing: AXSpacing.sm) {
                    HStack {
                        HStack(spacing: 0) {
                            TextField("blog", text: $viewModel.newSubdomain)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(maxWidth: 200)
                            Text(".\(viewModel.domain)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                                .padding(.leading, 4)
                        }
                        Spacer()
                        Button(action: { Task { await viewModel.createSubdomain() } }) {
                            Label("Create", systemImage: "plus.circle.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(viewModel.newSubdomain.isEmpty)
                    }

                    if viewModel.subdomains.isEmpty && !viewModel.isLoading {
                        AXPlaceholder(icon: "network", title: "No subdomains found")
                    } else {
                        ForEach(viewModel.subdomains) { sub in
                            HStack {
                                Circle()
                                    .fill(sub.isActive ? Color.axSuccess : Color.axTextMuted)
                                    .frame(width: 6, height: 6)
                                Text(sub.fullDomain)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                                Text(sub.isActive ? "Active" : "Inactive")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(sub.isActive ? .axSuccess : .axTextMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background((sub.isActive ? Color.axSuccess : Color.axTextMuted).opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
    }

    // MARK: - DNS

    private var dnsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text("DNS Records for \(viewModel.domain)")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: { Task { await viewModel.lookupDNS() } }) {
                    Label(viewModel.isLoading ? "Loading..." : "Lookup", systemImage: "magnifyingglass")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(viewModel.isLoading)
            }

            if viewModel.dnsRecords.isEmpty && !viewModel.isLoading {
                EmptyStateCard(icon: "globe", title: "No DNS Data", message: "Click Lookup to query DNS records")
            } else {
                // Group by type
                let grouped = Dictionary(grouping: viewModel.dnsRecords, by: { $0.type })
                ForEach(["A", "CNAME", "MX", "NS", "TXT"], id: \.self) { type in
                    if let records = grouped[type] {
                        AXConfigCard(icon: dnsIcon(type), title: "\(type) Records (\(records.count))", subtitle: dnsDesc(type)) {
                            VStack(spacing: 4) {
                                ForEach(records) { record in
                                    HStack {
                                        Text(record.value)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.axTextPrimary)
                                            .textSelection(.enabled)
                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Redirects

    private var redirectsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXConfigCard(icon: "arrow.uturn.right", title: "WWW Redirect", subtitle: "Choose canonical URL format") {
                HStack(spacing: AXSpacing.md) {
                    wwwButton(toWWW: true, icon: "arrow.right", color: .axAccentBlue)
                    wwwButton(toWWW: false, icon: "arrow.left", color: .orange)
                }
            }
        }
    }

    private func wwwButton(toWWW: Bool, icon: String, color: Color) -> some View {
        let from = toWWW ? viewModel.domain : "www.\(viewModel.domain)"
        let to = toWWW ? "www.\(viewModel.domain)" : viewModel.domain
        return Button(action: { Task { await viewModel.setWWWRedirect(toWWW: toWWW) } }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(toWWW ? "Force WWW" : "Force non-WWW")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text("\(from) → \(to)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.md)
            .background(color.opacity(0.06))
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private func dnsIcon(_ type: String) -> String {
        switch type {
        case "A": return "server.rack"
        case "CNAME": return "arrow.right.arrow.left"
        case "MX": return "envelope.fill"
        case "NS": return "network"
        default: return "doc.text"
        }
    }

    private func dnsDesc(_ type: String) -> String {
        switch type {
        case "A": return "Points to IP address"
        case "CNAME": return "Alias to another domain"
        case "MX": return "Mail server records"
        case "NS": return "Name server records"
        default: return ""
        }
    }
}
