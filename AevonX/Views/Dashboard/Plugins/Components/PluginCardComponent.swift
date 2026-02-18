//
//  PluginCardComponent.swift
//  AevonX
//
//  Renders a plugin-defined card with title, description, icon, and optional action button.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Card Component

public struct PluginCardComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    if let desc = plugin.description {
                        Text(desc)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            // Result output
            if let output = vm.resultOutput, !output.isEmpty {
                Text(output)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .padding(AXSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axBackground)
                    )
                    .lineLimit(4)
            }

            // Action button
            if let command = plugin.command {
                Button(action: {
                    Task {
                        await vm.execute(
                            command: command,
                            pluginId: plugin.id,
                            serverId: serverId,
                            context: context
                        )
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                                .scaleEffect(0.7)
                        } else if vm.isSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.axSuccess)
                        } else if let icon = plugin.icon {
                            Image(systemName: icon)
                                .font(.system(size: 11))
                        }

                        Text(vm.isSuccess ? "Done" : (plugin.label ?? "Run"))
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(vm.isSuccess ? .axSuccess : accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(accentColor.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }

            // Error display
            if let error = vm.errorMessage {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axError)
                        .lineLimit(2)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var accentColor: Color {
        switch plugin.style ?? .secondary {
        case .primary:   return .axAccentBlue
        case .danger:    return .axError
        case .warning:   return .axWarning
        case .success:   return .axSuccess
        case .secondary, .ghost: return .axAccentBlue
        }
    }
}
