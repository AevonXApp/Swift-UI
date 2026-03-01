//
//  AXDataTable.swift
//  AevonX
//
//  Generic, reusable data table for structured data.
//  Provides: header with badge+optional trailing content, column definitions,
//  zebra rows, pagination, loading/empty states, status bar.
//
//  Parent is responsible for filtering/searching items before passing them in.
//

import SwiftUI

// MARK: - Column Definition

struct AXDataColumn: Identifiable {
    let id = UUID()
    let title: String
    let width: CGFloat?          // nil = flexible
    var alignment: Alignment = .leading
}

// MARK: - AXDataTable

struct AXDataTable<Item: Identifiable, RowContent: View, TrailingContent: View>: View {
    let title: String
    let icon: String
    var iconColor: Color? = nil
    var accentColor: Color = .axAccentBlue
    var badgeText: String? = nil
    let columns: [AXDataColumn]
    let items: [Item]
    var totalCount: Int? = nil    // original count before parent filtering
    var pageSize: Int = 25
    var isLoading: Bool = false
    var emptyIcon: String = "tray"
    var emptyTitle: String = "No items found"
    @ViewBuilder let rowContent: (Item, Int) -> RowContent
    @ViewBuilder let trailingContent: () -> TrailingContent

    // Pagination
    @State private var currentPage = 1

    private var pagedItems: [Item] {
        Array(items.prefix(currentPage * pageSize))
    }

    private var hasMorePages: Bool {
        pagedItems.count < items.count
    }

    var body: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                headerRow

                Divider().background(Color.axBorder)

                // Column headers
                if !columns.isEmpty {
                    columnHeaderRow
                    Divider().background(Color.axBorder)
                }

                // Body
                if isLoading {
                    AXLoadingState(message: "Loading…", style: .inline)
                } else if items.isEmpty {
                    AXPlaceholder(icon: emptyIcon, title: emptyTitle)
                } else {
                    // Rows
                    ForEach(Array(pagedItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            rowContent(item, index)
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))

                            if index < pagedItems.count - 1 {
                                Divider().background(Color.axBorder.opacity(0.5))
                            }
                        }
                    }

                    // Pagination
                    if hasMorePages {
                        Button(action: { currentPage += 1 }) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 12))
                                Text("Load More (\(items.count - pagedItems.count) remaining)")
                                    .font(AXTypography.caption)
                            }
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AXSpacing.md)
                            .background(accentColor.opacity(0.05))
                        }
                        .buttonStyle(.plain)
                    }

                    // Status bar
                    statusBar
                }
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            AXSectionTitle(title: title, icon: icon, iconColor: iconColor ?? accentColor) {
                if let badge = badgeText {
                    AXBadge(text: badge, color: accentColor, style: .soft)
                }
            }
            trailingContent()
            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }

    // MARK: - Column Headers

    private var columnHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(columns) { col in
                if let w = col.width {
                    Text(col.title)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: w, alignment: col.alignment)
                } else {
                    Text(col.title)
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity, alignment: col.alignment)
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.5))
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)

            Text("Showing \(pagedItems.count) of \(items.count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextMuted)

            if let total = totalCount, total != items.count {
                Text("(\(total) total)")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.2))
    }
}

// MARK: - Convenience init (no trailing content)

extension AXDataTable where TrailingContent == EmptyView {
    init(
        title: String,
        icon: String,
        iconColor: Color? = nil,
        accentColor: Color = .axAccentBlue,
        badgeText: String? = nil,
        columns: [AXDataColumn],
        items: [Item],
        totalCount: Int? = nil,
        pageSize: Int = 25,
        isLoading: Bool = false,
        emptyIcon: String = "tray",
        emptyTitle: String = "No items found",
        @ViewBuilder rowContent: @escaping (Item, Int) -> RowContent
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.accentColor = accentColor
        self.badgeText = badgeText
        self.columns = columns
        self.items = items
        self.totalCount = totalCount
        self.pageSize = pageSize
        self.isLoading = isLoading
        self.emptyIcon = emptyIcon
        self.emptyTitle = emptyTitle
        self.rowContent = rowContent
        self.trailingContent = { EmptyView() }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AXDataTable(
            title: "Example Ports",
            icon: "antenna.radiowaves.left.and.right",
            badgeText: "3 active",
            columns: [
                AXDataColumn(title: "Protocol", width: 80),
                AXDataColumn(title: "Port", width: 80),
                AXDataColumn(title: "Service", width: nil),
            ],
            items: [
                PreviewPort(proto: "tcp", port: "80", service: "nginx"),
                PreviewPort(proto: "tcp", port: "443", service: "nginx"),
                PreviewPort(proto: "tcp", port: "22", service: "sshd"),
            ]
        ) { port, _ in
            HStack(spacing: 0) {
                Text(port.proto)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 80, alignment: .leading)
                Text(port.port)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 80, alignment: .leading)
                Text(port.service)
                    .font(.system(size: 12))
                    .foregroundColor(.axAccentBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
    .background(Color.axBackground)
}

private struct PreviewPort: Identifiable {
    let id = UUID()
    let proto: String
    let port: String
    let service: String
}
