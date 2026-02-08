//
//  DBTableDataView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBTableDataView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            dataToolbar
            Divider()

            if viewModel.isLoading && viewModel.browseResult == nil {
                Spacer()
                ProgressView()
                Spacer()
            } else if let result = viewModel.browseResult {
                if result.rows.isEmpty {
                    emptyState
                } else {
                    dataTable(result)
                }
            } else {
                emptyState
            }

            if viewModel.browseResult?.rows.isEmpty == false {
                Divider()
                paginationBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if viewModel.tableStructure == nil {
                await viewModel.loadTableStructure()
            }
            if viewModel.browseResult == nil {
                await viewModel.loadTableData()
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Image(systemName: "list.dash.header.rectangle")
                .font(.system(size: 32))
                .foregroundColor(.axTextMuted)
                .padding(.bottom, AXSpacing.sm)
            Text("No Data Found")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Button {
                viewModel.showAddRow = true
            } label: {
                Text("Insert Row")
            }
            .padding(.top, AXSpacing.md)
            Spacer()
        }
    }

    private var dataToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                // Search field
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    TextField("Search rows...", text: $viewModel.dataSearchText)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(.plain)
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 14, height: 14)
                    }
                    if !viewModel.dataSearchText.isEmpty {
                        Button {
                            Task { await viewModel.clearSearch() }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(maxWidth: 250)

                // Row count
                if let result = viewModel.browseResult {
                    let tableCount = viewModel.selectedTable?.rowCount ?? 0
                    let displayCount = tableCount > 0 ? "\(tableCount) rows" : "\(result.rows.count) rows"
                    Text(displayCount)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                // Sort indicator
                if let sortCol = viewModel.sortColumn {
                    sortIndicator(sortCol)
                }

                Spacer()

                // Delete selected
                if !viewModel.selectedRows.isEmpty {
                    Button {
                        viewModel.activeAlert = .confirmDeleteSelectedRows
                    } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Delete \(viewModel.selectedRows.count)")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axError)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }

                // Add Row
                Button { viewModel.showAddRow = true } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Row")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.database.type.brandColor)
                }
                .buttonStyle(.plain)

                // Page size
                HStack(spacing: AXSpacing.xs) {
                    Text("Rows:")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: Binding(
                        get: { viewModel.pageSize },
                        set: { newSize in
                            viewModel.pageSize = newSize
                            viewModel.currentPage = 0
                            Task { await viewModel.loadTableData() }
                        }
                    )) {
                        Text("25").tag(25)
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .labelsHidden()
                    .frame(width: 70)
                }

                // Refresh
                Button {
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
        }
        .task(id: viewModel.dataSearchText) {
            guard !viewModel.dataSearchText.isEmpty else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.searchData()
        }
    }

    private func sortIndicator(_ sortCol: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Text("Sorted by")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(sortCol)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(viewModel.database.type.brandColor)
            Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                .font(.system(size: 9))
                .foregroundColor(viewModel.database.type.brandColor)
            Button {
                viewModel.sortColumn = nil
                viewModel.currentPage = 0
                Task { await viewModel.loadTableData() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(viewModel.database.type.brandColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func dataTable(_ result: QueryResult) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Column headers
                HStack(spacing: 0) {
                    // Select all checkbox
                    Button {
                        if viewModel.selectedRows.count == result.rows.count {
                            viewModel.deselectAllRows()
                        } else {
                            viewModel.selectAllRows()
                        }
                    } label: {
                        Image(systemName: viewModel.selectedRows.count == result.rows.count && !result.rows.isEmpty
                              ? "checkmark.square.fill" : "square")
                            .font(.system(size: 12))
                            .foregroundColor(viewModel.database.type.brandColor)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32)
                    .padding(.vertical, AXSpacing.sm)

                    ForEach(result.columns, id: \.self) { col in
                        Button {
                            Task { await viewModel.sortBy(col) }
                        } label: {
                            HStack(spacing: AXSpacing.xxs) {
                                Text(col)
                                    .font(AXTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.axTextSecondary)
                                if viewModel.sortColumn == col {
                                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 8))
                                        .foregroundColor(viewModel.database.type.brandColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.sm)
                    }

                    // Actions header
                    Text("Actions")
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 70, alignment: .center)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.sm)
                }
                .background(Color.axSurface.opacity(0.8))

                Divider()

                // Data rows
                ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                    dataRow(index: index, row: row, columns: result.columns)
                }
            }
        }
    }

    private func dataRow(index: Int, row: [String?], columns: [String]) -> some View {
        let isSelected = viewModel.selectedRows.contains(index)
        return HStack(spacing: 0) {
            // Checkbox
            Button {
                viewModel.toggleRowSelection(index)
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? viewModel.database.type.brandColor : .axTextMuted)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
            .padding(.vertical, AXSpacing.xs)

            ForEach(Array(row.enumerated()), id: \.offset) { colIdx, value in
                Text(value ?? "NULL")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(value != nil ? .axTextPrimary : .axTextMuted)
                    .lineLimit(1)
                    .frame(minWidth: 120, alignment: .leading)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
            }

            // Row action buttons
            HStack(spacing: AXSpacing.xs) {
                Button {
                    viewModel.startEditingRow(index)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.database.type.brandColor)
                        .frame(width: 22, height: 22)
                        .background(viewModel.database.type.brandColor.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.activeAlert = .confirmDeleteRow(index)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.axError)
                        .frame(width: 22, height: 22)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.sm)
        }
        .background(isSelected ? viewModel.database.type.brandColor.opacity(0.08) : (index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3)))
        .contextMenu {
            Button {
                viewModel.startEditingRow(index)
            } label: {
                Label("Edit Row", systemImage: "pencil")
            }
            Button {
                let values = row.map { $0 ?? "NULL" }.joined(separator: "\t")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(values, forType: .string)
            } label: {
                Label("Copy Row Values", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.activeAlert = .confirmDeleteRow(index)
            } label: {
                Label("Delete Row", systemImage: "trash")
            }
        }
    }

    private var paginationBar: some View {
        HStack {
            Text("Showing \(viewModel.browseResult?.rows.count ?? 0) rows (offset \(viewModel.currentPage * viewModel.pageSize))")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                Button {
                    viewModel.currentPage = 0
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.left.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                Button {
                    Task { await viewModel.previousPage() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                Text("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(minWidth: 80)

                Button {
                    Task { await viewModel.nextPage() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)

                Button {
                    viewModel.currentPage = max(0, viewModel.totalPages - 1)
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)
            }
            .foregroundColor(viewModel.database.type.brandColor)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}
