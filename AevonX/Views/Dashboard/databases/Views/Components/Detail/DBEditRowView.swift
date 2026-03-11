//
//  DBEditRowView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
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

    var body: some View {
        VStack(spacing: 0) {
            editRowHeader
            Divider()
            editRowForm
            Divider()
            editRowFooter
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
        .onAppear { initFromEditing() }
    }

    private var editRowHeader: some View {
        HStack {
            Text("Edit Row")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("in \(viewModel.selectedTable?.name ?? "")")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showEditRow = false } label: {
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

    private var editRowForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                ForEach(columns) { col in
                    editRowField(col)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func editRowField(_ col: ColumnInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                HStack(spacing: AXSpacing.xs) {
                    if col.isPrimaryKey {
                        Image(systemName: "key.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.axWarning)
                    }
                    Text(col.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                }
                Text(col.type)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                Spacer()
                if col.isNullable {
                    Toggle("NULL", isOn: Binding(
                        get: { nullFlags[col.name] ?? false },
                        set: { nullFlags[col.name] = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                }
            }
            if !(nullFlags[col.name] ?? false) {
                TextField("value", text: Binding(
                    get: { values[col.name] ?? "" },
                    set: { values[col.name] = $0 }
                ))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            }
        }
    }

    private var editRowFooter: some View {
        HStack {
            Spacer()
            Button { viewModel.showEditRow = false } label: {
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
                    // Build PK from original values
                    var pk: [String: String] = [:]
                    let pkCols = columns.filter { $0.isPrimaryKey }
                    for col in pkCols {
                        if let original = viewModel.editingRowValues[col.name], let v = original {
                            pk[col.name] = v
                        }
                    }

                    // Build updated values
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
                    if isSubmitting { ProgressView().scaleEffect(0.7).tint(.axBackground) }
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isSubmitting ? Color.axTextMuted.opacity(0.5) : viewModel.database.type.brandColor)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(AXSpacing.xl)
    }

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
}
