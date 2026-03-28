//
//  DBTableIndexesView.swift
//  AevonX
//
//  Premium indexes view with icon badges,
//  type-colored index cards, and visual hierarchy.
//

import SwiftUI
import AevonXCoreBridge

struct DBTableIndexesView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var hoveredIndex: Int? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "list.bullet.indent")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                        Text(L10n.Database.indexesHeader)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        if !viewModel.tableIndexes.isEmpty {
                            Text("\(viewModel.tableIndexes.count)")
                                .font(AXTypography.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.axAccentBlue)
                                .padding(.horizontal, AXSpacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.axAccentBlue.opacity(0.1))
                                .cornerRadius(AXCornerRadius.full)
                        }
                    }
                    Spacer()

                    // Create Index button
                    Button { viewModel.showCreateIndex = true } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "plus")
                                .font(AXTypography.caption2)
                            Text(L10n.Database.createIndex)
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axAccentGreen)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axAccentGreen.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)

                    // Export All Indexes
                    if !viewModel.tableIndexes.isEmpty {
                        Button {
                            let usePG = viewModel.database.type == .postgresql || viewModel.database.type == .cockroachdb
                            let q: (String) -> String = usePG ? { "\"\($0)\"" } : { "`\($0)`" }
                            let ddl = viewModel.tableIndexes.map { idx in
                                let uq = idx.isUnique ? "UNIQUE " : ""
                                let cols = idx.columns.map { q($0) }.joined(separator: ", ")
                                let tbl = viewModel.selectedTable?.name ?? "table"
                                return "CREATE \(uq)INDEX \(q(idx.name)) ON \(q(tbl)) (\(cols));"
                            }.joined(separator: "\n")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ddl, forType: .string)
                            GlobalToastManager.shared.showSuccess(L10n.Database.indexDDLsCopied(viewModel.tableIndexes.count))
                        } label: {
                            HStack(spacing: AXSpacing.xxs) {
                                Image(systemName: "doc.text")
                                    .font(AXTypography.caption2)
                                Text(L10n.Button.copy)
                                    .font(AXTypography.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xs)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AXSpacing.lg)

                if viewModel.tableIndexes.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Spacer(minLength: 60)
                        Image(systemName: "list.bullet.indent")
                            .font(AXTypography.largeTitle)
                            .foregroundColor(.axTextMuted.opacity(0.4))
                        Text(L10n.Database.noIndexes)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text(L10n.Database.noIndexesDefined)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)
                        Spacer(minLength: 60)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        indexHeader
                        Divider().background(Color.axBorder)
                        ForEach(Array(viewModel.tableIndexes.enumerated()), id: \.element.id) { index, idx in
                            indexRow(idx, index: index)
                            if index < viewModel.tableIndexes.count - 1 {
                                Divider().background(Color.axBorder.opacity(0.3))
                            }
                        }
                    }
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.bottom, AXSpacing.lg)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateIndex) {
            DBCreateIndexView(viewModel: viewModel)
        }
    }

    private var indexHeader: some View {
        HStack(spacing: 0) {
            Text(L10n.Field.name)
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text(L10n.Database.columnsLabel)
                .frame(width: 250, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text(L10n.Database.uniqueColHeader)
                .frame(width: 70, alignment: .center)
                .padding(.horizontal, AXSpacing.sm)
            Text(L10n.Engine.type)
                .padding(.horizontal, AXSpacing.sm)
            Spacer()
        }
        .font(AXTypography.caption2)
        .fontWeight(.bold)
        .foregroundColor(.axTextMuted)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.8))
    }

    private func indexRow(_ index: TableIndex, index rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: AXSpacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index.isUnique ? Color.axWarning.opacity(0.1) : Color.axTextMuted.opacity(0.1))
                        .frame(width: 22, height: 22)
                    Image(systemName: index.isUnique ? "key.fill" : "list.bullet")
                        .font(AXTypography.caption2)
                        .foregroundColor(index.isUnique ? .axWarning : .axTextMuted)
                }
                Text(index.name)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            HStack(spacing: AXSpacing.xxs) {
                ForEach(index.columns, id: \.self) { col in
                    Text(col)
                        .font(AXTypography.monoXs).fontWeight(.medium)
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
            .frame(width: 250, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            Group {
                if index.isUnique {
                    Text(L10n.Database.yesLabel)
                        .font(AXTypography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.axSuccess)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.axSuccess.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                } else {
                    Text(L10n.Database.noLabel)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .frame(width: 70, alignment: .center)
            .padding(.horizontal, AXSpacing.sm)

            Text(index.type)
                .font(AXTypography.monoXs)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)

            Spacer()

            // Index actions — AXActionMenu
            AXActionMenu(sections: [
                AXMenuSection(L10n.Button.copy, items: [
                    AXMenuItem(L10n.Database.copyIndexDDL, icon: "doc.on.doc", color: .axAccentBlue) {
                        let uq = index.isUnique ? "UNIQUE " : ""
                        let cols = index.columns.joined(separator: ", ")
                        let tbl = viewModel.selectedTable?.name ?? "table"
                        let ddl = "CREATE \(uq)INDEX `\(index.name)` ON `\(tbl)` (\(cols));"
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(ddl, forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.indexDDLCopied)
                    },
                    AXMenuItem(L10n.Database.copyIndexName, icon: "textformat", color: .cyan) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(index.name, forType: .string)
                        GlobalToastManager.shared.showSuccess(L10n.Database.indexNameCopied)
                    },
                ]),
                AXMenuSection(items: [
                    AXMenuItem(L10n.Database.dropIndex, icon: "trash", isDestructive: true) {
                        viewModel.activeAlert = .confirmDropIndex(index.name)
                    },
                ]),
            ], triggerIcon: "ellipsis", triggerSize: 22)
        }
        .padding(.vertical, AXSpacing.sm)
        .background(
            hoveredIndex == rowIndex
                ? Color.axAccentBlue.opacity(0.05)
                : (rowIndex % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
        )
        .onHover { hovering in hoveredIndex = hovering ? rowIndex : nil }
    }
}
