//
//  DBTableStructureView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBTableStructureView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Columns")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    Button { viewModel.showAddColumn = true } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                            Text("Add Column")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(viewModel.database.type.brandColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.lg)

                if let structure = viewModel.tableStructure {
                    VStack(alignment: .leading, spacing: 0) {
                        columnHeader
                        Divider()
                        ForEach(structure.columns) { col in
                            columnRow(col)
                            Divider()
                        }
                    }
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.bottom, AXSpacing.lg)
                } else {
                    ProgressView()
                        .padding(AXSpacing.xl)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddColumn) {
            DBAddColumnView(viewModel: viewModel)
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(width: 150, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Type")
                .frame(width: 120, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Attributes")
                .padding(.horizontal, AXSpacing.sm)
            Spacer()
            Text("Actions")
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, AXSpacing.sm)
        }
        .font(AXTypography.caption)
        .fontWeight(.bold)
        .foregroundColor(.axTextSecondary)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.8))
    }

    private func columnRow(_ col: ColumnInfo) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: AXSpacing.xs) {
                if col.isPrimaryKey {
                    Image(systemName: "key.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axWarning)
                }
                Text(col.name)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
            }
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            Text(col.type)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(viewModel.database.type.brandColor)
                .frame(width: 120, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            HStack(spacing: AXSpacing.xs) {
                if !col.isNullable {
                    badge("NOT NULL", color: .axTextSecondary)
                }
                if let extra = col.extra, !extra.isEmpty {
                    badge(extra.uppercased(), color: .axInfo)
                }
            }
            .padding(.horizontal, AXSpacing.sm)

            Spacer()

            Button {
                viewModel.activeAlert = .confirmDropColumn(col.name)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.axError)
            }
            .buttonStyle(.plain)
            .frame(width: 60, alignment: .center)
            .padding(.horizontal, AXSpacing.sm)
        }
        .padding(.vertical, AXSpacing.sm)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
}
