//
//  DBCreateTableView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBCreateTableView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var tableName = ""
    @State private var columns: [CreateTableColumnDefinition] = [
        CreateTableColumnDefinition(name: "id", type: "INT", length: nil, isNullable: false, isPrimaryKey: true, isAutoIncrement: true)
    ]
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            createTableHeader
            Divider()
            createTableContent
            Divider()
            createTableFooter
        }
        .frame(width: 700, height: 550)
        .background(Color.axBackground)
    }

    private var createTableHeader: some View {
        HStack {
            Text("Create Table")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("in \(viewModel.database.name)")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showCreateTable = false } label: {
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
    }

    private var createTableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                tableNameField
                columnsSection
            }
            .padding(AXSpacing.xl)
        }
    }

    private var tableNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Table Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            TextField("users", text: $tableName)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
    }

    private var columnsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text("Columns")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                Spacer()
                Button { addColumn() } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Column")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.database.type.brandColor)
                }
                .buttonStyle(.plain)
            }

            columnHeaderRow

            ForEach(Array(columns.enumerated()), id: \.element.id) { index, _ in
                columnRow(index: index)
            }
        }
    }

    private var columnHeaderRow: some View {
        HStack(spacing: AXSpacing.sm) {
            Text("Name")
                .frame(width: 130, alignment: .leading)
            Text("Type")
                .frame(width: 100, alignment: .leading)
            Text("Length")
                .frame(width: 60, alignment: .leading)
            Text("PK")
                .frame(width: 28, alignment: .center)
            Text("NN")
                .frame(width: 28, alignment: .center)
            Text("AI")
                .frame(width: 28, alignment: .center)
            Text("UQ")
                .frame(width: 28, alignment: .center)
            Spacer()
        }
        .font(AXTypography.caption2)
        .fontWeight(.bold)
        .foregroundColor(.axTextMuted)
        .padding(.horizontal, AXSpacing.sm)
    }

    private func columnRow(index: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            TextField("column", text: $columns[index].name)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 130)

            Picker("", selection: $columns[index].type) {
                ForEach(mysqlColumnTypes, id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            .labelsHidden()
            .frame(width: 100)

            TextField("", text: Binding(
                get: { columns[index].length ?? "" },
                set: { columns[index].length = $0.isEmpty ? nil : $0 }
            ))
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .textFieldStyle(.plain)
            .padding(AXSpacing.xs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .frame(width: 60)

            Toggle("", isOn: $columns[index].isPrimaryKey)
                .toggleStyle(.checkbox)
                .frame(width: 28)

            Toggle("", isOn: Binding(
                get: { !columns[index].isNullable },
                set: { columns[index].isNullable = !$0 }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 28)

            Toggle("", isOn: $columns[index].isAutoIncrement)
                .toggleStyle(.checkbox)
                .frame(width: 28)

            Toggle("", isOn: $columns[index].isUnique)
                .toggleStyle(.checkbox)
                .frame(width: 28)

            Spacer()

            if columns.count > 1 {
                Button { columns.remove(at: index) } label: {
                    Image(systemName: "minus.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
    }

    private var createTableFooter: some View {
        HStack(spacing: AXSpacing.md) {
            Text("\(columns.count) column\(columns.count == 1 ? "" : "s")")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showCreateTable = false } label: {
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
                    await viewModel.createTable(name: tableName, columns: columns)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting {
                        ProgressView().scaleEffect(0.7).tint(.axBackground)
                    }
                    Text(isSubmitting ? "Creating..." : "Create Table")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isFormValid && !isSubmitting ? viewModel.database.type.brandColor : Color.axTextMuted.opacity(0.5))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isSubmitting)
        }
        .padding(AXSpacing.xl)
    }

    private var isFormValid: Bool {
        !tableName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !columns.isEmpty &&
        columns.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func addColumn() {
        columns.append(CreateTableColumnDefinition())
    }

    private var mysqlColumnTypes: [String] {
        ["INT", "BIGINT", "SMALLINT", "TINYINT", "MEDIUMINT",
         "VARCHAR", "CHAR", "TEXT", "MEDIUMTEXT", "LONGTEXT",
         "DECIMAL", "FLOAT", "DOUBLE",
         "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
         "BOOLEAN", "ENUM", "SET",
         "BLOB", "MEDIUMBLOB", "LONGBLOB",
         "JSON", "BINARY", "VARBINARY"]
    }
}
