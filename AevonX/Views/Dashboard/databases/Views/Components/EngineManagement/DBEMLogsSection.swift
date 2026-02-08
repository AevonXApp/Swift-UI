//
//  DBEMLogsSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEMLogsSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Logs")
                    .font(AXTypography.title)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                // Log Type Selector
                HStack(spacing: 0) {
                    ForEach(DatabaseEngineDetailViewModel.LogType.allCases, id: \.self) { logType in
                        Button(logType.rawValue) {
                            viewModel.selectedLogType = logType
                            Task {
                                switch logType {
                                case .error:
                                    await viewModel.loadErrorLog()
                                case .slowQuery:
                                    await viewModel.loadSlowQueryLog()
                                }
                            }
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(viewModel.selectedLogType == logType ? .semibold : .regular)
                        .foregroundColor(viewModel.selectedLogType == logType ? viewModel.databaseType.brandColor : .axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(viewModel.selectedLogType == logType ? viewModel.databaseType.brandColor.opacity(0.1) : Color.clear)
                        .cornerRadius(AXCornerRadius.md)
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)

                Button("Refresh") {
                    Task {
                        switch viewModel.selectedLogType {
                        case .error:
                            await viewModel.loadErrorLog()
                        case .slowQuery:
                            await viewModel.loadSlowQueryLog()
                        }
                    }
                }
                .font(AXTypography.subheadline)
                .foregroundColor(viewModel.databaseType.brandColor)
                .padding(.leading, AXSpacing.md)
                .disabled(viewModel.isOperationInProgress)
            }
            .padding(AXSpacing.xl)

            Divider()

            // Log Content
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    let logContent: AevonXCore.LogContent? = {
                        switch viewModel.selectedLogType {
                        case .error: return viewModel.errorLog
                        case .slowQuery: return viewModel.slowQueryLog
                        }
                    }()

                    if let log = logContent, !log.lines.isEmpty {
                        ForEach(Array(log.lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                                .padding(.vertical, AXSpacing.xs)
                        }
                    } else {
                        Text("No logs loaded. Click 'Refresh' to load logs.")
                            .foregroundColor(.axTextMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AXSpacing.xl)
                    }
                }
                .padding(AXSpacing.lg)
            }
        }
        .onAppear {
            Task { await viewModel.loadErrorLog() }
        }
    }
}
