//
//  ChronoLiveLogView.swift
//  AevonX
//
//  Real-time SSE log streaming with monospaced terminal output.
//

import SwiftUI

struct ChronoLiveLogView: View {
    let deployId: String
    @ObservedObject var viewModel: ChronoViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.axDivider)
            logTerminal
            Divider().background(Color.axDivider)
            footer
        }
        .background(Color.axBackground)
        .task { await viewModel.watchLiveLog(deployId: deployId) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                if viewModel.isLiveStreaming {
                    Circle()
                        .fill(Color.axError)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(Color.axError.opacity(0.4))
                                .frame(width: 14, height: 14)
                        )
                }
                Text(L10n.Chrono.Deploy.live)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            Text("Deploy \(deployId)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Terminal

    private var logTerminal: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.liveLogLines.enumerated()), id: \.offset) { idx, line in
                        logLine(line, index: idx)
                            .id(idx)
                    }
                }
                .padding(AXSpacing.md)
            }
            .background(Color.black)
            .onChange(of: viewModel.liveLogLines.count) { _, newCount in
                if newCount > 0 {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func logLine(_ line: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Text("\(index + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.2))
                .frame(width: 32, alignment: .trailing)
            Text(line)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(logColor(line))
                .textSelection(.enabled)
        }
        .padding(.vertical, 1)
    }

    private func logColor(_ line: String) -> Color {
        if line.contains("[ERROR]") || line.contains("FATAL") { return Color(red: 1.0, green: 0.4, blue: 0.4) }
        if line.contains("[WARN]") { return Color(red: 1.0, green: 0.8, blue: 0.3) }
        if line.contains("[OK]") || line.contains("SUCCESS") { return Color(red: 0.4, green: 1.0, blue: 0.5) }
        if line.contains(">>>") || line.contains("---") { return Color(red: 0.5, green: 0.7, blue: 1.0) }
        return Color.white.opacity(0.85)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if viewModel.isLiveStreaming {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView().controlSize(.small)
                    Text("Streaming...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            } else {
                Text("\(viewModel.liveLogLines.count) lines")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
            Button { dismiss() } label: {
                Text("Close")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.lg)
    }
}
