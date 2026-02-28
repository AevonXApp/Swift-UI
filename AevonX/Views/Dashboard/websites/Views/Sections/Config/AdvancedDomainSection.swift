//
//  AdvancedDomainSection.swift
//  AevonX
//
//  Advanced domain management: aliases, subdomains, DNS, redirects
//

import SwiftUI
import AevonXCore

struct AdvancedDomainSection: View {
    @ObservedObject var viewModel: AdvancedDomainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Advanced Domain", icon: "globe.americas.fill")

                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(AdvancedDomainViewModel.DomainTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch viewModel.selectedTab {
                case .aliases: aliasesTab
                case .subdomains: subdomainsTab
                case .dns: dnsTab
                case .redirects: redirectsTab
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadAliases() } }
    }

    // MARK: - Aliases

    private var aliasesTab: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXConfigCard(icon: "link.badge.plus", title: "Domain Aliases", subtitle: "Additional domains pointing to this site") {
                VStack(spacing: AXSpacing.sm) {
                    HStack {
                        TextField("alias.example.com", text: $viewModel.newAlias)
                            .textFieldStyle(.roundedBorder)
                        Button(action: { Task { await viewModel.addAlias() } }) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    if viewModel.aliases.isEmpty && !viewModel.isLoading {
                        AXPlaceholder(icon: "link", title: "No aliases configured")
                    } else {
                        ForEach(viewModel.aliases, id: \.self) { alias in
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.axAccentBlue)
                                    .font(.system(size: 12))
                                Text(alias)
                                    .font(.system(size: 13, design: .monospaced))
                                Spacer()
                                Button(action: { Task { await viewModel.removeAlias(alias) } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.axError)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .onAppear { Task { await viewModel.loadAliases() } }
    }

    // MARK: - Subdomains

    private var subdomainsTab: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXConfigCard(icon: "network", title: "Subdomains", subtitle: "Manage subdomains of \(viewModel.domain)") {
                VStack(spacing: AXSpacing.sm) {
                    HStack {
                        TextField("subdomain", text: $viewModel.newSubdomain)
                            .textFieldStyle(.roundedBorder)
                        Text(".\(viewModel.domain)")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextMuted)
                        Button(action: { Task { await viewModel.createSubdomain() } }) {
                            Label("Create", systemImage: "plus.circle.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    ForEach(viewModel.subdomains) { sub in
                        HStack {
                            Circle()
                                .fill(sub.isActive ? Color.axSuccess : Color.axTextMuted)
                                .frame(width: 6, height: 6)
                            Text(sub.fullDomain)
                                .font(.system(size: 13, design: .monospaced))
                            Spacer()
                            Text(sub.isActive ? "Active" : "Inactive")
                                .font(.system(size: 10))
                                .foregroundColor(sub.isActive ? .axSuccess : .axTextMuted)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .onAppear { Task { await viewModel.loadSubdomains() } }
    }

    // MARK: - DNS

    private var dnsTab: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text("DNS Records")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { Task { await viewModel.lookupDNS() } }) {
                    Label("Lookup", systemImage: "magnifyingglass")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if viewModel.dnsRecords.isEmpty && !viewModel.isLoading {
                EmptyStateCard(icon: "globe", title: "No DNS Data", message: "Click Lookup to fetch DNS records")
            } else {
                ForEach(viewModel.dnsRecords) { record in
                    HStack {
                        Text(record.type)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                            .frame(width: 50)
                        Text(record.value)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.xs)
                }
            }
        }
    }

    // MARK: - Redirects

    private var redirectsTab: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXConfigCard(icon: "arrow.uturn.right", title: "WWW Redirect", subtitle: "Force www or non-www") {
                HStack(spacing: AXSpacing.lg) {
                    Button(action: { Task { await viewModel.setWWWRedirect(toWWW: true) } }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(.axAccentBlue)
                            Text("→ www")
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(viewModel.domain) → www.\(viewModel.domain)")
                                .font(.system(size: 9))
                                .foregroundColor(.axTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(Color.axAccentBlue.opacity(0.06))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)

                    Button(action: { Task { await viewModel.setWWWRedirect(toWWW: false) } }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            Text("→ non-www")
                                .font(.system(size: 11, weight: .semibold))
                            Text("www.\(viewModel.domain) → \(viewModel.domain)")
                                .font(.system(size: 9))
                                .foregroundColor(.axTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(Color.orange.opacity(0.06))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
