//
//  DBEDHeader.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEDHeader: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack {
                // Back button
                Button(action: onDismiss) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text(L10n.Button.back)
                    }
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Engine icon and name
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(Color.axAccentBlue.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: viewModel.databaseType.iconName)
                            .font(AXTypography.title)
                            .foregroundColor(.axAccentBlue)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(viewModel.databaseType.displayName)
                            .font(AXTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)

                        Text(viewModel.formattedVersion)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                // Status indicator
                HStack(spacing: AXSpacing.sm) {
                    Circle()
                        .fill(viewModel.statusColor)
                        .frame(width: 8, height: 8)

                    Text(viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                        .font(AXTypography.subheadline)
                        .foregroundColor(viewModel.statusColor)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(viewModel.statusColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.full)
            }

            // Service Controls
            if viewModel.isInstalled {
                DBEDServiceControls(viewModel: viewModel)
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axSurface)
    }
}
