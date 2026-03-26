//
//  AXLaunchStepProgress.swift
//  AevonX
//
//  Live progress terminal during deployment.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStepProgress: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            progressHeader
            stepList
            logTerminal
            footerButtons
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(headerTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(headerColor)
                if !viewModel.launchProgress.stepName.isEmpty {
                    Text(viewModel.launchProgress.stepName)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
            }
            Spacer()
            percentCircle
        }
    }

    private var headerTitle: String {
        if viewModel.launchComplete { return L10n.AXLaunch.complete }
        if viewModel.launchFailed { return L10n.AXLaunch.failed }
        return L10n.AXLaunch.launching
    }

    private var headerColor: Color {
        if viewModel.launchComplete { return .axSuccess }
        if viewModel.launchFailed { return .axError }
        return .axTextPrimary
    }

    private var percentCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.axBorder, lineWidth: 4)
            Circle()
                .trim(from: 0, to: viewModel.launchProgress.percent / 100)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: viewModel.launchProgress.percent)
            Text("\(Int(viewModel.launchProgress.percent))%")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
        .frame(width: 56, height: 56)
    }

    private var progressColor: Color {
        if viewModel.launchComplete { return .axSuccess }
        if viewModel.launchFailed { return .axError }
        return .axAccentBlue
    }

    // MARK: - Step List

    @ViewBuilder
    private var stepList: some View {
        let progress = viewModel.launchProgress
        if progress.totalSteps > 0 {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                ForEach(0..<progress.totalSteps, id: \.self) { index in
                    stepRow(index: index, currentIndex: progress.stepIndex, name: stepNameForIndex(index))
                }
            }
        }
    }

    private func stepRow(index: Int, currentIndex: Int, name: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            stepIcon(index: index, currentIndex: currentIndex)
                .frame(width: 16)
            Text(name)
                .font(AXTypography.caption)
                .foregroundColor(index <= currentIndex ? .axTextPrimary : .axTextMuted)
            Spacer()
        }
    }

    @ViewBuilder
    private func stepIcon(index: Int, currentIndex: Int) -> some View {
        if index < currentIndex {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.axSuccess)
        } else if index == currentIndex {
            ProgressView()
                .scaleEffect(0.5)
        } else {
            Image(systemName: "circle")
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
        }
    }

    private func stepNameForIndex(_ index: Int) -> String {
        if index == viewModel.launchProgress.stepIndex {
            return viewModel.launchProgress.stepName
        }
        return "Step \(index + 1)"
    }

    // MARK: - Log Terminal

    private var logTerminal: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.logLines.indices, id: \.self) { idx in
                        AXLaunchLogLineView(line: viewModel.logLines[idx])
                            .id(idx)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(AXSpacing.sm)
            }
            .background(Color.black.opacity(0.6))
            .cornerRadius(AXCornerRadius.md)
            .frame(maxHeight: 200)
            .onChange(of: viewModel.logLines.count) { _, newCount in
                withAnimation {
                    proxy.scrollTo(newCount - 1, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Transfer Info

    @ViewBuilder
    private var transferInfo: some View {
        let p = viewModel.launchProgress
        if p.totalBytes > 0 {
            VStack(spacing: AXSpacing.xs) {
                ProgressView(value: Double(p.bytesSent), total: Double(p.totalBytes))
                    .tint(.axAccentBlue)
                HStack {
                    if let file = p.currentFile {
                        Text(file)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(formatBytes(p.bytesSent)) / \(formatBytes(p.totalBytes))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerButtons: some View {
        HStack {
            Spacer()
            if viewModel.isLaunching {
                AXPrimaryButton(
                    title: L10n.AXLaunch.cancelLaunch,
                    icon: "xmark",
                    action: { Task { await viewModel.cancelLaunch() } },
                    style: .destructive
                )
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576.0
        return String(format: "%.1f MB", mb)
    }
}
