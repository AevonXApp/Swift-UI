//
//  WebsiteTableView.swift
//  AevonX
//
//  Card grid view displaying websites with filter bar
//

import SwiftUI

// MARK: - Filter Options

enum WebsiteFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case online = "Online"
    case offline = "Offline"
    case sslSecured = "SSL"
    case php = "PHP"
    case nodejs = "Node.js"
    case staticSite = "Static"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "globe"
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.circle.fill"
        case .sslSecured: return "lock.fill"
        case .php: return "chevron.left.forwardslash.chevron.right"
        case .nodejs: return "cube.fill"
        case .staticSite: return "doc.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .axAccentBlue
        case .online: return .axSuccess
        case .offline: return .axError
        case .sslSecured: return .axAccentGreen
        case .php: return .axAccentPurple
        case .nodejs: return .green
        case .staticSite: return .orange
        }
    }
}

// MARK: - Website Grid View

struct WebsiteTableView: View {
    let websites: [WebsiteInfo]
    let onSelect: (WebsiteInfo) -> Void
    let onToggle: (WebsiteInfo) -> Void
    let onDeploy: (WebsiteInfo) -> Void
    let onDelete: (WebsiteInfo) -> Void
    let onLogs: (WebsiteInfo) -> Void
    let onConfig: (WebsiteInfo) -> Void
    let onSSL: (WebsiteInfo) -> Void
    let onClone: (WebsiteInfo) -> Void
    let onBackup: (WebsiteInfo) -> Void
    
    @State private var activeFilter: WebsiteFilter = .all

    // Grid columns
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: AXSpacing.md)
    ]
    
    private var filteredWebsites: [WebsiteInfo] {
        switch activeFilter {
        case .all: return websites
        case .online: return websites.filter { $0.status == .online }
        case .offline: return websites.filter { $0.status != .online }
        case .sslSecured: return websites.filter { $0.sslEnabled }
        case .php: return websites.filter { $0.runtime == .php }
        case .nodejs: return websites.filter { $0.runtime == .nodejs }
        case .staticSite: return websites.filter { $0.runtime == .`static` }
        }
    }

    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Filter Bar
            filterBar
            
            // Grid
            ScrollView(showsIndicators: false) {
                if filteredWebsites.isEmpty {
                    emptyFilterView
                } else {
                    LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                        ForEach(filteredWebsites) { website in
                            WebsiteCard(
                                website: website,
                                onToggle: { onToggle(website) },
                                onDeploy: { onDeploy(website) },
                                onDelete: { onDelete(website) },
                                onLogs: { onLogs(website) },
                                onConfig: { onConfig(website) },
                                onSSL: { onSSL(website) },
                                onClone: { onClone(website) },
                                onBackup: { onBackup(website) },
                                onSelect: { onSelect(website) }
                            )
                        }
                    }
                    .padding(.bottom, AXSpacing.xl)
                }
            }
        }
        .padding(.horizontal, AXSpacing.xl)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(WebsiteFilter.allCases) { filter in
                    let count = countFor(filter)
                    let isActive = activeFilter == filter
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            activeFilter = filter
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(AXTypography.caption2).fontWeight(.bold)
                            
                            Text(filter.rawValue)
                                .font(AXTypography.footnote).fontWeight(.semibold)
                            
                            if count > 0 || filter == .all {
                                Text("\(count)")
                                    .font(AXTypography.caption2).fontWeight(.heavy)
                                    .foregroundColor(isActive ? .white.opacity(0.9) : filter.color.opacity(0.7))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule()
                                            .fill(isActive ? Color.white.opacity(0.2) : filter.color.opacity(0.1))
                                    )
                            }
                        }
                        .foregroundColor(isActive ? .white : .axTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isActive ? filter.color : Color.axSurface)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isActive ? Color.clear : Color.axBorder.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Empty Filter State
    
    private var emptyFilterView: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextMuted)
            
            Text("No websites match '\(activeFilter.rawValue)'")
                .font(AXTypography.callout).fontWeight(.medium)
                .foregroundColor(.axTextSecondary)
            
            Button(action: {
                withAnimation { activeFilter = .all }
            }) {
                Text(L10n.Websites.showAll)
                    .font(AXTypography.footnote).fontWeight(.semibold)
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper
    
    private func countFor(_ filter: WebsiteFilter) -> Int {
        switch filter {
        case .all: return websites.count
        case .online: return websites.filter { $0.status == .online }.count
        case .offline: return websites.filter { $0.status != .online }.count
        case .sslSecured: return websites.filter { $0.sslEnabled }.count
        case .php: return websites.filter { $0.runtime == .php }.count
        case .nodejs: return websites.filter { $0.runtime == .nodejs }.count
        case .staticSite: return websites.filter { $0.runtime == .`static` }.count
        }
    }
}
