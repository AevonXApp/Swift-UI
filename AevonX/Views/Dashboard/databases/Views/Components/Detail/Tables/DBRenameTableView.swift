//
//  DBRenameTableView.swift
//  AevonX
//
//  Rename table dialog with SQL preview and validation.
//

import SwiftUI
import AevonXCoreBridge

struct DBRenameTableView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @State private var isRenaming = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.axWarning.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "pencil")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axWarning)
                    }
                    Text("Rename Table")
                        .font(AXTypography.headline).fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AXTypography.title3)
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)

            Divider().background(Color.axBorder)

            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Current name
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Current Name")
                        .font(AXTypography.footnote).fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                    Text(viewModel.selectedTable?.name ?? "")
                        .font(AXTypography.monoMd).fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axSurface.opacity(0.4))
                        .cornerRadius(AXCornerRadius.md)
                }

                // New name
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("New Name")
                        .font(AXTypography.footnote).fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    TextField("new_table_name", text: $newName)
                        .font(AXTypography.monoMd)
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

                    if !newName.isEmpty && newName.contains(" ") {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(AXTypography.caption2)
                            Text("Table names should not contain spaces")
                                .font(AXTypography.caption)
                        }
                        .foregroundColor(.axWarning)
                    }
                }

                // SQL Preview
                if !newName.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("SQL Preview")
                            .font(AXTypography.footnote).fontWeight(.semibold)
                            .foregroundColor(.axTextSecondary)
                        Text(generateSQL())
                            .font(AXTypography.monoSm)
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

            Spacer()

            Divider().background(Color.axBorder)

            // Actions
            HStack(spacing: AXSpacing.md) {
                Button { dismiss() } label: {
                    Text(L10n.Button.cancel)
                        .font(AXTypography.subheadline).fontWeight(.semibold)
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
                        isRenaming = true
                        let sql = generateSQL()
                        viewModel.queryText = sql
                        await viewModel.executeQuery()
                        await viewModel.loadTables()
                        isRenaming = false
                        dismiss()
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isRenaming {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 14, height: 14)
                        }
                        Text(isRenaming ? "Renaming..." : "Rename")
                            .font(AXTypography.subheadline).fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(isValid ? Color.axWarning : Color.axTextMuted.opacity(0.3))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(!isValid || isRenaming)
            }
            .padding(AXSpacing.lg)
        }
        .frame(width: 400, height: 400)
        .background(Color.axBackground)
        .onAppear {
            newName = viewModel.selectedTable?.name ?? ""
        }
    }

    private var isValid: Bool {
        !newName.isEmpty && newName != viewModel.selectedTable?.name && !newName.contains(" ")
    }

    private func generateSQL() -> String {
        let oldName = viewModel.selectedTable?.name ?? "table"
        return "RENAME TABLE `\(oldName)` TO `\(newName)`;"
    }
}
