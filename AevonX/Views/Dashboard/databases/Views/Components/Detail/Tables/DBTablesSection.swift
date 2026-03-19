//
//  DBTablesSection.swift
//  AevonX
//
//  Redesigned table browser with premium sidebar using AXSidebarContainer,
//  enhanced table header with badges and quick actions,
//  and styled sub-tab navigation.
//

import SwiftUI
import AevonXCoreBridge

struct DBTablesSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        HSplitView {
            tableListPanel
                .frame(minWidth: 220, maxWidth: 300)

            if let _ = viewModel.selectedTable {
                tableDetailPanel
            } else {
                tableEmptyState
            }
        }
        .sheet(isPresented: $viewModel.showCreateTable) {
            DBCreateTableView(viewModel: viewModel)
        }
    }

    // MARK: - Left Panel: Table List using AXSidebarContainer

    private var tableListPanel: some View {
        AXSidebarContainer(
            width: 260,
            header: {
                // Search + Create
                HStack(spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "magnifyingglass")
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextMuted)
                        TextField("Search tables...", text: $viewModel.tableSearchText)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextPrimary)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs + 2)
                    .background(Color.axBackground.opacity(0.6))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                    )

                    Button { viewModel.showCreateTable = true } label: {
                        Image(systemName: "plus")
                            .font(AXTypography.footnote).fontWeight(.bold)
                            .foregroundColor(.axAccentGreen)
                            .frame(width: 28, height: 28)
                            .background(Color.axAccentGreen.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.top, AXSpacing.md)
                .padding(.bottom, AXSpacing.sm)
            },
            items: {
                if viewModel.filteredTables.isEmpty {
                    VStack(spacing: AXSpacing.sm) {
                        Spacer(minLength: 40)
                        Image(systemName: "tablecells")
                            .font(AXTypography.title)
                            .foregroundColor(.axTextMuted.opacity(0.3))
                        Text("No tables found")
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextMuted)
                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.filteredTables) { table in
                        PremiumTableRow(
                            table: table,
                            isSelected: viewModel.selectedTable?.name == table.name,
                            structure: viewModel.tableStructure
                        ) {
                            viewModel.selectTable(table)
                        }
                        .overlay(alignment: .trailing) {
                            AXActionMenu(sections: [
                                AXMenuSection("Info", items: [
                                    AXMenuItem("Copy Table Name", icon: "doc.on.doc", color: .axAccentBlue) {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(table.name, forType: .string)
                                        GlobalToastManager.shared.showSuccess("Table name copied")
                                    },
                                ]),
                                AXMenuSection("Maintenance", items: [
                                    AXMenuItem("Optimize Table", icon: "wand.and.stars", color: .orange) {
                                        Task { await viewModel.optimizeTable(table.name) }
                                    },
                                    AXMenuItem("Analyze Table", icon: "magnifyingglass", color: .cyan) {
                                        Task { await viewModel.analyzeTable(table.name) }
                                    },
                                ]),
                                AXMenuSection(items: [
                                    AXMenuItem("Truncate Table", icon: "xmark.bin", isDestructive: true) {
                                        viewModel.confirmTruncateTable(table.name)
                                    },
                                    AXMenuItem("Drop Table", icon: "trash", isDestructive: true) {
                                        viewModel.confirmDropTable(table.name)
                                    },
                                ]),
                            ], triggerIcon: "ellipsis", triggerSize: 20)
                            .padding(.trailing, AXSpacing.sm)
                        }
                    }
                }
            },
            footer: {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.axBorder.opacity(0.25))
                        .frame(height: 1)
                        .padding(.horizontal, AXSpacing.sm)
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "tablecells")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted.opacity(0.5))
                        Text("\(viewModel.tables.count) tables")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted.opacity(0.5))
                        Spacer()
                        Text(AXFormatter.formatSizeMB(viewModel.database.size))
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted.opacity(0.5))
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                }
            }
        )
    }

    // MARK: - Empty State

    private var tableEmptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axAccentBlue.opacity(0.05))
                    .frame(width: 72, height: 72)
                Image(systemName: "tablecells.badge.ellipsis")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextMuted.opacity(0.4))
            }
            VStack(spacing: AXSpacing.xs) {
                Text("Select a Table")
                    .font(AXTypography.title2).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text("Choose a table from the sidebar to view its structure and data")
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextMuted)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: AXSpacing.md) {
                Button {
                    if let first = viewModel.tables.first {
                        viewModel.selectTable(first)
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "tablecells")
                            .font(AXTypography.footnote)
                        Text("Open First Table")
                            .font(AXTypography.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.tables.isEmpty)

                Button {
                    viewModel.showCreateTable = true
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "plus")
                            .font(AXTypography.footnote)
                        Text("Create New")
                            .font(AXTypography.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentGreen)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentGreen.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axAccentGreen.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }

    // MARK: - Right Panel: Table Detail

    private var tableDetailPanel: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            HStack(spacing: AXSpacing.md) {
                // Table icon + name
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.mint.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "tablecells")
                            .font(AXTypography.body)
                            .foregroundColor(.mint)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(viewModel.selectedTable?.name ?? "")
                            .font(AXTypography.title3).fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                        HStack(spacing: AXSpacing.sm) {
                            if let table = viewModel.selectedTable {
                                Text("\(table.rowCount) rows")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                if let structure = viewModel.tableStructure {
                                    Text("·")
                                        .foregroundColor(.axTextMuted)
                                    Text("\(structure.columns.count) cols")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Styled tab switcher
                HStack(spacing: 2) {
                    ForEach(TableDetailTab.allCases) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.tableDetailTab = tab
                            }
                        } label: {
                            HStack(spacing: AXSpacing.xxs) {
                                Image(systemName: iconFor(tab))
                                    .font(AXTypography.caption)
                                Text(tab.rawValue)
                                    .font(AXTypography.footnote).fontWeight(viewModel.tableDetailTab == tab ? .semibold : .regular)
                            }
                            .foregroundColor(viewModel.tableDetailTab == tab ? .axTextPrimary : .axTextMuted)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.xs + 1)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(viewModel.tableDetailTab == tab ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.md)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.3))

            Rectangle()
                .fill(Color.axBorder.opacity(0.3))
                .frame(height: 1)

            // Content
            switch viewModel.tableDetailTab {
            case .structure:
                DBTableStructureView(viewModel: viewModel)
            case .data:
                DBTableDataView(viewModel: viewModel)
            case .indexes:
                DBTableIndexesView(viewModel: viewModel)
            }
        }
        .background(Color.axBackground)
    }

    private func iconFor(_ tab: TableDetailTab) -> String {
        switch tab {
        case .structure: return "list.bullet.rectangle"
        case .data: return "tablecells"
        case .indexes: return "list.bullet.indent"
        }
    }
}

// MARK: - Premium Table Row

private struct PremiumTableRow: View {
    let table: TableInfo
    let isSelected: Bool
    let structure: TableStructure?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Table icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isSelected
                                ? Color.mint.opacity(0.15)
                                : Color.mint.opacity(isHovered ? 0.10 : 0.07)
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: "tablecells")
                        .font(AXTypography.subheadline).fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(
                            isSelected ? .mint : .mint.opacity(isHovered ? 0.85 : 0.7)
                        )
                }

                // Name + size
                VStack(alignment: .leading, spacing: 2) {
                    Text(table.name)
                        .font(AXTypography.callout).fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
                        .lineLimit(1)
                    Text(AXFormatter.formatBytes(table.dataSize))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                // Row count badge
                if table.rowCount > 0 {
                    Text("\(table.rowCount)")
                        .font(AXTypography.caption).fontWeight(.bold)
                        .foregroundColor(isSelected ? .mint : .axTextMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.mint.opacity(0.12) : Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }

            }
            .padding(.leading, AXSpacing.sm)
            .padding(.trailing, AXSpacing.xxl)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        isSelected
                            ? Color.mint.opacity(0.08)
                            : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear)
                    )
            )
            .overlay(
                HStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mint)
                            .frame(width: 3)
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
