//
//  DBTableIndexesView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBTableIndexesView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            if viewModel.tableIndexes.isEmpty {
                VStack {
                    Spacer(minLength: 100)
                    Text("No indexes found")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    indexHeader
                    Divider()
                    ForEach(viewModel.tableIndexes) { index in
                        indexRow(index)
                        Divider()
                    }
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .padding(AXSpacing.lg)
            }
        }
    }

    private var indexHeader: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Columns")
                .frame(width: 250, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Unique")
                .frame(width: 70, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Type")
                .padding(.horizontal, AXSpacing.sm)
            Spacer()
        }
        .font(AXTypography.caption)
        .fontWeight(.bold)
        .foregroundColor(.axTextSecondary)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.8))
    }

    private func indexRow(_ index: TableIndex) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: index.isUnique ? "key.fill" : "list.bullet")
                    .font(.system(size: 10))
                    .foregroundColor(index.isUnique ? .axWarning : .axTextMuted)
                Text(index.name)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            Text(index.columns.joined(separator: ", "))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(viewModel.database.type.brandColor)
                .frame(width: 250, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(index.isUnique ? "YES" : "NO")
                .font(AXTypography.caption)
                .foregroundColor(index.isUnique ? .axSuccess : .axTextMuted)
                .frame(width: 70, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(index.type)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)

            Spacer()
        }
        .padding(.vertical, AXSpacing.sm)
    }
}
