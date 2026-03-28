//
//  DBAddRowView.swift
//  AevonX
//
//  Premium Add Row dialog with type badges,
//  NULL toggles, and auto-increment detection.
//

import SwiftUI
import AevonXCoreBridge

struct DBAddRowView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var values: [String: String] = [:]
    @State private var nullFlags: [String: Bool] = [:]
    @State private var isSubmitting = false

    private var columns: [ColumnInfo] {
        viewModel.tableStructure?.columns ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            dialogHeader
            Divider().background(Color.axBorder)
            dialogForm
            Divider().background(Color.axBorder)
            dialogFooter
        }
        .frame(width: 620, height: 520)
        .background(Color.axBackground)
        .onAppear { initDefaults() }
    }

    // MARK: - Header

    private var dialogHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axAccentGreen.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "plus.rectangle")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentGreen)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Database.insertRow)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Database.intoDatabase(viewModel.selectedTable?.name ?? ""))
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Text(L10n.Database.columnsCount(columns.count))
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 2)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.full)

            Button { viewModel.showAddRow = false } label: {
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
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(columns) { col in
                    fieldRow(col)
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    private func fieldRow(_ col: ColumnInfo) -> some View {
        let isAuto = col.extra.contains("auto_increment")
        let isNull = nullFlags[col.name] ?? false

        return VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                // Column name
                if col.isPrimaryKey {
                    Image(systemName: "key.fill")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axWarning)
                }
                Text(col.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                // Type badge
                Text(col.type)
                    .font(AXTypography.monoXxs).fontWeight(.bold)
                    .foregroundColor(colorForType(col.type))
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 1)
                    .background(colorForType(col.type).opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)

                if isAuto {
                    Text("AUTO")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 1)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()

                if col.isNullable {
                    Button {
                        nullFlags[col.name] = !(nullFlags[col.name] ?? false)
                    } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: isNull ? "checkmark.square.fill" : "square")
                                .font(AXTypography.caption2)
                            Text("NULL")
                                .font(AXTypography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(isNull ? .axWarning : .axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !isNull {
                TextField(isAuto ? L10n.Database.autoGenerated : L10n.Database.enterValue, text: Binding(
                    get: { values[col.name] ?? "" },
                    set: { values[col.name] = $0 }
                ))
                .font(AXTypography.monoMd)
                .foregroundColor(isAuto ? .axTextMuted : .axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .disabled(isAuto)
            } else {
                HStack {
                    Text("NULL")
                        .font(AXTypography.monoMd)
                        .italic()
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axSurface.opacity(0.3))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(AXSpacing.sm)
        .background(isAuto ? Color.axSurface.opacity(0.2) : Color.clear)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Footer

    private var dialogFooter: some View {
        HStack(spacing: AXSpacing.md) {
            Spacer()

            Button { viewModel.showAddRow = false } label: {
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
                    var finalValues: [String: String?] = [:]
                    for col in columns {
                        if col.extra.contains("auto_increment") { continue }
                        if nullFlags[col.name] == true {
                            finalValues[col.name] = nil
                        } else {
                            let v = values[col.name] ?? ""
                            if !v.isEmpty { finalValues[col.name] = v }
                        }
                    }
                    await viewModel.insertRow(finalValues)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    }
                    Text(isSubmitting ? L10n.Database.inserting : L10n.Database.insertRow)
                }
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isSubmitting ? Color.axTextMuted.opacity(0.3) : Color.axAccentGreen)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Helpers

    private func initDefaults() {
        let dupeVals = viewModel.duplicateRowValues
        for col in columns {
            if let dv = dupeVals?[col.name], dv != "NULL" {
                values[col.name] = col.isAutoIncrement ? "" : dv
                nullFlags[col.name] = false
            } else {
                values[col.name] = ""
                nullFlags[col.name] = false
            }
        }
        // Clear after consuming
        viewModel.duplicateRowValues = nil
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
}
