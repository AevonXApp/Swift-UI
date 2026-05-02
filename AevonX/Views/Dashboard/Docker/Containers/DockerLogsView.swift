//
//  DockerLogsView.swift
//  AevonX
//
//  Live streaming log viewer for Docker containers.
//  Uses shared AXLogTable with flexible columns.
//

import SwiftUI
import AevonXCoreBridge

struct DockerLogsView: View {
    let container: DockerContainer
    let serverId: String
    @Binding var isPresented: Bool

    @State private var logs: String = ""
    @State private var isStreaming: Bool = false
    @State private var task: Task<Void, Never>?
    @State private var tailCount: Int = 200

    private let logColumns: [AXLogColumn] = [
        AXLogColumn(id: "time", title: "Time", width: 140),
        AXLogColumn(id: "message", title: "Message", width: nil),
    ]

    private var logRows: [AXLogRow] {
        logs.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, line in
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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.axAccentBlue)
                        Text("Logs: \(container.names)")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    HStack(spacing: AXSpacing.sm) {
                        Text(container.shortId)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .monospaced()

                        if isStreaming {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.axSuccess)
                                    .frame(width: 5, height: 5)
                                Text(L10n.Docker.live)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.axSuccess)
                            }
                        }
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Button(action: { logs = "" }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextSecondary)
                            .padding(5)
                            .background(Color.axSurface)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)

            // Log display via shared component
            AXLogTable(
                title: "Container Logs",
                icon: "shippingbox.fill",
                columns: logColumns,
                rows: logRows,
                isLoading: false,
                onRefresh: { restartStream() }
            )

            // Footer — tail count
            HStack {
                HStack(spacing: 4) {
                    Text(L10n.Docker.tail)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: $tailCount) {
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.mini)
                    .frame(width: 200)
                    .onChange(of: tailCount) { _, _ in restartStream() }
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
        }
        .frame(width: 900, height: 650)
        .background(Color.axBackground)
        .onAppear { startStreaming() }
        .onDisappear { stopStreaming() }
    }

    // MARK: - Streaming

    private func startStreaming() {
        isStreaming = true
        logs = ""

        task = Task {
            do {
                try await DockerService.shared.getContainerLogs(
                    id: container.id,
                    tail: tailCount,
                    follow: true,
                    serverId: serverId
                ) { chunk in
                    Task { @MainActor in logs += chunk }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        logs += "\n[Error] Stream disconnected: \(error.localizedDescription)"
                    }
                }
            }
            isStreaming = false
        }
    }

    private func stopStreaming() {
        task?.cancel()
        task = nil
        isStreaming = false
    }

    private func restartStream() {
        stopStreaming()
        startStreaming()
    }
}
