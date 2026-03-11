//
//  DBAddRowView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
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
            addRowHeader
            Divider()
            addRowForm
            Divider()
            addRowFooter
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
        .onAppear { initDefaults() }
    }

    private var addRowHeader: some View {
        HStack {
            Text("Add Row")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("to \(viewModel.selectedTable?.name ?? "")")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showAddRow = false } label: {
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

    private var addRowForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                ForEach(columns) { col in
                    addRowField(col)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func addRowField(_ col: ColumnInfo) -> some View {
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
                TextField(col.extra.contains("auto_increment") ? "(auto)" : "value", text: Binding(
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
                .disabled(col.extra.contains("auto_increment"))
            }
        }
    }

    private var addRowFooter: some View {
        HStack {
            Text("\(columns.count) columns")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showAddRow = false } label: {
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
                    if isSubmitting { ProgressView().scaleEffect(0.7).tint(.axBackground) }
                    Text(isSubmitting ? "Inserting..." : "Insert Row")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isSubmitting ? Color.axTextMuted.opacity(0.5) : Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(AXSpacing.xl)
    }

    private func initDefaults() {
        for col in columns {
            values[col.name] = ""
            nullFlags[col.name] = false
        }
    }
}
