//
//  PluginCommandBlockComponent.swift
//  AevonX
//
//  Displays a code-styled, copyable command block. Used for "run this on
//  the server" instructions (KEK rotation, DR bundle export, plugin-specific
//  ops). The command is never executed — the UI only offers a copy button.
//

import SwiftUI
import AevonXCoreBridge

public struct PluginCommandBlockComponent: View {

    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @State private var copied: Bool = false

    public var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            header
            commandBody
            footer
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder.opacity(0.4), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Header

private extension PluginCommandBlockComponent {

    @ViewBuilder
    var header: some View {
        if let caption = plugin.caption ?? plugin.label {
            HStack(spacing: AXSpacing.xs) {
                if let icon = plugin.icon {
                    Image(systemName: icon)
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentPurple)
                }
                Text(caption)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                Spacer()
            }
        }
    }
}

// MARK: - Command body

private extension PluginCommandBlockComponent {

    var commandBody: some View {
        HStack(spacing: AXSpacing.xs) {
            Text(displayedCommand)
                .font(AXTypography.monoSm)
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)
                .padding(AXSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axBackground.opacity(0.7))
                )
            copyButton
        }
    }

    var copyButton: some View {
        Button {
            copyToClipboard(displayedCommand)
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(copied ? .axAccentGreen : .axTextSecondary)
                .frame(width: 32, height: 32)
                .background(Color.axBackground.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
        .help(copied ? "Copied" : "Copy to clipboard")
    }

    /// Interpolates `{{var}}` placeholders in the command text using the
    /// shared context. Falls back to the raw command if no context match.
    var displayedCommand: String {
        guard let raw = plugin.commandText, !raw.isEmpty else {
            return "# no command_text set"
        }
        var out = raw
        for (k, v) in context {
            out = out.replacingOccurrences(of: "{{\(k)}}", with: v)
        }
        return out
    }

    func copyToClipboard(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}

// MARK: - Footer

private extension PluginCommandBlockComponent {

    @ViewBuilder
    var footer: some View {
        if let note = plugin.note, !note.isEmpty {
            Text(note)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
    }
}
