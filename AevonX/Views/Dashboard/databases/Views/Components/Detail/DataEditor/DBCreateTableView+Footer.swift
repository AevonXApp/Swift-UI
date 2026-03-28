//
//  DBCreateTableView+Footer.swift
//  AevonX
//
//  Footer action buttons and helper methods
//  for the create table view.
//

import SwiftUI
import AevonXCoreBridge

extension DBCreateTableView {
    // MARK: - Footer

    var dialogFooter: some View {
        HStack(spacing: AXSpacing.md) {
            Text(L10n.Database.columnCount(columns.count))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            if isFormValid {
                HStack(spacing: AXSpacing.xxs) {
                    Circle()
                        .fill(Color.axSuccess)
                        .frame(width: 6, height: 6)
                    Text(L10n.Database.ready)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axSuccess)
                }
            }

            Spacer()

            Button { viewModel.showCreateTable = false } label: {
                Text(L10n.Button.cancel)
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
                        ProgressView().scaleEffect(0.6).tint(.white)
                    }
                    Text(isSubmitting ? L10n.Database.creating : L10n.Database.createTable)
                }
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isFormValid && !isSubmitting ? Color.axAccentBlue : Color.axTextMuted.opacity(0.3))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isSubmitting)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Helpers

    var isFormValid: Bool {
        !tableName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !columns.isEmpty &&
        columns.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    func addColumn() {
        withAnimation(.spring(response: 0.2)) {
            columns.append(CreateTableColumnDefinition())
        }
    }

    func generateSQL() -> String {
        guard !tableName.isEmpty else { return "CREATE TABLE ... ;" }
        var lines: [String] = []
        var pkCols: [String] = []
        for col in columns {
            var def = "  `\(col.name)` \(col.type)"
            if let len = col.length, !len.isEmpty { def += "(\(len))" }
            if !col.isNullable { def += " NOT NULL" }
            if col.isAutoIncrement { def += " AUTO_INCREMENT" }
            if col.isUnique { def += " UNIQUE" }
            if col.isPrimaryKey { pkCols.append("`\(col.name)`") }
            lines.append(def)
        }
        if !pkCols.isEmpty {
            lines.append("  PRIMARY KEY (\(pkCols.joined(separator: ", ")))")
        }
        return "CREATE TABLE `\(tableName)` (\n\(lines.joined(separator: ",\n"))\n);"
    }

    var mysqlColumnTypes: [String] {
        switch viewModel.database.type {
        case .postgresql, .cockroachdb:
            return ["INTEGER", "BIGINT", "SMALLINT", "SERIAL", "BIGSERIAL",
                    "VARCHAR", "CHAR", "TEXT",
                    "NUMERIC", "REAL", "DOUBLE PRECISION",
                    "DATE", "TIMESTAMP", "TIMESTAMPTZ", "TIME", "INTERVAL",
                    "BOOLEAN",
                    "BYTEA",
                    "JSON", "JSONB", "UUID", "INET", "CIDR",
                    "ARRAY", "HSTORE"]
        default: // MySQL, MariaDB
            return ["INT", "BIGINT", "SMALLINT", "TINYINT", "MEDIUMINT",
                    "VARCHAR", "CHAR", "TEXT", "MEDIUMTEXT", "LONGTEXT",
                    "DECIMAL", "FLOAT", "DOUBLE",
                    "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
                    "BOOLEAN", "ENUM", "SET",
                    "BLOB", "MEDIUMBLOB", "LONGBLOB",
                    "JSON", "BINARY", "VARBINARY"]
        }
    }
}
