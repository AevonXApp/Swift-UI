//
//  DBEDLogsTab.swift
//  AevonX
//
//  Database engine detail — Logs tab.
//  Uses shared AXLogTable with flexible columns.
//

import SwiftUI
import AevonXCoreBridge

struct DBEDLogsTab: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    private let logColumns: [AXLogColumn] = [
        AXLogColumn(id: "time", title: "Time", width: 140),
        AXLogColumn(id: "message", title: "Message", width: nil),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Log type selector
            HStack(spacing: AXSpacing.md) {
                ForEach(DatabaseEngineDetailViewModel.LogType.allCases, id: \.self) { logType in
                    Button(logType.rawValue) {
                        viewModel.selectedLogType = logType
                        Task {
                            switch logType {
                            case .error: await viewModel.loadErrorLog()
                            case .slowQuery: await viewModel.loadSlowQueryLog()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(viewModel.selectedLogType == logType ? .axTextPrimary : .axTextSecondary)
                }
                Spacer()
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            // Log content
            AXLogTable(
                title: viewModel.selectedLogType.rawValue,
                icon: viewModel.selectedLogType == .error ? "exclamationmark.triangle.fill" : "tortoise.fill",
                columns: logColumns,
                rows: buildRows(currentLogLines),
                isLoading: viewModel.isOperationInProgress,
                accentColor: viewModel.databaseType.brandColor,
                onRefresh: {
                    switch viewModel.selectedLogType {
                    case .error: await viewModel.loadErrorLog()
                    case .slowQuery: await viewModel.loadSlowQueryLog()
                    }
                }
            )
        }
        .onAppear {
            Task { await viewModel.loadErrorLog() }
        }
    }

    private var currentLogLines: [String] {
        let logContent: LogContent? = {
            switch viewModel.selectedLogType {
            case .error: return viewModel.errorLog
            case .slowQuery: return viewModel.slowQueryLog
            }
        }()
        return logContent?.lines ?? []
    }

    private func buildRows(_ lines: [String]) -> [AXLogRow] {
        lines.enumerated().map { index, line in
            AXLogRow(
                id: index,
                level: AXLogLevelDetector.detect(line),
                cells: [
                    "time": AXLogTimestamp.extract(line),
                    "message": line
                ],
                raw: line
            )
        }
    }
}
