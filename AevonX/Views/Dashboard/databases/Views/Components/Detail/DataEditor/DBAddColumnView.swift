//
//  DBAddColumnView.swift
//  AevonX
//
//  Premium Add Column dialog with type badge preview,
//  constraint toggles, and SQL preview.
//

import SwiftUI
import AevonXCoreBridge

struct DBAddColumnView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var column = CreateTableColumnDefinition()
    @State private var afterColumn: String = ""
    @State private var isSubmitting = false

    private var mysqlColumnTypes: [String] {
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
        default:
            return ["INT", "BIGINT", "SMALLINT", "TINYINT", "MEDIUMINT",
                    "VARCHAR", "CHAR", "TEXT", "MEDIUMTEXT", "LONGTEXT",
                    "DECIMAL", "FLOAT", "DOUBLE",
                    "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
                    "BOOLEAN", "ENUM", "SET",
                    "BLOB", "MEDIUMBLOB", "LONGBLOB",
                    "JSON", "BINARY", "VARBINARY"]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            dialogHeader
            Divider().background(Color.axBorder)
            dialogForm
            Divider().background(Color.axBorder)
            dialogFooter
        }
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var dialogHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axAccentBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Database.addColumn)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Database.toTable(viewModel.selectedTable?.name ?? ""))
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Button { viewModel.showAddColumn = false } label: {
                Image(systemName: "xmark")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Form

    private var dialogForm: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Column Name
                fieldGroup(label: L10n.Database.columnNameHeader) {
                    TextField("column_name", text: $column.name)
                        .font(AXTypography.monoMd)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(column.name.isEmpty ? Color.axBorder : Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                        )
                }

                // Type & Length
                HStack(spacing: AXSpacing.lg) {
                    fieldGroup(label: L10n.Database.typeHeader) {
                        Picker("", selection: $column.type) {
                            ForEach(mysqlColumnTypes, id: \.self) { t in Text(t).tag(t) }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }

                    fieldGroup(label: L10n.Database.lengthHeader) {
                        TextField("255", text: Binding(
                            get: { column.length ?? "" },
                            set: { column.length = $0.isEmpty ? nil : $0 }
                        ))
                        .font(AXTypography.monoMd)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .frame(width: 100)
                }

                // Constraints
                fieldGroup(label: L10n.Database.constraintsHeader) {
                    HStack(spacing: AXSpacing.lg) {
                        constraintOption(L10n.Database.notNullLabel, isOn: Binding(
                            get: { !column.isNullable },
                            set: { column.isNullable = !$0 }
                        ), color: .axTextSecondary)

                        constraintOption(L10n.Database.primaryKeyLabel, isOn: $column.isPrimaryKey, color: .axWarning)
                        constraintOption(L10n.Database.autoIncrementLabel, isOn: $column.isAutoIncrement, color: .axAccentBlue)
                        constraintOption(L10n.Database.uniqueLabel, isOn: $column.isUnique, color: .axAccentGreen)
                    }
                }

                // Position
                fieldGroup(label: L10n.Database.positionHeader) {
                    Picker("", selection: $afterColumn) {
                        Text(L10n.Database.endOfTable).tag("")
                        if let structure = viewModel.tableStructure {
                            ForEach(structure.columns) { col in
                                Text(L10n.Database.afterColumnName(col.name)).tag(col.name)
                            }
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                // Preview
                if !column.name.isEmpty {
                    previewCard
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(label)
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundColor(.axTextMuted)
                .tracking(0.5)
            content()
        }
    }

    private func constraintOption(_ title: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(AXTypography.caption)
                    .foregroundColor(isOn.wrappedValue ? color : .axTextMuted)
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(isOn.wrappedValue ? .axTextPrimary : .axTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Database.previewHeader)
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundColor(.axTextMuted)
                .tracking(0.5)

            HStack(spacing: AXSpacing.sm) {
                Text(column.name)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                Text(column.type + (column.length.map { "(\($0))" } ?? ""))
                    .font(AXTypography.monoSm).fontWeight(.medium)
                    .foregroundColor(colorForType(column.type))
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 2)
                    .background(colorForType(column.type).opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)

                if !column.isNullable {
                    Text("NN")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.axTextSecondary.opacity(0.1))
                        .cornerRadius(AXCornerRadius.xs)
                }
                if column.isPrimaryKey {
                    Text("PK")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axWarning)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.axWarning.opacity(0.1))
                        .cornerRadius(AXCornerRadius.xs)
                }
                if column.isAutoIncrement {
                    Text("AI")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.xs)
                }
            }
            .padding(AXSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Footer

    private var dialogFooter: some View {
        HStack(spacing: AXSpacing.md) {
            if !column.name.isEmpty {
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

            Button { viewModel.showAddColumn = false } label: {
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
                    await viewModel.addColumn(column, afterColumn: afterColumn.isEmpty ? nil : afterColumn)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    }
                    Text(isSubmitting ? L10n.Database.adding : L10n.Database.addColumn)
                }
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(!column.name.isEmpty && !isSubmitting ? Color.axAccentBlue : Color.axTextMuted.opacity(0.3))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(column.name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Helpers

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
}
