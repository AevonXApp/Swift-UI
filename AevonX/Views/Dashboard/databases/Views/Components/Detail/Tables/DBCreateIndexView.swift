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

    private let indexTypes = ["BTREE", "HASH", "FULLTEXT", "SPATIAL"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.axAccentGreen.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axAccentGreen)
                    }
                    Text("Create Index")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }

                Spacer()

                if let table = viewModel.selectedTable {
                    Text(table.name)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 3)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)

            Divider().background(Color.axBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    // Index Name
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Index Name")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        TextField("idx_\(viewModel.selectedTable?.name ?? "table")_...", text: $indexName)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }

                    // Index Type
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Index Type")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(indexTypes, id: \.self) { type in
                                Button {
                                    indexType = type
                                } label: {
                                    Text(type)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(indexType == type ? .white : .axTextSecondary)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.sm)
                                        .background(indexType == type ? Color.axAccentBlue : Color.axSurface)
                                        .cornerRadius(AXCornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(indexType == type ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Unique toggle
                    HStack {
                        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                            Text("Unique Index")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            Text("Enforce unique values across selected columns")
                                .font(.system(size: 9))
                                .foregroundColor(.axTextMuted)
                        }
                        Spacer()
                        Toggle("", isOn: $isUnique)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }

                    // Column Selection
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        HStack {
                            Text("Columns")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                            Text("\(selectedColumns.count) selected")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(selectedColumns.isEmpty ? .axError : .axSuccess)
                        }

                        if let structure = viewModel.tableStructure {
                            VStack(spacing: 0) {
                                ForEach(Array(structure.columns.enumerated()), id: \.element.id) { index, col in
                                    let isSelected = selectedColumns.contains(col.name)
                                    Button {
                                        if isSelected {
                                            selectedColumns.remove(col.name)
                                        } else {
                                            selectedColumns.insert(col.name)
                                        }
                                    } label: {
                                        HStack(spacing: AXSpacing.sm) {
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 14))
                                                .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted.opacity(0.4))

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(col.name)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.axTextPrimary)
                                                Text(col.type)
                                                    .font(.system(size: 9, design: .monospaced))
                                                    .foregroundColor(.axTextMuted)
                                            }

                                            Spacer()

                                            if col.isPrimaryKey {
                                                Text("PK")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.axWarning)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.axWarning.opacity(0.1))
                                                    .cornerRadius(3)
                                            }
                                        }
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.sm)
                                        .background(
                                            isSelected
                                                ? Color.axAccentBlue.opacity(0.05)
                                                : (index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    if index < structure.columns.count - 1 {
                                        Divider().background(Color.axBorder.opacity(0.3))
                                    }
                                }
                            }
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                        }
                    }

                    // SQL Preview
                    if !selectedColumns.isEmpty {
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            HStack {
                                Text("SQL Preview")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(generateSQL(), forType: .string)
                                    GlobalToastManager.shared.showSuccess("SQL copied")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 9))
                                        .foregroundColor(.axAccentBlue)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(generateSQL())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axAccentGreen)
                                .textSelection(.enabled)
                                .padding(AXSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(AXCornerRadius.md)
                        }
                    }
                }
                .padding(AXSpacing.lg)
            }

            Divider().background(Color.axBorder)

            // Actions
            HStack(spacing: AXSpacing.md) {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        isCreating = true
                        let sql = generateSQL()
                        viewModel.queryText = sql
                        await viewModel.executeQuery()
                        isCreating = false
                        // Refresh indexes
                        if let table = viewModel.selectedTable {
                            await viewModel.loadTableStructure()
                        }
                        dismiss()
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 14, height: 14)
                        }
                        Text(isCreating ? "Creating..." : "Create Index")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        isValid
                            ? Color.axAccentBlue
                            : Color.axTextMuted.opacity(0.3)
                    )
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(!isValid || isCreating)
            }
            .padding(AXSpacing.lg)
        }
        .frame(width: 520, height: 600)
        .background(Color.axBackground)
    }

    private var isValid: Bool {
        !indexName.isEmpty && !selectedColumns.isEmpty
    }

    private func generateSQL() -> String {
        let tableName = viewModel.selectedTable?.name ?? "table"
        let uq = isUnique ? "UNIQUE " : ""
        let cols = selectedColumns.sorted().map { "`\($0)`" }.joined(separator: ", ")
        let using = indexType != "BTREE" ? " USING \(indexType)" : ""
        return "CREATE \(uq)INDEX `\(indexName)` ON `\(tableName)` (\(cols))\(using);"
    }
}
