//
//  UnifiedDependencyView.swift
//  AevonX
//
//  Shared dependency list view for pip (Python) and npm/yarn (Node.js).
//  Shows installed packages with version, outdated indicators, and actions.
//

import SwiftUI

// MARK: - Dependency Item Model

struct DependencyItem: Identifiable {
    let id: String
    let name: String
    let version: String
    let latestVersion: String?
    let type: DependencyType
    var isOutdated: Bool { latestVersion != nil && latestVersion != version }

    enum DependencyType: String {
        case production = "prod"
        case dev = "dev"
        case peer = "peer"
    }
}

// MARK: - Unified Dependency View

struct UnifiedDependencyView: View {
    let title: String
    let packageManager: String  // "pip", "npm", "yarn", "pnpm"
    let dependencies: [DependencyItem]
    let accentColor: Color
    let isLoading: Bool

    var onInstall: ((String) -> Void)?
    var onUpdate: ((String) -> Void)?
    var onUninstall: ((String) -> Void)?
    var onUpdateAll: (() -> Void)?
    var onRefresh: (() async -> Void)?

    @State private var searchText: String = ""
    @State private var filterOutdated: Bool = false

    private var filteredDeps: [DependencyItem] {
        var deps = dependencies
        if filterOutdated {
            deps = deps.filter { $0.isOutdated }
        }
        if !searchText.isEmpty {
            deps = deps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return deps
    }

    private var outdatedCount: Int {
        dependencies.filter { $0.isOutdated }.count
    }

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Header
            HStack {
                Text(title)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text("\(dependencies.count) packages")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                if outdatedCount > 0 {
                    Button {
                        filterOutdated.toggle()
                    } label: {
                        Text("\(outdatedCount) outdated")
                            .font(AXTypography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(filterOutdated ? accentColor : Color.orange)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if outdatedCount > 0, let onUpdateAll = onUpdateAll {
                    AXActionButton(label: "Update All", icon: "arrow.up.circle", style: .primary, size: .small) {
                        onUpdateAll()
                    }
                }

                if let onRefresh = onRefresh {
                    AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost, size: .small) {
                        Task { await onRefresh() }
                    }
                }
            }

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.axTextMuted)
                TextField("Search packages…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(AXTypography.body)
            }
            .padding(AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)

            // Table
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if filteredDeps.isEmpty {
                AXPlaceholder(
                    icon: "shippingbox",
                    title: searchText.isEmpty ? "No Packages Found" : "No Results",
                    subtitle: searchText.isEmpty ? "Install packages via \(packageManager)" : "Try a different search"
                )
            } else {
                AXCard {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Package")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Version")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 100, alignment: .center)
                            Text("Latest")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 100, alignment: .center)
                            Text("")
                                .frame(width: 80)
                        }
                        .padding(.bottom, 6)

                        Divider()

                        ForEach(filteredDeps) { dep in
                            depRow(dep)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func depRow(_ dep: DependencyItem) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text(dep.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

                if dep.type != .production {
                    Text(dep.type.rawValue)
                        .font(.system(.caption2))
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.axTextMuted.opacity(0.15))
                        .cornerRadius(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(dep.version)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .frame(width: 100, alignment: .center)

            Group {
                if dep.isOutdated, let latest = dep.latestVersion {
                    Text(latest)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.axSuccess)
                }
            }
            .frame(width: 100, alignment: .center)

            Group {
                if dep.isOutdated, let onUpdate = onUpdate {
                    AXActionButton(label: "Update", style: .ghost, size: .small) {
                        onUpdate(dep.name)
                    }
                } else {
                    Text("")
                }
            }
            .frame(width: 80)
        }
        .padding(.vertical, 4)
    }
}
