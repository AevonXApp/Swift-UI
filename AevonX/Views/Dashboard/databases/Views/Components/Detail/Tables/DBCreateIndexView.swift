//
//  DBCreateIndexView.swift
//  AevonX
//
//  Create Index dialog with column selection,
//  index type, unique toggle, and SQL preview.
//

import SwiftUI
import AevonXCoreBridge

struct DBCreateIndexView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var indexName = ""
    @State private var selectedColumns: Set<String> = []
    @State private var isUnique = false
    @State private var indexType = "BTREE"
    @State private var isCreating = false

    private var indexTypes: [String] {
        switch viewModel.database.type {
        case .postgresql, .cockroachdb:
            return ["BTREE", "HASH", "GIN", "GiST", "BRIN"]
        case .sqlite:
            return ["BTREE"]
        default:
            return ["BTREE", "HASH", "FULLTEXT", "SPATIAL"]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            dialogHeader
            Divider().background(Color.axBorder)
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    indexNameField
                    indexTypePicker
                    uniqueToggleRow
                    columnSelectionSection
                    sqlPreviewSection
                }
                .padding(AXSpacing.lg)
            }
            Divider().background(Color.axBorder)
            footerActions
        }
        .frame(width: 520, height: 600)
        .background(Color.axBackground)
    }

    // MARK: - Header

    @ViewBuilder private var dialogHeader: some View {
        HStack {
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(Color.axAccentGreen.opacity(0.12)).frame(width: 28, height: 28)
                    Image(systemName: "list.bullet.indent").font(AXTypography.subheadline).foregroundColor(.axAccentGreen)
                }
                Text(L10n.Database.createIndex).font(AXTypography.headline).fontWeight(.bold).foregroundColor(.axTextPrimary)
            }
            Spacer()
            if let table = viewModel.selectedTable {
                Text(table.name).font(AXTypography.monoXs).fontWeight(.medium).foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, 3)
                    .background(Color.axSurface).cornerRadius(AXCornerRadius.sm)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(AXTypography.title3).foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Form Fields

    @ViewBuilder private var indexNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Database.indexName).font(AXTypography.footnote).fontWeight(.semibold).foregroundColor(.axTextSecondary)
            TextField("idx_\(viewModel.selectedTable?.name ?? "table")_...", text: $indexName)
                .font(AXTypography.monoMd).foregroundColor(.axTextPrimary).textFieldStyle(.plain)
                .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        }
    }

    @ViewBuilder private var indexTypePicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Database.indexType).font(AXTypography.footnote).fontWeight(.semibold).foregroundColor(.axTextSecondary)
            HStack(spacing: AXSpacing.sm) {
                ForEach(indexTypes, id: \.self) { type in
                    Button { indexType = type } label: {
                        Text(type).font(AXTypography.monoXs).fontWeight(.bold)
                            .foregroundColor(indexType == type ? .white : .axTextSecondary)
                            .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
                            .background(indexType == type ? Color.axAccentBlue : Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(indexType == type ? Color.axAccentBlue : Color.axBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder private var uniqueToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Database.uniqueIndex).font(AXTypography.footnote).fontWeight(.semibold).foregroundColor(.axTextSecondary)
                Text(L10n.Database.uniqueIndexDesc).font(AXTypography.caption2).foregroundColor(.axTextMuted)
            }
            Spacer()
            Toggle("", isOn: $isUnique).toggleStyle(.switch).controlSize(.small)
        }
    }

    @ViewBuilder private var columnSelectionSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                Text(L10n.Database.columnsLabel).font(AXTypography.footnote).fontWeight(.semibold).foregroundColor(.axTextSecondary)
                Spacer()
                Text(L10n.Database.selectedCount(selectedColumns.count))
                    .font(AXTypography.caption2).foregroundColor(selectedColumns.isEmpty ? .axError : .axSuccess)
            }
            if let structure = viewModel.tableStructure {
                VStack(spacing: 0) {
                    ForEach(Array(structure.columns.enumerated()), id: \.element.id) { index, col in
                        columnRow(col: col, index: index, total: structure.columns.count)
                    }
                }
                .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            }
        }
    }

    @ViewBuilder private func columnRow(col: BridgeColumnInfo, index: Int, total: Int) -> some View {
        let isSelected = selectedColumns.contains(col.name)
        Button {
            if isSelected { selectedColumns.remove(col.name) } else { selectedColumns.insert(col.name) }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(AXTypography.body).foregroundColor(isSelected ? .axAccentBlue : .axTextMuted.opacity(0.4))
                VStack(alignment: .leading, spacing: 1) {
                    Text(col.name).font(AXTypography.footnote).foregroundColor(.axTextPrimary)
                    Text(col.type).font(AXTypography.monoXxs).foregroundColor(.axTextMuted)
                }
                Spacer()
                if col.isPrimaryKey {
                    Text("PK").font(AXTypography.caption2).fontWeight(.bold).foregroundColor(.axWarning)
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(Color.axWarning.opacity(0.1)).cornerRadius(AXCornerRadius.xs)
                }
            }
            .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
            .background(isSelected ? Color.axAccentBlue.opacity(0.05) : (index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3)))
        }
        .buttonStyle(.plain)
        if index < total - 1 { Divider().background(Color.axBorder.opacity(0.3)) }
    }

    @ViewBuilder private var sqlPreviewSection: some View {
        if !selectedColumns.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack {
                    Text(L10n.Database.sqlPreview).font(AXTypography.footnote).fontWeight(.semibold).foregroundColor(.axTextSecondary)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(generateSQL(), forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.sqlCopied)
                    } label: {
                        Image(systemName: "doc.on.doc").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                }
                Text(generateSQL()).font(AXTypography.monoSm).foregroundColor(.axAccentGreen).textSelection(.enabled)
                    .padding(AXSpacing.md).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3)).cornerRadius(AXCornerRadius.md)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder private var footerActions: some View {
        HStack(spacing: AXSpacing.md) {
            Button { dismiss() } label: {
                Text(L10n.Button.cancel).font(AXTypography.subheadline).fontWeight(.semibold).foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Button {
                Task {
                    isCreating = true
                    let sql = generateSQL()
                    viewModel.queryText = sql
                    await viewModel.executeQuery()
                    isCreating = false
                    if viewModel.selectedTable != nil { await viewModel.loadTableStructure() }
                    dismiss()
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isCreating { ProgressView().scaleEffect(0.5).frame(width: 14, height: 14) }
                    Text(isCreating ? L10n.Database.creating : L10n.Database.createIndex).font(AXTypography.subheadline).fontWeight(.bold)
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, AXSpacing.sm)
                .background(isValid ? Color.axAccentBlue : Color.axTextMuted.opacity(0.3)).cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain).disabled(!isValid || isCreating)
        }
        .padding(AXSpacing.lg)
    }

    private var isValid: Bool {
        !indexName.isEmpty && !selectedColumns.isEmpty
    }

    private func generateSQL() -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let uq = isUnique ? "UNIQUE " : ""
        switch viewModel.database.type {
        case .postgresql, .cockroachdb:
            let cols = selectedColumns.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
            let using = indexType != "BTREE" ? " USING \(indexType.lowercased())" : ""
            return "CREATE \(uq)INDEX \"\(indexName)\" ON \"\(tableName)\"\(using) (\(cols));"
        case .sqlite:
            let cols = selectedColumns.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
            return "CREATE \(uq)INDEX \"\(indexName)\" ON \"\(tableName)\" (\(cols));"
        default:
            let cols = selectedColumns.sorted().map { "`\($0)`" }.joined(separator: ", ")
            let using = indexType != "BTREE" ? " USING \(indexType)" : ""
            return "CREATE \(uq)INDEX `\(indexName)` ON `\(tableName)` (\(cols))\(using);"
        }
    }
}
