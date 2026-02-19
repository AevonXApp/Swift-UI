//
//  DBAddColumnView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBAddColumnView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var column = CreateTableColumnDefinition()
    @State private var afterColumn: String = ""
    @State private var isSubmitting = false

    private var mysqlColumnTypes: [String] {
        ["INT", "BIGINT", "SMALLINT", "TINYINT", "MEDIUMINT",
         "VARCHAR", "CHAR", "TEXT", "MEDIUMTEXT", "LONGTEXT",
         "DECIMAL", "FLOAT", "DOUBLE",
         "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
         "BOOLEAN", "ENUM", "SET",
         "BLOB", "MEDIUMBLOB", "LONGBLOB",
         "JSON", "BINARY", "VARBINARY"]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Column")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text("to \(viewModel.selectedTable?.name ?? "")")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                Spacer()
                Button { viewModel.showAddColumn = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.xl)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    addColumnNameField
                    addColumnTypeRow
                    addColumnOptionsRow
                    addColumnPositionField
                }
                .padding(AXSpacing.xl)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button { viewModel.showAddColumn = false } label: {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                }
                .buttonStyle(.plain)

                Button {
                    isSubmitting = true
                    Task {
                        await viewModel.addColumn(column, afterColumn: afterColumn.isEmpty ? nil : afterColumn)
                        isSubmitting = false
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isSubmitting {
                            ProgressView().scaleEffect(0.7).tint(.axBackground)
                        }
                        Text(isSubmitting ? "Adding..." : "Add Column")
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .background(!column.name.isEmpty && !isSubmitting ? viewModel.database.type.brandColor : Color.axTextMuted.opacity(0.5))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(column.name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }

    private var addColumnNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Column Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            TextField("column_name", text: $column.name)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        }
    }

    private var addColumnTypeRow: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Type")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                Picker("", selection: $column.type) {
                    ForEach(mysqlColumnTypes, id: \.self) { t in Text(t).tag(t) }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Length")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                TextField("255", text: Binding(
                    get: { column.length ?? "" },
                    set: { column.length = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            }
            .frame(width: 100)
        }
    }

    private var addColumnOptionsRow: some View {
        HStack(spacing: AXSpacing.xl) {
            Toggle("Not Null", isOn: Binding(
                get: { !column.isNullable },
                set: { column.isNullable = !$0 }
            ))
            .toggleStyle(.checkbox)

            Toggle("Primary Key", isOn: $column.isPrimaryKey)
                .toggleStyle(.checkbox)

            Toggle("Auto Increment", isOn: $column.isAutoIncrement)
                .toggleStyle(.checkbox)

            Toggle("Unique", isOn: $column.isUnique)
                .toggleStyle(.checkbox)
        }
        .font(AXTypography.subheadline)
        .foregroundColor(.axTextPrimary)
    }

    private var addColumnPositionField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Position (After Column)")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            Picker("", selection: $afterColumn) {
                Text("End of table").tag("")
                if let structure = viewModel.tableStructure {
                    ForEach(structure.columns) { col in
                        Text("After \(col.name)").tag(col.name)
                    }
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }
}
