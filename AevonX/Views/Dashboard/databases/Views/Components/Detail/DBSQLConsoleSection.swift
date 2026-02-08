//
//  DBSQLConsoleSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBSQLConsoleSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            consoleHeader
            Divider()
            queryEditor
            Divider()
            queryResults
        }
    }

    private var consoleHeader: some View {
        HStack {
            Text("SQL Console")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            Spacer()

            if !viewModel.queryHistory.isEmpty {
                Menu {
                    ForEach(viewModel.queryHistory.prefix(10)) { entry in
                        Button {
                            viewModel.queryText = entry.query
                        } label: {
                            HStack {
                                Image(systemName: entry.success ? "checkmark.circle" : "xmark.circle")
                                Text(entry.query.prefix(60) + (entry.query.count > 60 ? "..." : ""))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                        Text("History")
                            .font(AXTypography.caption)
                    }
                    .foregroundColor(viewModel.database.type.brandColor)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 90)
            }
        }
        .padding(AXSpacing.lg)
    }

    private var queryEditor: some View {
        VStack(spacing: AXSpacing.sm) {
            TextEditor(text: $viewModel.queryText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )

            HStack {
                Text("Database: \(viewModel.database.name)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                Spacer()

                Button {
                    Task { await viewModel.executeQuery() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if viewModel.isExecutingQuery {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text("Execute")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .background(viewModel.queryText.isEmpty || viewModel.isExecutingQuery ? Color.axTextMuted.opacity(0.5) : viewModel.database.type.brandColor)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.queryText.isEmpty || viewModel.isExecutingQuery)
            }
        }
        .padding(AXSpacing.lg)
    }

    @ViewBuilder
    private var queryResults: some View {
        if let result = viewModel.queryResult {
            VStack(alignment: .leading, spacing: 0) {
                // Result info bar
                HStack {
                    if result.isSelect {
                        Text("\(result.rows.count) rows returned")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    } else {
                        Text("Query executed successfully")
                            .font(AXTypography.caption)
                            .foregroundColor(.axSuccess)
                    }
                    Spacer()
                    Text(String(format: "%.3fs", result.executionTime))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)

                if result.isSelect && !result.columns.isEmpty {
                    Divider()
                    queryResultsTable(result)
                }
            }
        } else {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: "terminal")
                    .font(.system(size: 28))
                    .foregroundColor(.axTextMuted)
                Text("Enter a query and click Execute")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
    }

    private func queryResultsTable(_ result: QueryResult) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(result.columns, id: \.self) { col in
                        Text(col)
                            .font(AXTypography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextSecondary)
                            .frame(minWidth: 120, alignment: .leading)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.sm)
                    }
                }
                .background(Color.axSurface.opacity(0.8))

                Divider()

                ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, value in
                            Text(value ?? "NULL")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(value != nil ? .axTextPrimary : .axTextMuted)
                                .lineLimit(1)
                                .frame(minWidth: 120, alignment: .leading)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xs)
                        }
                    }
                    .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                }
            }
        }
    }
}
