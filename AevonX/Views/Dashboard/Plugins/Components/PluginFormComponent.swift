//
//  PluginFormComponent.swift
//  AevonX
//
//  Renders a form with fields derived from the plugin's payload template.
//  Users fill in the form and submit to dispatch the command.
//

import SwiftUI
import AevonXCore

// MARK: - Plugin Form Component

public struct PluginFormComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var fieldValues: [String: String] = [:]

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
                Text(plugin.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
            }

            if let desc = plugin.description {
                Text(desc)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Divider()

            // Form fields — derived from payload template keys
            if let payload = plugin.command?.payload {
                VStack(spacing: AXSpacing.sm) {
                    ForEach(Array(payload.keys.sorted()), id: \.self) { key in
                        let templateValue = payload[key]?.stringValue ?? ""
                        // Only show fields that have template placeholders (user-fillable)
                        if templateValue.contains("{{") {
                            FormFieldRow(
                                key: key,
                                placeholder: extractPlaceholder(from: templateValue),
                                value: Binding(
                                    get: { fieldValues[key] ?? "" },
                                    set: { fieldValues[key] = $0 }
                                )
                            )
                        }
                    }
                }
            }

            // Output
            if let output = vm.resultOutput, !output.isEmpty {
                Text(output.prefix(200))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .padding(AXSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axBackground)
                    )
                    .lineLimit(4)
            }

            if let error = vm.errorMessage {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axError)
                }
            }

            // Submit button
            if let command = plugin.command {
                Button(action: {
                    Task {
                        // Merge form values into context
                        var mergedContext = context
                        for (key, value) in fieldValues {
                            mergedContext[key] = value
                        }
                        await vm.execute(
                            command: command,
                            pluginId: plugin.id,
                            serverId: serverId,
                            context: mergedContext
                        )
                    }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else if vm.isSuccess {
                            Image(systemName: "checkmark")
                        } else if let icon = plugin.icon {
                            Image(systemName: icon)
                                .font(.system(size: 12))
                        }
                        Text(vm.isSuccess ? "Done!" : (plugin.label ?? "Submit"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(vm.isSuccess ? Color.axSuccess : Color.axAccentBlue)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
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

    /// Extracts the placeholder name from a template string like "{{website.id}}"
    private func extractPlaceholder(from template: String) -> String {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        if let range = template.range(of: pattern, options: .regularExpression) {
            let match = String(template[range])
            return match
                .replacingOccurrences(of: "{{", with: "")
                .replacingOccurrences(of: "}}", with: "")
        }
        return template
    }
}

// MARK: - Form Field Row

private struct FormFieldRow: View {
    let key: String
    let placeholder: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.axTextSecondary)

            TextField(placeholder, text: $value)
                .font(AXTypography.body)
                .textFieldStyle(.plain)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
    }
}
