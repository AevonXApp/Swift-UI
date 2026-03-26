//
//  AXAdvancedLogsView.swift
//  AevonX
//
//  Premium generic logs viewer with table, filters, and real-time data fetching.
//  Supports multiple sources like individual websites or global Nginx service.
//
//  Split structure:
//    AXLogModels.swift      — Enums, source, display model
//    AXLogTable.swift        — Reusable raw-text log table component
//    AXLogTableRow.swift     — Parsed log table row + tab button
//    AXLogDetailSheet.swift  — Detail sheet + helpers
//    AXIPBlockSheet.swift    — IP block form
//    AXLogsViewModel.swift   — ViewModel, data loading, parsing
//

import SwiftUI
import AevonXCoreBridge

// MARK: - AX Advanced Logs View

public struct AXAdvancedLogsView: View {
    @StateObject private var viewModel: AXLogsViewModel
    @State private var showClearConfirmation = false

    public init(
        source: AXLogSource,
        serverId: String?,
        onSuccess: ((String) -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: AXLogsViewModel(
            source: source,
            serverId: serverId,
            onSuccess: onSuccess,
            onError: onError
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            controlsHeader

            Divider()
                .background(Color.axBorder.opacity(0.3))

            if viewModel.isLoading {
                loadingState
            } else if viewModel.filteredLogs.isEmpty {
                emptyState
            } else {
                logsTable
            }
        }
        .background(Color.axBackground)
        .sheet(isPresented: $viewModel.showLogDetail) {
            if let log = viewModel.selectedLog {
                AXLogDetailSheet(log: log, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showIPBlockSheet) {
            if let ip = viewModel.selectedIP {
                AXIPBlockSheet(ip: ip, onBlock: { reason in
                    Task { await viewModel.blockIP(ip, reason: reason) }
                })
            }
        }
        .task {
            await viewModel.loadLogs()
        }
        .alert("Clear Logs", isPresented: $showClearConfirmation) {
            Button(L10n.Button.cancel, role: .cancel) { }
            Button(L10n.Button.clear, role: .destructive) {
                Task { await viewModel.clearLogs() }
            }
        } message: {
            Text("Are you sure you want to clear all log files for this source? This action cannot be undone.")
        }
    }

    // MARK: - Controls Header

    private var controlsHeader: some View {
        VStack(spacing: AXSpacing.md) {
            // Tabs
            HStack(spacing: AXSpacing.sm) {
                ForEach(AXLogTab.allCases) { tab in
                    AXLogTabButton(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab,
                        count: viewModel.getCount(for: tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    }
                }

                Spacer()

                // Refresh Button
                Button(action: { Task { await viewModel.loadLogs() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        if !viewModel.isLoading {
                            Text(L10n.Button.refresh)
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)

                // Clear Logs Button
                Button(action: { showClearConfirmation = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                        Text(L10n.Button.clear)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.axError)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
            }

            // Filters Row
            HStack(spacing: AXSpacing.sm) {
                // Search
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)

                    TextField("Search IP, URL, or message...", text: $viewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 280)

                // Status Filter
                if viewModel.selectedTab == .access || viewModel.selectedTab == .all {
                    Menu {
                        Button("All Status") { viewModel.statusFilter = nil }
                        Divider()
                        Button("2xx Success") { viewModel.statusFilter = 200 }
                        Button("3xx Redirect") { viewModel.statusFilter = 300 }
                        Button("4xx Client Error") { viewModel.statusFilter = 400 }
                        Button("5xx Server Error") { viewModel.statusFilter = 500 }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 11))
                            Text(viewModel.statusFilterLabel)
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                }

                // Sort Menu
                Menu {
                    ForEach(AXLogSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                                if viewModel.sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.sortOption.icon)
                            .font(.system(size: 11))
                        Text(viewModel.sortOption.rawValue)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()

                // Results Count
                Text("\(viewModel.filteredLogs.count) entries")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextTertiary)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5))
    }

    // MARK: - Logs Table

    private var logsTable: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                tableHeader

                Divider()
                    .background(Color.axBorder)

                ForEach(Array(viewModel.filteredLogs.enumerated()), id: \.element.id) { index, log in
                    AXLogTableRow(log: log, isEven: index % 2 == 0) {
                        viewModel.selectedLog = log
                        viewModel.showLogDetail = true
                    }

                    if index < viewModel.filteredLogs.count - 1 {
                        Divider()
                            .background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: AXSpacing.md) {
            Text("Time")
                .frame(width: 140, alignment: .leading)

            if viewModel.selectedTab != .error {
                Text("IP Address")
                    .frame(width: 130, alignment: .leading)
                Text("Method")
                    .frame(width: 70, alignment: .leading)
            }

            Text(viewModel.selectedTab == .error ? "Level" : "Status")
                .frame(width: 80, alignment: .leading)

            Text(viewModel.selectedTab == .error ? "Message" : "URL")
                .frame(minWidth: 200, alignment: .leading)

            Spacer()
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.axTextSecondary)
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading logs...")
                .font(.system(size: 14))
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.axTextTertiary.opacity(0.5))

            VStack(spacing: AXSpacing.xs) {
                Text("No Logs Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text(viewModel.searchText.isEmpty ? "No logs available for this source" : "No logs match your search criteria")
                    .font(.system(size: 13))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}
