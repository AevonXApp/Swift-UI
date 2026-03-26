//
//  AXLaunchProgressBubble.swift
//  AevonX
//
//  Floating progress overlay that persists across navigation.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchProgressBubble: View {
    @ObservedObject var viewModel: AXLaunchProgressBubbleViewModel

    var body: some View {
        if viewModel.isVisible {
            bubbleContent
                .onTapGesture { viewModel.showReopenSheet?() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var bubbleContent: some View {
        HStack(spacing: AXSpacing.md) {
            statusIcon
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(statusTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(statusColor)
                if !viewModel.domainName.isEmpty {
                    Text(viewModel.domainName)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            progressBar
            dismissButton
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(.ultraThinMaterial)
        .background(Color.axSurface.opacity(0.8))
        .cornerRadius(AXCornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .padding(.horizontal, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if viewModel.isComplete {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.axSuccess)
        } else if viewModel.isFailed {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.axError)
        } else {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.axAccentBlue)
        }
    }

    private var statusTitle: String {
        if viewModel.isComplete { return L10n.AXLaunch.complete }
        if viewModel.isFailed { return L10n.AXLaunch.failed }
        return "\(L10n.AXLaunch.launching)  \(Int(viewModel.progress.percent))%"
    }

    private var statusColor: Color {
        if viewModel.isComplete { return .axSuccess }
        if viewModel.isFailed { return .axError }
        return .axTextPrimary
    }

    private var progressBar: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.axBorder)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(width: geo.size.width * viewModel.progress.percent / 100)
                        .animation(.linear(duration: 0.3), value: viewModel.progress.percent)
                }
        }
        .frame(width: 60, height: 4)
    }

    private var dismissButton: some View {
        Button { viewModel.dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.axTextMuted)
        }
        .buttonStyle(.plain)
    }
}
