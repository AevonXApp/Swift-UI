//
//  QuickInstallProgressView.swift
//  AevonX
//
//  Live installation progress screen for the Quick Environment Install.
//  Sits on top of QuickInstallView after user hits "Install Now".
//  Wraps AXStepInstallerView and adds a Minimize button.
//

import SwiftUI

struct QuickInstallProgressView: View {

    @ObservedObject var viewModel: QuickInstallViewModel
    var onMinimize: () -> Void
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────
            header

            Divider().background(Color.axBorder.opacity(0.3))

            // ── Step List ────────────────────────────────────
            if let installerVM = viewModel.installerViewModel {
                AXStepInstallerView(
                    viewModel: installerVM,
                    title: "Installing \(viewModel.selections.count) package\(viewModel.selections.count == 1 ? "" : "s")",
                    icon: "bolt.fill",
                    accentColor: .axAccentBlue,
                    onDismiss: onDone
                )
            } else {
                VStack {
                    ProgressView()
                    Text("Preparing installation...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .padding(.top, AXSpacing.sm)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 480)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 40, x: 0, y: 20)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AXSpacing.md) {
            // Animated spinner icon
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: viewModel.isComplete ? "checkmark.circle.fill" : "bolt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.isComplete ? .axSuccess : .axAccentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isComplete ? "Installation Complete" : "Installing...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(viewModel.isComplete ? .axSuccess : .axTextPrimary)

                if let vm = viewModel.installerViewModel {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isRunning {
                            Text(vm.currentStepTitle)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                                .lineLimit(1)
                        }
                        Text("·")
                            .foregroundColor(.axTextMuted)
                        Text(vm.elapsedTimeFormatted)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextTertiary)
                    }
                }
            }

            Spacer()

            // Package summaries
            ForEach(Array(viewModel.selections.prefix(4))) { sel in
                Text(sel.package_name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                            .stroke(Color.axBorder.opacity(0.4), lineWidth: 1)
                    )
            }
            if viewModel.selections.count > 4 {
                Text("+\(viewModel.selections.count - 4) more")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            // Minimize button
            if !viewModel.isComplete && !viewModel.isFailed {
                Button(action: onMinimize) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 11))
                        Text("Minimize")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }
}
