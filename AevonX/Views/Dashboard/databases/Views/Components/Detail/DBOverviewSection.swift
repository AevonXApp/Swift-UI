//
//  DBOverviewSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBOverviewSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                sectionTitle

                statsGrid

                tablesOverview
            }
            .padding(AXSpacing.xl)
        }
    }

    private var sectionTitle: some View {
        Text("Database Overview")
            .font(AXTypography.title2)
            .fontWeight(.bold)
            .foregroundColor(.axTextPrimary)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            overviewStat(icon: "cylinder", label: "Engine", value: viewModel.database.type.displayName, color: viewModel.database.type.brandColor)
            overviewStat(icon: "internaldrive", label: "Size", value: AXFormatter.formatSizeMB(viewModel.database.size), color: .axAccentGreen)
            overviewStat(icon: "tablecells", label: "Tables", value: "\(viewModel.tables.count)", color: .axWarning)
            overviewStat(icon: "bolt.horizontal", label: "Connections", value: "\(viewModel.database.connections)", color: .axInfo)
        }
    }

    private func overviewStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var tablesOverview: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Tables")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            if viewModel.tables.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Text("No tables found in this database.")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                    Button {
                        viewModel.currentSection = .tables
                        viewModel.showCreateTable = true
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                            Text("Create Table")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(viewModel.database.type.brandColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.lg)
            } else {
                ForEach(viewModel.tables.prefix(10)) { table in
                    tableOverviewRow(table)
                }
                if viewModel.tables.count > 10 {
                    Text("and \(viewModel.tables.count - 10) more...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .padding(.leading, AXSpacing.md)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func tableOverviewRow(_ table: TableInfo) -> some View {
        HStack {
            Image(systemName: "tablecells")
                .font(.system(size: 12))
                .foregroundColor(viewModel.database.type.brandColor)
                .frame(width: 20)
            Text(table.name)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Text("\(table.rowCount) rows")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(AXFormatter.formatBytes(table.dataSize))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, AXSpacing.xs)
    }

}
