//
//  DBDetailSidebar.swift
//  AevonX
//
//  Database detail sidebar using AXSidebarContainer + AXSidebarRow
//  for full design system compliance with glassmorphism background,
//  colored icon badges, accent lines, and active dot indicators.
//

import SwiftUI
import AevonXCoreBridge

struct DBDetailSidebar: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    var onBack: () -> Void

    @State private var sidebarTableSearch = ""

    var body: some View {
        AXSidebarContainer(
            width: 240,
            header: { sidebarHeader },
            items: { sidebarItems },
            footer: { sidebarFooter }
        )
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            // Back button — compact, left-aligned
            HStack(spacing: AXSpacing.xxs) {
                Button(action: onBack) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "chevron.left")
                            .font(AXTypography.caption2).fontWeight(.bold)
                        Text(L10n.Button.back)
                            .font(AXTypography.footnote).fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                Spacer()
            }

            // Database icon + name — left-aligned
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [Color.axAccentBlue.opacity(0.25), Color.axAccentBlue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axAccentBlue.opacity(0.15), lineWidth: 1)
                        )
                    Image(systemName: "cylinder.split.1x2")
                        .font(AXTypography.headline)
                        .foregroundColor(.axAccentBlue)
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(viewModel.database.name)
                        .font(AXTypography.headline).fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    HStack(spacing: AXSpacing.xs) {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 5, height: 5)
                        Text("\(viewModel.database.type.displayName) \(viewModel.database.version ?? "")")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.top, AXSpacing.lg)
        .padding(.bottom, AXSpacing.md)
    }

    // MARK: - Navigation Items

    @ViewBuilder
    private var sidebarItems: some View {
        // Section header
        Text("NAVIGATION")
            .font(AXTypography.caption2).fontWeight(.heavy)
            .foregroundColor(.axTextMuted.opacity(0.5))
            .tracking(1.5)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.top, AXSpacing.xs)
            .padding(.bottom, AXSpacing.xxs)

        ForEach(DatabaseDetailSection.allCases, id: \.self) { section in
            AXSidebarRow(
                icon: section.iconName,
                title: section.rawValue,
                color: colorFor(section),
                isSelected: viewModel.currentSection == section
            ) {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.currentSection = section
                }
            }
            .overlay(alignment: .trailing) {
                if let badge = badgeFor(section) {
                    Text(badge)
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(colorFor(section))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(colorFor(section).opacity(0.12))
                        .cornerRadius(AXCornerRadius.sm)
                        .padding(.trailing, AXSpacing.sm)
                }
            }
        }

        // Quick actions section
        Rectangle()
            .fill(Color.axBorder.opacity(0.25))
            .frame(height: 1)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.sm)

        Text("QUICK ACTIONS")
            .font(AXTypography.caption2).fontWeight(.heavy)
            .foregroundColor(.axTextMuted.opacity(0.5))
            .tracking(1.5)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.bottom, AXSpacing.xxs)

        Button {
            viewModel.showCreateTable = true
            viewModel.currentSection = .tables
        } label: {
            quickActionRow(icon: "plus.rectangle", title: L10n.Database.createTable, color: .axAccentGreen)
        }
        .buttonStyle(.plain)

        Button {
            viewModel.currentSection = .queryConsole
        } label: {
            quickActionRow(icon: "terminal", title: "Run Query", color: .axInfo)
        }
        .buttonStyle(.plain)

        Button {
            viewModel.currentSection = .backup
        } label: {
            quickActionRow(icon: "arrow.down.doc", title: "New Backup", color: .axWarning)
        }
        .buttonStyle(.plain)

        Button {
            viewModel.showImportSQL = true
        } label: {
            quickActionRow(icon: "arrow.up.doc", title: L10n.Database.importSQL, color: .purple)
        }
        .buttonStyle(.plain)

        // Tables list section
        if !viewModel.tables.isEmpty {
            Rectangle()
                .fill(Color.axBorder.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.sm)

            Text("TABLES")
                .font(AXTypography.caption2).fontWeight(.heavy)
                .foregroundColor(.axTextMuted.opacity(0.5))
                .tracking(1.5)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.bottom, AXSpacing.xxs)

            // Table search
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                TextField("Filter tables...", text: $sidebarTableSearch)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(.plain)
                if !sidebarTableSearch.isEmpty {
                    Button { sidebarTableSearch = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 4)
            .background(Color.axSurface.opacity(0.4))
            .cornerRadius(AXCornerRadius.sm)
            .padding(.horizontal, AXSpacing.sm)

            // Filtered table list
            let filtered = sidebarTableSearch.isEmpty
                ? Array(viewModel.tables.prefix(20))
                : viewModel.tables.filter { $0.name.localizedCaseInsensitiveContains(sidebarTableSearch) }

            ForEach(filtered, id: \.name) { table in
                Button {
                    viewModel.currentSection = .tables
                    viewModel.selectedTable = table
                    Task { await viewModel.loadTableData() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "tablecells")
                            .font(AXTypography.caption2)
                            .foregroundColor(.mint.opacity(0.6))
                        Text(table.name)
                            .font(AXTypography.footnote)
                            .foregroundColor(viewModel.selectedTable?.name == table.name ? .axAccentBlue : .axTextSecondary)
                            .lineLimit(1)
                        Spacer()
                        if table.rowCount > 0 {
                            Text("\(table.rowCount)")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        viewModel.selectedTable?.name == table.name
                            ? Color.axAccentBlue.opacity(0.08)
                            : Color.clear
                    )
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            if viewModel.tables.count > 20 && sidebarTableSearch.isEmpty {
                Text("+ \(viewModel.tables.count - 20) more...")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.top, AXSpacing.xxs)
            }
        }
    }

    private func quickActionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.07))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(AXTypography.footnote)
                    .foregroundColor(color.opacity(0.7))
            }
            Text(title)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 5)
    }

    // MARK: - Footer

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.axBorder.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.sm)

            HStack(spacing: AXSpacing.lg) {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "internaldrive")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                    Text(AXFormatter.formatSizeMB(viewModel.database.size))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "tablecells")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                    Text("\(viewModel.tables.count) tables")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "bolt.horizontal")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                    Text("\(viewModel.database.connections)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
        }
    }

    // MARK: - Helpers

    private func colorFor(_ section: DatabaseDetailSection) -> Color {
        switch section {
        case .overview: return .axAccentBlue
        case .tables: return .mint
        case .queryConsole: return .purple
        case .backup: return .axWarning
        case .activityLog: return .indigo
        case .importSQL: return .purple
        }
    }

    private func badgeFor(_ section: DatabaseDetailSection) -> String? {
        switch section {
        case .tables:
            return viewModel.tables.isEmpty ? nil : "\(viewModel.tables.count)"
        case .activityLog:
            return viewModel.activityLog.isEmpty ? nil : "\(viewModel.activityLog.count)"
        case .queryConsole:
            return viewModel.queryHistory.isEmpty ? nil : "\(viewModel.queryHistory.count)"
        default:
            return nil
        }
    }
}
