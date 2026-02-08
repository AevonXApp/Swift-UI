//
//  DBEDLogsTab.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEDLogsTab: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Log type selector
            HStack(spacing: AXSpacing.md) {
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
                    .buttonStyle(.plain)
                    .foregroundColor(viewModel.selectedLogType == logType ? .axTextPrimary : .axTextSecondary)
                }

                Spacer()

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
                .buttonStyle(.plain)
                .foregroundColor(viewModel.databaseType.brandColor)
                .disabled(viewModel.isOperationInProgress)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            // Log content
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
                        Text("No logs loaded. Click 'Error Log' or 'Slow Query Log' to view.")
                            .foregroundColor(.axTextMuted)
                            .padding()
                    }
                }
                .padding(AXSpacing.lg)
            }
            .background(Color.axBackground)
        }
        .onAppear {
            Task { await viewModel.loadErrorLog() }
        }
    }
}
