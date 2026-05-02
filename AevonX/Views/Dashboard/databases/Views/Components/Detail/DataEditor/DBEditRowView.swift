//
//  DBEditRowView.swift
//  AevonX
//
//  Premium Edit Row dialog with change tracking,
//  type badges, and visual diff indicators.
//

import SwiftUI
import AevonXCoreBridge

struct DBEditRowView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var values: [String: String] = [:]
    @State private var nullFlags: [String: Bool] = [:]
    @State private var isSubmitting = false

    private var columns: [ColumnInfo] {
        viewModel.tableStructure?.columns ?? []
    }

    private var changedCount: Int {
        columns.filter { col in
            let original = viewModel.editingRowValues[col.name] ?? nil
            let current = nullFlags[col.name] == true ? nil : values[col.name]
            return original != current
        }.count
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
        .onAppear { initFromEditing() }
    }

    // MARK: - Header

    private var dialogHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axAccentBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "pencil.and.list.clipboard")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Database.editRow)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Database.inDatabase(viewModel.selectedTable?.name ?? ""))
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            if changedCount > 0 {
                HStack(spacing: AXSpacing.xxs) {
                    Circle()
                        .fill(Color.axWarning)
                        .frame(width: 6, height: 6)
                    Text(L10n.Database.changedCount(changedCount))
                        .font(AXTypography.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.axWarning)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(AXCornerRadius.full)
            }

            Button { viewModel.showEditRow = false } label: {
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
        let isNull = nullFlags[col.name] ?? false
        let original = viewModel.editingRowValues[col.name] ?? nil
        let current = isNull ? nil : values[col.name]
        let hasChanged = original != current

        return VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                if col.isPrimaryKey {
                    Image(systemName: "key.fill")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axWarning)
                }
                Text(col.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                Text(col.type)
                    .font(AXTypography.monoXxs).fontWeight(.bold)
                    .foregroundColor(colorForType(col.type))
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 1)
                    .background(colorForType(col.type).opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)

                if hasChanged {
                    Text(L10n.Database.modified)
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axWarning)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 1)
                        .background(Color.axWarning.opacity(0.1))
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
                            Text(L10n.Literal.null)
                                .font(AXTypography.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(isNull ? .axWarning : .axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !isNull {
                TextField(L10n.Field.value, text: Binding(
                    get: { values[col.name] ?? "" },
                    set: { values[col.name] = $0 }
                ))
                .font(AXTypography.monoMd)
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(hasChanged ? Color.axWarning.opacity(0.5) : Color.axBorder, lineWidth: 1)
                )
            } else {
                HStack {
                    Text(L10n.Literal.null)
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
        .background(hasChanged ? Color.axWarning.opacity(0.03) : Color.clear)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Footer

    private var dialogFooter: some View {
        HStack(spacing: AXSpacing.md) {
            if changedCount > 0 {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "pencil")
                        .font(AXTypography.caption2)
                    Text(L10n.Database.fieldsModified(changedCount))
                        .font(AXTypography.caption)
                }
                .foregroundColor(.axWarning)
            }

            Spacer()

            Button { viewModel.showEditRow = false } label: {
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
                    var pk: [String: String] = [:]
                    for col in columns.filter({ $0.isPrimaryKey }) {
                        if let original = viewModel.editingRowValues[col.name], let v = original {
                            pk[col.name] = v
                        }
                    }

                    var updatedValues: [String: String?] = [:]
                    for col in columns {
                        if nullFlags[col.name] == true {
                            updatedValues[col.name] = nil
                        } else {
                            updatedValues[col.name] = values[col.name]
                        }
                    }

                    await viewModel.updateRow(primaryKey: pk, values: updatedValues)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    }
                    Text(isSubmitting ? L10n.Database.saving : L10n.Button.saveChanges)
                }
                .font(AXTypography.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isSubmitting ? Color.axTextMuted.opacity(0.3) : Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Helpers

    private func initFromEditing() {
        for col in columns {
            if let optVal = viewModel.editingRowValues[col.name] {
                if let val = optVal {
                    values[col.name] = val
                    nullFlags[col.name] = false
                } else {
                    values[col.name] = ""
                    nullFlags[col.name] = true
                }
            } else {
                values[col.name] = ""
                nullFlags[col.name] = false
            }
        }
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
