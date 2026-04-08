//
//  PluginMarkdownView.swift
//  AevonX
//
//  Renders plugin description markdown with proper styling.
//  Handles: ## headers, **bold**, - bullets, `code`, paragraphs.
//

import SwiftUI

struct PluginMarkdownView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func blockView(_ block: MDBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .bullet(let text):
            bulletView(text: text)
        case .paragraph(let text):
            paragraphView(text: text)
        }
    }

    private func headingView(level: Int, text: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.axAccentBlue)
                .frame(width: 3, height: level == 1 ? 20 : 16)

            Text(renderInline(text))
                .font(level == 1 ? AXTypography.title3 : AXTypography.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
        }
        .padding(.top, level == 1 ? AXSpacing.md : AXSpacing.sm)
    }

    private func bulletView(text: String) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.sm) {
            Circle()
                .fill(Color.axAccentBlue.opacity(0.6))
                .frame(width: 5, height: 5)
                .padding(.top, 6)

            Text(renderInline(text))
                .font(AXTypography.body)
                .foregroundStyle(Color.axTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, AXSpacing.md)
    }

    private func paragraphView(text: String) -> some View {
        Text(renderInline(text))
            .font(AXTypography.body)
            .foregroundStyle(Color.axTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Inline Markdown → AttributedString

    private func renderInline(_ text: String) -> AttributedString {
        // SwiftUI AttributedString supports markdown inline formatting
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(text)
    }

    // MARK: - Block Parser

    private enum MDBlock {
        case heading(Int, String)
        case bullet(String)
        case paragraph(String)
    }

    private func parseBlocks() -> [MDBlock] {
        var blocks: [MDBlock] = []
        var paragraphBuffer = ""

        func flushParagraph() {
            let trimmed = paragraphBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(.paragraph(trimmed))
            }
            paragraphBuffer = ""
        }

        for line in markdown.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line → flush paragraph
            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            // Heading: # or ##
            if trimmed.hasPrefix("#") {
                flushParagraph()
                var level = 0
                var rest = trimmed
                while rest.hasPrefix("#") {
                    level += 1
                    rest = String(rest.dropFirst())
                }
                let headingText = rest.trimmingCharacters(in: .whitespaces)
                if !headingText.isEmpty {
                    blocks.append(.heading(min(level, 3), headingText))
                }
                continue
            }

            // Bullet: - or *
            if (trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")) {
                flushParagraph()
                let bulletText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                blocks.append(.bullet(bulletText))
                continue
            }

            // Regular text — accumulate into paragraph
            if paragraphBuffer.isEmpty {
                paragraphBuffer = trimmed
            } else {
                paragraphBuffer += " " + trimmed
            }
        }

        flushParagraph()
        return blocks
    }
}
