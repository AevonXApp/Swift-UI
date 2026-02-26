//
//  PluginButtonComponent.swift
//  AevonX
//
//  Renders a plugin-defined button with loading/success/error states.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Button Component

public struct PluginButtonComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var showConfirmation = false

    public var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 6) {
                if vm.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else if vm.isSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                } else {
                    if let icon = plugin.icon {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .medium))
                    }
                }

                Text(vm.isSuccess ? "Done" : (plugin.label ?? plugin.name))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(vm.isLoading)
        .animation(.spring(response: 0.25), value: vm.isLoading)
        .animation(.spring(response: 0.25), value: vm.isSuccess)
        .popover(isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.reset() } }
        )) {
            if let error = vm.errorMessage {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextPrimary)
                }
                .padding(AXSpacing.md)
            }
        }
        .alert(plugin.confirmationMessage ?? "Are you sure?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button(plugin.label ?? plugin.name, role: .destructive) {
                executeCommand()
            }
        }
    }

    private func handleTap() {
        if plugin.confirmationMessage != nil {
            showConfirmation = true
        } else {
            executeCommand()
        }
    }

    private func executeCommand() {
        guard let command = plugin.command else { return }
        Task {
            await vm.execute(
                command: command,
                pluginId: plugin.id,
                serverId: serverId,
                context: context,
                namespace: plugin.namespace
            )
        }
    }

    // MARK: - Styling

    private var buttonStyle: HookButtonStyle { plugin.style ?? .secondary }

    private var backgroundColor: Color {
        if vm.isSuccess { return .axSuccess.opacity(0.15) }
        switch buttonStyle {
        case .primary:   return .axAccentBlue
        case .danger:    return .axError
        case .warning:   return .axWarning
        case .success:   return .axSuccess
        case .secondary: return Color.axSurface
        case .ghost:     return Color.clear
        }
    }

    private var foregroundColor: Color {
        if vm.isSuccess { return .axSuccess }
        switch buttonStyle {
        case .primary, .danger, .warning, .success:
            return .white
        case .secondary, .ghost:
            return .axTextSecondary
        }
    }

    private var borderColor: Color {
        if vm.isSuccess { return .axSuccess.opacity(0.3) }
        switch buttonStyle {
        case .primary:   return Color.axAccentBlue.opacity(0.5)
        case .danger:    return Color.axError.opacity(0.5)
        case .warning:   return Color.axWarning.opacity(0.5)
        case .success:   return Color.axSuccess.opacity(0.5)
        case .secondary: return Color.axBorder
        case .ghost:     return Color.clear
        }
    }
}
