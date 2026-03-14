//
//  PluginMarkdownComponent.swift
//  AevonX
//
//  Renders markdown content fetched from a command or file path.
//  Used for plugin documentation, changelogs, and help pages.
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

struct PluginMarkdownComponent: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    @StateObject private var vm = HookPluginViewModel()
    @State private var markdownContent: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: plugin.icon ?? "doc.text.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.axAccentBlue)
                Text(plugin.name)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Spacer()

                Button(action: { Task { await loadContent() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextMuted)
                        .padding(6)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundTertiary)

            Divider().background(Color.axBorder)

            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                        .scaleEffect(1.0)
                    Text("Loading content…")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if markdownContent.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.axTextMuted)
                    Text("No content available")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    markdownView
                        .padding(AXSpacing.xl)
                }
            }
        }
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder, lineWidth: 1))
        .task {
            await loadContent()
        }
    }

    private var markdownView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            ForEach(Array(markdownContent.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                markdownLine(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func markdownLine(_ line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(line.dropFirst(2))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.axTextPrimary)
                .padding(.top, AXSpacing.md)
        } else if line.hasPrefix("## ") {
            Text(line.dropFirst(3))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.axTextPrimary)
                .padding(.top, AXSpacing.sm)
        } else if line.hasPrefix("### ") {
            Text(line.dropFirst(4))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.axTextPrimary)
                .padding(.top, AXSpacing.xs)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: AXSpacing.sm) {
                Text("•")
                    .foregroundColor(.axAccentBlue)
                Text(line.dropFirst(2))
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            }
        } else if line.hasPrefix("> ") {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.axAccentBlue)
                    .frame(width: 3)
                Text(line.dropFirst(2))
                    .font(.system(size: 13, design: .default).italic())
                    .foregroundColor(.axTextSecondary)
                    .padding(.leading, AXSpacing.sm)
            }
            .padding(.vertical, AXSpacing.xs)
        } else if line.hasPrefix("```") {
            EmptyView()
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Spacer().frame(height: AXSpacing.xs)
        } else {
            let parsed = parseInlineFormatting(line)
            parsed
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
    }

    private func parseInlineFormatting(_ text: String) -> Text {
        var result = Text("")
        var remaining = text

        while !remaining.isEmpty {
            if let boldRange = remaining.range(of: "**") {
                let before = String(remaining[..<boldRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                }
                remaining = String(remaining[boldRange.upperBound...])
                if let endBold = remaining.range(of: "**") {
                    let boldText = String(remaining[..<endBold.lowerBound])
                    result = result + Text(boldText).bold()
                    remaining = String(remaining[endBold.upperBound...])
                }
            } else if let codeRange = remaining.range(of: "`") {
                let before = String(remaining[..<codeRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                }
                remaining = String(remaining[codeRange.upperBound...])
                if let endCode = remaining.range(of: "`") {
                    let codeText = String(remaining[..<endCode.lowerBound])
                    result = result + Text(codeText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                    remaining = String(remaining[endCode.upperBound...])
                }
            } else {
                result = result + Text(remaining)
                remaining = ""
            }
        }
        return result
    }

    private func loadContent() async {
        isLoading = true

        if let source = plugin.contentSource, !source.isEmpty {
            _ = HookPluginCommand(type: .coreCmd, action: "cat", payload: ["path": AnyCodable(source)], timeout: 10)
            if let result = try? await SSHBridge.shared.execute("cat '\(source)' 2>/dev/null", serverId: serverId) {
                markdownContent = result.stdout
            }
        } else if let ds = plugin.dataSource {
            let command = HookPluginCommand(
                type: ds.type ?? .coreCmd,
                action: ds.action,
                payload: ds.payload,
                timeout: 15
            )
            await vm.execute(
                command: command,
                pluginId: plugin.id,
                serverId: serverId,
                context: context,
                namespace: plugin.namespace
            )
            markdownContent = vm.resultOutput ?? ""
        } else {
            markdownContent = plugin.description ?? ""
        }

        isLoading = false
    }
}
