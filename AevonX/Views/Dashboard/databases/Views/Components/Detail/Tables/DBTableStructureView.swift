//
//  DBTableStructureView.swift
//  AevonX
//
//  Premium table structure view with type-colored badges,
//  default values, and column reordering context menu.
//

import SwiftUI
import AevonXCoreBridge

struct DBTableStructureView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                        Text(L10n.Database.columnsLabel)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        if let structure = viewModel.tableStructure {
                            Text("\(structure.columns.count)")
                                .font(AXTypography.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.axAccentBlue)
                                .padding(.horizontal, AXSpacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.axAccentBlue.opacity(0.1))
                                .cornerRadius(AXCornerRadius.full)
                        }
                    }
                    Spacer()

                    // Export Schema
                    Button {
                        if let structure = viewModel.tableStructure {
                            let ddl = generateDDL(structure)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ddl, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.ddlCopied)
                        }
                    } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "doc.text")
                                .font(AXTypography.caption2)
                            Text(L10n.Database.copyDDL)
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button { viewModel.showAddColumn = true } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "plus")
                                .font(AXTypography.caption2)
                            Text(L10n.Database.addColumn)
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.lg)

                if let structure = viewModel.tableStructure {
                    VStack(alignment: .leading, spacing: 0) {
                        columnHeader
                        Divider().background(Color.axBorder)
                        ForEach(Array(structure.columns.enumerated()), id: \.element.id) { index, col in
                            columnRow(col, index: index)
                            if index < structure.columns.count - 1 {
                                Divider().background(Color.axBorder.opacity(0.3))
                            }
                        }
                    }
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.bottom, AXSpacing.lg)
                } else {
                    VStack {
                        Spacer(minLength: 60)
                        ProgressView()
                        Spacer(minLength: 60)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddColumn) {
            DBAddColumnView(viewModel: viewModel)
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 30, alignment: .center)
            Text(L10n.Field.name)
                .frame(width: 160, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text(L10n.Database.typeHeader)
                .frame(width: 110, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text(L10n.Database.defaultColHeader)
                .frame(width: 90, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text(L10n.Database.constraintsHeader)
                .padding(.horizontal, AXSpacing.sm)
            Spacer()
            Text("")
                .frame(width: 40, alignment: .center)
        }
        .font(AXTypography.caption2)
        .fontWeight(.bold)
        .foregroundColor(.axTextMuted)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.8))
    }

    private func columnRow(_ col: ColumnInfo, index: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .frame(width: 30, alignment: .center)

            HStack(spacing: AXSpacing.xs) {
                if col.isPrimaryKey {
                    Image(systemName: "key.fill")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axWarning)
                }
                Text(col.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(col.isPrimaryKey ? .semibold : .regular)
                    .foregroundColor(.axTextPrimary)
            }
            .frame(width: 160, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            Text(col.type)
                .font(AXTypography.monoSm).fontWeight(.medium)
                .foregroundColor(colorForType(col.type))
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background(colorForType(col.type).opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 110, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            // Default value
            Group {
                if !col.defaultValue.isEmpty {
                    Text(col.defaultValue)
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                } else {
                    Text("—")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted.opacity(0.3))
                }
            }
            .frame(width: 90, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            HStack(spacing: AXSpacing.xs) {
                if col.isPrimaryKey {
                    constraintBadge("PK", color: .axWarning)
                }
                if !col.isNullable {
                    constraintBadge("NN", color: .axTextSecondary)
                }
                if col.extra.contains("auto_increment") {
                    constraintBadge("AI", color: .axAccentBlue)
                }
                if col.extra.contains("UNIQUE") || col.extra.contains("unique") {
                    constraintBadge("UQ", color: .axAccentGreen)
                }
                if col.extra.contains("MUL") {
                    constraintBadge("FK", color: .axInfo)
                }
            }
            .padding(.horizontal, AXSpacing.sm)

            Spacer()

            // Column actions — AXActionMenu
            AXActionMenu(sections: [
                AXMenuSection(L10n.Button.copy, items: [
                    AXMenuItem(L10n.Database.copyColumnName, icon: "doc.on.doc", color: .axAccentBlue) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(col.name, forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.columnNameCopied)
                    },
                    AXMenuItem(L10n.Database.copyColumnDDL, icon: "chevron.left.forwardslash.chevron.right", color: .mint) {
                        let ddl = columnDDL(col)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(ddl, forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.columnDDLCopied)
                    },
                ]),
                AXMenuSection(items: [
                    AXMenuItem(L10n.Database.dropColumn, icon: "trash", isDestructive: true) {
                        viewModel.activeAlert = .confirmDropColumn(col.name)
                    },
                ]),
            ], triggerIcon: "ellipsis", triggerSize: 22)
            .frame(width: 40, alignment: .center)
        }
        .padding(.vertical, AXSpacing.sm)
        .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
        .help(columnTooltip(col))
    }

    private func constraintBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AXTypography.caption2).fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.xs)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }

    private func colorForType(_ type: String) -> Color {
        let t = type.uppercased()
        if t.contains("INT") || t.contains("DECIMAL") || t.contains("FLOAT") || t.contains("DOUBLE") {
            return .axAccentBlue
        }
        if t.contains("VARCHAR") || t.contains("CHAR") || t.contains("TEXT") {
            return .axAccentGreen
        }
        if t.contains("DATE") || t.contains("TIME") || t.contains("YEAR") {
            return .axWarning
        }
        if t.contains("JSON") || t.contains("BLOB") { return .axInfo }
        if t.contains("BOOL") { return .axError }
        return .axTextMuted
    }

    private func columnTooltip(_ col: ColumnInfo) -> String {
        var parts = ["\(col.name) \(col.type)"]
        if col.isPrimaryKey { parts.append("PRIMARY KEY") }
        if !col.isNullable { parts.append("NOT NULL") }
        if !col.defaultValue.isEmpty { parts.append("DEFAULT \(col.defaultValue)") }
        if !col.extra.isEmpty { parts.append(col.extra) }
        return parts.joined(separator: " | ")
    }

    private func columnDDL(_ col: ColumnInfo) -> String {
        var ddl = "`\(col.name)` \(col.type)"
        if !col.isNullable { ddl += " NOT NULL" }
        if col.extra.contains("auto_increment") { ddl += " AUTO_INCREMENT" }
        if !col.defaultValue.isEmpty { ddl += " DEFAULT \(col.defaultValue)" }
        if col.isPrimaryKey { ddl += " PRIMARY KEY" }
        return ddl
    }

    private func generateDDL(_ structure: TableStructure) -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        var cols: [String] = []
        var pks: [String] = []
        for col in structure.columns {
            cols.append("  " + columnDDL(col))
            if col.isPrimaryKey { pks.append("`\(col.name)`") }
        }
        var ddl = "CREATE TABLE `\(tableName)` (\n"
        ddl += cols.joined(separator: ",\n")
        ddl += "\n);"
        return ddl
    }
}
